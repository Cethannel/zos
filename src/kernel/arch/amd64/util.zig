const tty = @import("tty.zig");
const std = @import("std");

pub const InterruptRegisters = extern struct {
    cr2: u32,
    ds: u32,
    edi: u32,
    esi: u32,
    ebp: u32,
    esp: u32,
    ebx: u32,
    edx: u32,
    ecx: u32,
    eax: u32,
    int_no: u32,
    err_code: u32,
    eip: u32,
    csm: u32,
    eflags: u32,
    useresp: u32,
    ss: u32,
};

pub extern fn outb(port: u16, value: u8) void;
pub extern fn inb(port: u16) u8;

pub inline fn ceil_div(a: u32, b: u32) u32 {
    return ((a +% b) -% 1) / b;
}

pub inline fn panic(msg: []const u8) noreturn {
    tty.printf("PANIC: {s}\n", .{msg});
    while (true) {}
}
