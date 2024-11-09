const std = @import("std");
const fmt = @import("std").fmt;
const Writer = @import("std").io.Writer;
const x86 = @import("x86.zig");
const tty = @import("tty.zig");

const PORT = 0x3f8;

const SerialErrors = error{
    FaulySerial,
};

pub fn init() !void {
    x86.outb(PORT + 1, 0x00); // Disable all interrupts
    x86.outb(PORT + 3, 0x80); // Enable DLAB (set baud rate divisor)
    x86.outb(PORT + 0, 0x03); // Set divisor to 3 (lo byte) 38400 baud
    x86.outb(PORT + 1, 0x00); //                  (hi byte)
    x86.outb(PORT + 3, 0x03); // 8 bits, no parity, one stop bit
    x86.outb(PORT + 2, 0xC7); // Enable FIFO, clear them, with 14-byte threshold
    x86.outb(PORT + 4, 0x0B); // IRQs enabled, RTS/DSR set
    x86.outb(PORT + 4, 0x1E); // Set in loopback mode, test the serial chip
    x86.outb(PORT + 0, 0xAE); // Test serial chip (send byte 0xAE and check if serial returns same byte)

    if (x86.inb(PORT + 0) != 0xAE) {
        return SerialErrors.FaulySerial;
    }

    x86.outb(PORT + 4, 0x0F);
}

pub fn serial_recieved() bool {
    return x86.inb(PORT + 5) & 1;
}

pub fn read_serial() u8 {
    while (!serial_recieved()) {}
    return x86.inb(PORT);
}

fn is_transmit_empty() u8 {
    return x86.inb(PORT + 5) & 0x20;
}

pub fn write_serial(a: u8) void {
    while (is_transmit_empty() == 0) {}

    x86.outb(PORT, a);
}

pub const writer = Writer(void, error{}, callback){ .context = {} };

fn callback(_: void, inString: []const u8) error{}!usize {
    for (inString) |ch| {
        if (ch == '\n') {
            write_serial('\r');
        }

        write_serial(ch);
    }
    return inString.len;
}

pub fn print(comptime format: []const u8, args: anytype) void {
    fmt.format(writer, format, args) catch tty.puts("Failed to print!\n");
}
