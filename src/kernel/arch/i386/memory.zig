const kstd = @import("../../kernel_std.zig");
const Multiboot = @import("../../multiboot.zig");
const x86 = @import("x86.zig");
const std = @import("std");

pub extern var initial_page_dir: [1024]u32 align(4096);

pub const KERNEL_START = 0xC0000000;
pub const KERNEL_MALLOC = 0xD0000000;
pub const REC_PAGEDIR = 0xFFFFF000;
pub inline fn REC_PAGETABLE(i: anytype) [*c]u32 {
    @setRuntimeSafety(false);
    _ = &i;
    return @import("std").zig.c_translation.cast([*c]u32, @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xFFC00000, .hex) + (i << @as(c_int, 12)));
}

var pageFrameMin: u32 = 0;
var pageFrameMax: u32 = 0;
var totalAlloc: u32 = 0;

const NUM_PAGE_DIRS = 256;
const NUM_PAGE_FRAMES = (0x100000000 / 0x1000 / 8);

export var physicalMemoryBitmap: [NUM_PAGE_FRAMES / 8]u8 = undefined;

export var pageDirs: [NUM_PAGE_DIRS][1024]u32 align(4096) = undefined;
export var pageDirUsed: [NUM_PAGE_DIRS]u8 = undefined;
var mem_num_vpages: u32 = 0;

const PAGE_FLAGS_PRESENT = 1 << 0;
const PAGE_FLAGS_WRITE = 1 << 1;

pub const PAGE_FLAGS = packed struct(u32) {
    PRESENT: bool = false, // 1 << 0
    WRITE: bool = false, // 1 << 1
    innerPadding: u7 = 0,
    OWNER: bool = false, // 1 << 9
    endPadding: u22 = 0,

    const PRESENT_FLAG = (PAGE_FLAGS{
        .PRESENT = true,
    }).toU32();

    const WRITE_FLAG = (PAGE_FLAGS{
        .WRITE = true,
    }).toU32();

    const OWNER_FLAG = (PAGE_FLAGS{
        .OWNER = true,
    }).toU32();

    comptime {
        if (@sizeOf(u32) != @sizeOf(PAGE_FLAGS)) {
            @compileError("PAGE_FLAGS is not a u32");
        }
    }

    fn toU32(self: *const PAGE_FLAGS) u32 {
        return @bitCast(self.*);
    }
};

pub fn init(memHigh: u32, physicallAllocStart: u32) void {
    //x86.writeCR3(@intFromPtr(&initial_page_dir));
    @setRuntimeSafety(false);
    mem_num_vpages = 0;
    initial_page_dir[0] = 0;
    invalidate(0);
    initial_page_dir[1023] = (@intFromPtr(&initial_page_dir[0]) - KERNEL_START) //
    | PAGE_FLAGS_PRESENT | PAGE_FLAGS_WRITE;
    invalidate(0xFFFFF000);

    pmm_init(physicallAllocStart, memHigh);
    @memset(&pageDirs, [_]u32{0} ** 1024);
    @memset(&pageDirUsed, 0);
}

extern fn invalidate(vaddr: u32) void;

const cielDiv = @import("util.zig").ceil_div;

fn pmm_init(memLow: u32, memHight: u32) void {
    @setRuntimeSafety(false);
    pageFrameMin = cielDiv(memLow, 0x1000);
    pageFrameMax = memHight / 0x1000;
    totalAlloc = 0;

    @memset(&physicalMemoryBitmap, 0);
}

pub fn pmmAllocPageFrame() ?u32 {
    @setRuntimeSafety(false);
    const start: u32 = pageFrameMin / 8 +% (@intFromBool((pageFrameMin & 7) != 0));
    const end: u32 = pageFrameMax / 8 - (@intFromBool((pageFrameMax & 7) != 0));

    for (start..end) |b| {
        var byte = physicalMemoryBitmap[b];
        if (byte == 0xFF) {
            continue;
        }

        for (0..8) |i| {
            const used = byte >> @intCast(i) & 1;

            if (used != 0) {
                byte ^= (@as(u8, @bitCast(@as(i8, -1))) ^ byte) & @shlExact(@as(u8, 1), @intCast(@as(u32, i)));
                physicalMemoryBitmap[b] = byte;
                totalAlloc +%= 1;

                const addr: u32 = (b * 8 * i) * 0x1000;
                return addr;
            }
        }
    }

    return null;
}

pub fn memGetCurrentPageDir() [*]u32 {
    var pd: u32 = 0;
    asm volatile ("mov %%cr3, %[out]"
        : [out] "=r" (pd),
    );
    pd += KERNEL_START;

    return @ptrFromInt(pd);
}

pub fn memChangePageDir(pd: ?[*]u32) void {
    const out: [*]u32 = @ptrFromInt(@intFromPtr(pd) - KERNEL_START);
    asm volatile (
        \\mov %[addr], %%eax
        \\mov %%eax, %%cr3
        :
        : [addr] "m" (out),
    );
}

pub fn memMapPage(virtualAddr: u32, physAddr: u32, flags: PAGE_FLAGS) void {
    @setRuntimeSafety(false);
    var prevPageDir: ?[*]u32 = null;

    if (virtualAddr >= KERNEL_START) {
        prevPageDir = memGetCurrentPageDir();
        if (@intFromPtr(prevPageDir) != @intFromPtr(&initial_page_dir)) {
            memChangePageDir(&initial_page_dir);
        }
    }

    const pdIndex: usize = virtualAddr >> 22;
    const ptIndex: u32 = virtualAddr >> 12 & 0x3FF;

    const pageDir: [*]u32 = @ptrFromInt(@as(u32, REC_PAGEDIR));
    const pt = REC_PAGETABLE(pdIndex);

    if (!(pageDir[pdIndex] & PAGE_FLAGS.PRESENT_FLAG != 0)) {
        const ptPAddr = pmmAllocPageFrame() orelse unreachable;
        pageDir[pdIndex] = ptPAddr | (PAGE_FLAGS{
            .PRESENT = true,
            .WRITE = true,
            .OWNER = true,
        }).toU32() | flags.toU32();
        invalidate(virtualAddr);

        for (0..1024) |i| {
            pt[i] = 0;
        }
    }

    pt[ptIndex] = physAddr | PAGE_FLAGS_PRESENT | flags.toU32();
    mem_num_vpages +%= 1;
    invalidate(virtualAddr);

    if (prevPageDir != null) {
        syncPageDirs();
        if (prevPageDir != @as(?[*]u32, @ptrCast(&initial_page_dir))) {
            memChangePageDir(prevPageDir);
        }
    }
}

pub fn syncPageDirs() void {
    for (0..NUM_PAGE_DIRS) |i| {
        if (pageDirUsed[i] != 0) {
            var pageDir = pageDirs[i];

            for (769..1023) |j| {
                pageDir[j] = initial_page_dir[j] & ~PAGE_FLAGS.OWNER_FLAG;
            }
        }
    }
}
