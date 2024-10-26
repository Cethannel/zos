const std = @import("std");
const memory = @import("memory.zig");
const util = @import("util.zig");
const tty = @import("tty.zig");

var heapStart: u32 = undefined;
var heapSize: u32 = undefined;
var threshhold: u32 = undefined;
var kmallocInitialized: bool = false;

pub fn init(initialHeapSize: u32) void {
    heapStart = memory.KERNEL_MALLOC;
    heapSize = 0;
    threshhold = 0;
    kmallocInitialized = true;

    changeHeapSize(initialHeapSize);
}

pub fn changeHeapSize(newSize: u32) void {
    const oldPageTop = util.ceil_div(heapSize, 0x1000);
    const newPageTop = util.ceil_div(newSize, 0x1000);

    const diff = newPageTop - oldPageTop;

    for (0..diff) |i| {
        const phys = memory.pmmAllocPageFrame() orelse unreachable;
        tty.printf("Got physical addr: 0x{X}\n", .{phys});
        memory.memMapPage(memory.KERNEL_MALLOC + oldPageTop * 0x1000 + i * 0x1000, phys, memory.PAGE_FLAGS{
            .WRITE = true,
        });
    }
}
