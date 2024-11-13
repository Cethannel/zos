const std = @import("std");
const fmt = @import("std").fmt;
const Writer = @import("std").io.Writer;
const x86 = @import("x86.zig");
const tty = @import("tty.zig");
const Idt = @import("idt.zig");

const PORT = 0x3f8;

const SerialErrors = error{
    FaulySerial,
};

fn serialInterruptHandler(args: *Idt.InterruptRegisters) void {
    _ = args;

    tty.printf("Got serial interrupt", .{});

    while (serial_recieved()) {
        const c: u8 = x86.inb(PORT);
        write_serial(c);
    }
}

pub fn init_interrupt() !void {
    Idt.irq_install_handler(4, serialInterruptHandler);
}

pub fn init() !void {
    x86.outb(PORT + 1, 0x00); // Disable all interrupts
    x86.outb(PORT + 3, 0x80); // Enable DLAB (set baud rate divisor)
    x86.outb(PORT + 0, 0x0C); // Set divisor to 3 (lo byte) 38400 baud
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
    return x86.inb(PORT + 5) & 1 != 0;
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
    for (inString, 0..) |ch, i| {
        if (ch == '\n' and (i == 0 or inString[i - 1] != '\r')) {
            write_serial('\r');
        }

        write_serial(ch);
    }
    return inString.len;
}

pub fn print(comptime format: []const u8, args: anytype) void {
    fmt.format(writer, format, args) catch tty.puts("Failed to print!\n");
}

pub fn indent_print(indent: usize, comptime format: []const u8, args: anytype) void {
    for (0..indent) |_| {
        print("  ", .{});
    }

    print(format, args);
}

pub fn debug_print(input: anytype) void {
    inner_debug_print(0, input);
    print("\n", .{});
}

pub fn inner_debug_print(indent: usize, input: anytype) void {
    const ti = @typeInfo(@TypeOf(input));
    if (std.meta.hasFn(@TypeOf(input), "debug_print")) {
        input.debug_print(indent);
    } else {
        switch (ti) {
            .Struct => |st| {
                indent_print(0, "{s} : {{\n", .{@typeName(@TypeOf(input))});
                inline for (st.fields) |field| {
                    if (field.name.len != 0 and field.name[0] != '_') {
                        indent_print(indent + 1, "{s} = ", .{field.name});
                        inner_debug_print(indent + 1, @field(input, field.name));
                        print("\n", .{});
                    }
                }
                indent_print(indent, "}}", .{});
            },
            .Int => {
                print("0x{x}", .{input});
            },
            .Bool => {
                print("{}", .{input});
            },
            .Union => |un| {
                if (un.tag_type) |UnionTagType| {
                    indent_print(0, ".{s} = ", .{@tagName(input)});
                    inline for (un.fields) |u_field| {
                        if (input == @field(UnionTagType, u_field.name)) {
                            inner_debug_print(indent + 1, @field(input, u_field.name));
                        }
                    }
                } else {
                    @compileError("Cannot print untagged unions");
                }
            },
            .Void => {
                print("void", .{});
            },
            else => {
                @compileError(&std.fmt.comptimePrint("Unsupported type: {s}", .{@tagName(ti)}).*);
            },
        }
    }
}
