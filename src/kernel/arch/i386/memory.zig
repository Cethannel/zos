const kstd = @import("../../kernel_std.zig");
const Multiboot = @import("../../multiboot.zig");
const x86 = @import("x86.zig");
const std = @import("std");

pub extern var initial_page_dir: [1024]u32 align(4096);

pub const KERNEL_START = 0xC0000000;

var pageFrameMin: u32 = 0;
var pageFrameMax: u32 = 0;
var totalAlloc: u32 = 0;

const NUM_PAGE_DIRS = 256;
const NUM_PAGE_FRAMES = (0x100000000 / 0x1000 / 8);

export var physicalMemoryBitmap: [NUM_PAGE_FRAMES / 8]u8 = undefined;

export var pageDirs: [NUM_PAGE_DIRS][1024]u32 align(4096) = undefined;
export var pageDirUsed: [NUM_PAGE_DIRS]u8 = undefined;

const PAGE_FLAGS_PRESENT = 1 << 0;
const PAGE_FLAGS_WRITE = 1 << 1;

pub const PAGE_FLAGS = packed struct(u32) {
    PRESENT: bool,
    WRITE: bool,
    padding: u30 = 0,
};

pub fn init(memHigh: u32, physicallAllocStart: u32) void {
    //x86.writeCR3(@intFromPtr(&initial_page_dir));
    @setRuntimeSafety(false);
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

inline fn cielDiv(a: u32, b: u32) u32 {
    return ((a +% b) -% 1) / b;
}

fn pmm_init(memLow: u32, memHight: u32) void {
    @setRuntimeSafety(false);
    pageFrameMin = cielDiv(memLow, 0x1000);
    pageFrameMax = memHight / 0x1000;
    totalAlloc = 0;

    @memset(&physicalMemoryBitmap, 0);
}
