const std = @import("std");
const Util = @import("util.zig");
const Idt = @import("idt.zig");
const x86 = @import("x86.zig");
const TTY = @import("tty.zig");
const serial = @import("serial.zig");
const kstd = @import("../../kernel_std.zig");

pub fn init() void {
    Idt.irq_install_handler(1, keyboardHandler);
}

var capsOn = false;
var capsLock = false;

const conv = std.builtin.CallingConvention.Interrupt;

fn keyboardHandler(args: *Idt.InterruptRegisters) void {
    _ = args;
    @setRuntimeSafety(false);
    const scancode: u8 = Util.inb(0x60) & 0x7F;
    const pressed = (Util.inb(0x60) & 0x80) == 0;

    switch (scancode) {
        1, 29, 56, 59, 60, 61, 62, 63, 64, 65, 66, 67 => {},
        42 => {
            if (pressed) {
                capsOn = true;
            } else {
                capsOn = false;
            }
        },
        58 => {
            if (!capsLock and pressed) {
                capsLock = true;
            } else if (capsLock and pressed) {
                capsLock = false;
            }
        },
        else => {
            if (pressed) {
                if (capsOn or capsLock) {
                    const c: u8 = @intCast(uppercase[scancode]);
                    TTY.putc(c);
                    serial.write_serial(c);
                } else {
                    const c: u8 = @intCast(lowercase[scancode]);
                    TTY.putc(c);
                    serial.write_serial(c);
                }
            }
        },
    }
}

const UNKNOWN = 0xFFFFFFFF;
const ESC = 0xFFFFFFFF - 1;
const CTRL = 0xFFFFFFFF - 2;
const LSHFT = 0xFFFFFFFF - 3;
const RSHFT = 0xFFFFFFFF - 4;
const ALT = 0xFFFFFFFF - 5;
const F1 = 0xFFFFFFFF - 6;
const F2 = 0xFFFFFFFF - 7;
const F3 = 0xFFFFFFFF - 8;
const F4 = 0xFFFFFFFF - 9;
const F5 = 0xFFFFFFFF - 10;
const F6 = 0xFFFFFFFF - 11;
const F7 = 0xFFFFFFFF - 12;
const F8 = 0xFFFFFFFF - 13;
const F9 = 0xFFFFFFFF - 14;
const F10 = 0xFFFFFFFF - 15;
const F11 = 0xFFFFFFFF - 16;
const F12 = 0xFFFFFFFF - 17;
const SCRLCK = 0xFFFFFFFF - 18;
const HOME = 0xFFFFFFFF - 19;
const UP = 0xFFFFFFFF - 20;
const LEFT = 0xFFFFFFFF - 21;
const RIGHT = 0xFFFFFFFF - 22;
const DOWN = 0xFFFFFFFF - 23;
const PGUP = 0xFFFFFFFF - 24;
const PGDOWN = 0xFFFFFFFF - 25;
const END = 0xFFFFFFFF - 26;
const INS = 0xFFFFFFFF - 27;
const DEL = 0xFFFFFFFF - 28;
const CAPS = 0xFFFFFFFF - 29;
const NONE = 0xFFFFFFFF - 30;
const ALTGR = 0xFFFFFFFF - 31;
const NUMLCK = 0xFFFFFFFF - 32;

const lowercase = [_]u32{ UNKNOWN, ESC, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', 8, '\t', 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', '\n', CTRL, 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', '\'', '`', LSHFT, '\\', 'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/', RSHFT, '*', ALT, ' ', CAPS, F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, NUMLCK, SCRLCK, HOME, UP, PGUP, '-', LEFT, UNKNOWN, RIGHT, '+', END, DOWN, PGDOWN, INS, DEL, UNKNOWN, UNKNOWN, UNKNOWN, F11, F12, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN };

const uppercase = [_]u32{ UNKNOWN, ESC, '!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '_', '+', 8, '\t', 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', '{', '}', '\n', CTRL, 'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', ':', '"', '~', LSHFT, '|', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', '<', '>', '?', RSHFT, '*', ALT, ' ', CAPS, F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, NUMLCK, SCRLCK, HOME, UP, PGUP, '-', LEFT, UNKNOWN, RIGHT, '+', END, DOWN, PGDOWN, INS, DEL, UNKNOWN, UNKNOWN, UNKNOWN, F11, F12, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN };
