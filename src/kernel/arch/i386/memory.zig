const kstd = @import("../../kernel_std.zig");
const Multiboot = @import("../../multiboot.zig");
const Util = @import("util.zig");

const initial_page_dir = @extern(*[1024]u32, .{ .name = "initial_page_dir" });
const KERNEL_START: u32 = 0xC0000000;
const TTY_BUFFER: u32 = 0xC00B8000;

const PAGE_PRESENT: u32 = 1 << 0;
const PAGE_WRITE: u32 = 1 << 1;

var page_frame_min: u32 = 0;
var page_frame_max: u32 = 0;
var total_allocated: u32 = 0;

const NUM_PAGE_DIRS: u32 = 256;
const NUM_PAGE_FRAMES: u32 = (0x100000000 / 0x1000 / 8);

// TODO: Should be dynamic and a bit array
var physical_memory_bitmap: [NUM_PAGE_FRAMES / 8]u8 = undefined;

var page_dirs: [NUM_PAGE_DIRS][1024]u32 align(4096) = undefined;
var page_dirs_used: [NUM_PAGE_DIRS]u32 = undefined;

fn pmmInit(memLow: u32, mem_high: u32) void {
    page_frame_min = Util.ceil_div(memLow, 0x1000);
    page_frame_max = mem_high / 0x1000;
    total_allocated = 0;

    memset(@ptrCast(&physical_memory_bitmap), 0, NUM_PAGE_FRAMES / 8);
}

const ABOSULT_VGA_BUFFER: u32 = 0xB8000;

pub fn init(mem_high: u32, physical_alloc_start: u32) void {
    initial_page_dir[0] = 0;
    invalidate(0);
    // Map the first 4MB of memory
    initial_page_dir[1023] = (@intFromPtr(initial_page_dir) - KERNEL_START) | PAGE_PRESENT | PAGE_WRITE;
    invalidate(0xFFFFF000);
    // Map the VGA buffer
    initial_page_dir[0xB8] = (TTY_BUFFER - KERNEL_START) | PAGE_PRESENT | PAGE_WRITE;
    invalidate(0xC00B8000);

    pmmInit(physical_alloc_start, mem_high);
    memset(@ptrCast(&page_dirs), 0, 0x1000 * NUM_PAGE_DIRS);
    memset(@ptrCast(&page_dirs_used), 0, NUM_PAGE_DIRS);
}

extern fn invalidate(addr: u32) void;

pub fn memset(ptr: [*]u8, value: u8, count: usize) void {
    var counti = count;
    var ptri: [*]u8 = ptr;
    while (counti > 0) : (counti -= 1) {
        ptri[0] = value;
        ptri += 1;
    }
}

pub fn get_physaddr(virtualaddr: usize) usize {
    var pdindex: u32 = virtualaddr >> 22;
    var ptindex: u32 = virtualaddr >> 12 & 0x03FF;

    //var pd: *u32 = 0xFFFFF000;
    // Here you need to check whether the PD entry is present.

    var pt: [*]u32 = @ptrFromInt((0xFFC00000) + (0x400 * pdindex));
    // Here you need to check whether the PT entry is present.

    var fff: u32 = 0xFFF;
    return ((pt[ptindex] & ~fff) + (virtualaddr & 0xFFF));
}

pub fn eql(comptime T: type, a: []const T, b: []const T) bool {
    if (a.len != b.len) return false;
    if (a.ptr == b.ptr) return true;
    for (a, b) |a_elem, b_elem| {
        if (a_elem != b_elem) return false;
    }
    return true;
}

fn map_page(physaddr: u32, virtualaddr: u32, flags: u32) void {
    // Make sure that both addresses are page-aligned.

    var pdindex: u32 = virtualaddr >> 22;
    var ptindex: u32 = virtualaddr >> 12 & 0x03FF;

    var pd: [*]u32 = @ptrCast(&page_dirs[pdindex]);
    _ = pd;
    // Here you need to check whether the PD entry is present.
    // When it is not present, you need to create a new empty PT and
    // adjust the PDE accordingly.

    var pt: [*]u32 = @ptrCast(&page_dirs[pdindex][ptindex]);
    // Here you need to check whether the PT entry is present.
    // When it is, then there is already a mapping present. What do you do now?

    pt[ptindex] = physaddr | flags;

    // Now you need to flush the entry in the TLB
    // or you might not notice the change.
    invalidate(virtualaddr);
}

fn allocate_page_frame() u32 {
    var page_frame: u32 = 0;
    var page_frame_index: u32 = 0;
    while (page_frame_index < NUM_PAGE_FRAMES) : (page_frame_index += 1) {
        var anded: u32 = (@as(u32, 1) << @intCast(page_frame_index % 8));
        if (physical_memory_bitmap[page_frame_index / 8] & anded == 0) {
            page_frame = page_frame_index;
            break;
        }
    }

    if (page_frame == 0) {
        kstd.kpanic("Out of memory", .{});
    }

    physical_memory_bitmap[page_frame / 8] |= @as(u8, 1) << @intCast(page_frame % 8);
    total_allocated += 1;

    return page_frame * 0x1000;
}

pub fn map_kernel() void {
    map_page(0x00000000, 0xC0000000, PAGE_PRESENT | PAGE_WRITE);
}

pub fn initialize_vga_buffer_page() void {
    map_page(@ptrFromInt(0xC00B8000), @ptrFromInt(0xC00B8000), PAGE_PRESENT | PAGE_WRITE);
}
