const fmt = @import("std").fmt;
const Writer = @import("std").io.Writer;
const vga_color = @import("vga.zig").vga_color;
const Memory = @import("memory.zig");
const vga_entry_color = @import("vga.zig").vga_entry_color;
pub const vga_entry = @import("vga.zig").vga_entry;
const x86 = @import("x86.zig");

const mem = @import("std").mem;

const VGA_WIDTH = 80;
const VGA_HEIGHT = 25;
const VGA_SIZE = VGA_WIDTH * VGA_HEIGHT;

var terminal_row: u8 = 0;
var terminal_column: u8 = 0;
pub var terminal_color = vga_entry_color(.VGA_COLOR_LIGHT_GREY, .VGA_COLOR_BLACK);
var terminal_buffer: [*]volatile u16 = @ptrFromInt(0xC00B8000);
//const terminal_buffer: [*]u16 = @ptrFromInt(0xB8000);
//extern const terminal_buffer: [*c]volatile u16; // = @ptrFromInt(0xB8000);
const basic_color = vga_entry_color(vga_color.VGA_COLOR_LIGHT_GREY, vga_color.VGA_COLOR_BLACK);

fn terminal_setcolor(color: u8) void {
    terminal_color = color;
}

pub fn clear() void {
    @memset(terminal_buffer[0..VGA_SIZE], vga_entry(' ', basic_color));
}

pub fn terminal_putentryat(c: u8, color: u8, x: usize, y: usize) void {
    const index = y * VGA_WIDTH + x;
    terminal_buffer[index] = vga_entry(c, color);
}

pub const putCharError = error{
    Zero,
};

pub fn terminal_putchar(c: u8) !void {
    @setRuntimeSafety(false);
    if (c == 0) {
        return error.Zero;
    }

    if (c == '\n') {
        new_line();
        return;
    }
    if (c == '\r') {
        terminal_column = 0;
        return;
    }
    if (c == 8) {
        if (terminal_column == 0) {
            move_up();
        }
        terminal_column -= 1;
        terminal_putentryat(' ', terminal_color, terminal_column, VGA_HEIGHT - 1);
        return;
    }
    terminal_putentryat(c, terminal_color, terminal_column, VGA_HEIGHT - 1);
    terminal_column += 1;
    if (terminal_column == VGA_WIDTH) {
        new_line();
    }
}

fn move_up() void {
    for (0..(VGA_HEIGHT - 1)) |row| {
        for (0..VGA_WIDTH) |col| {
            terminal_buffer[(row + 1) * VGA_WIDTH + col] = terminal_buffer[row * VGA_WIDTH + col];
        }
    }
    clear_row(0);
    terminal_column = VGA_WIDTH;
}

fn new_line() void {
    @setRuntimeSafety(false);
    for (1..VGA_HEIGHT) |row| {
        for (0..VGA_WIDTH) |col| {
            terminal_buffer[(row - 1) * VGA_WIDTH + col] = terminal_buffer[row * VGA_WIDTH + col];
        }
    }
    clear_row(VGA_HEIGHT - 1);
    terminal_column = 0;
}

fn clear_row(row: usize) void {
    const blank = vga_entry(' ', basic_color);
    for (0..VGA_WIDTH) |col| {
        terminal_buffer[row * VGA_WIDTH + col] = blank;
    }
}

var printing_error = false;

fn putCharErr(s: []const u8, i: usize) void {
    if (!printing_error) {
        printing_error = true;
        defer printing_error = false;
        printf("\nERROR: Got zero in: {s} at {}\n", .{ s, i });
    }
}

pub fn terminal_write(s: []const u8) void {
    for (0..s.len) |i| {
        terminal_putchar(s[i]) catch putCharErr(s, i);
    }
}

pub fn write_test() void {
    printf("Video buffer is at: 0x{*}\n", .{terminal_buffer});
}

pub fn initialize() void {
    terminal_row = 0;
    terminal_column = 0;
    terminal_color = vga_entry_color(.VGA_COLOR_LIGHT_GREY, .VGA_COLOR_BLACK);
    //terminal_buffer = @as(*[VGA_SIZE]u16, 0xB8000);

    for (0..VGA_HEIGHT) |y| {
        for (0..VGA_WIDTH) |x| {
            terminal_putentryat(0, 0, x, y);
        }
    }
}

pub fn reinit() void {
    terminal_buffer = @ptrFromInt(0xC00B8000);
}

const WriterError = error{
    Null,
};

pub const writer = Writer(void, WriterError, callback){ .context = {} };

fn callback(_: void, inString: []const u8) WriterError!usize {
    const str: ?[]const u8 = @ptrCast(inString);
    if (str) |string| {
        if (string.len == 0) {
            return 0;
        }
        terminal_write(string);
        return string.len;
    } else {
        return error.Null;
    }
}

pub fn printf(comptime format: []const u8, args: anytype) void {
    fmt.format(writer, format, args) catch puts("Failed to print!\n");
}

pub fn panic(comptime format: []const u8, args: anytype) noreturn {
    printf("\n", .{});
    terminal_color = vga_entry_color(.VGA_COLOR_WHITE, .VGA_COLOR_BLACK);
    printf(format, args);

    x86.hang();
}

pub export fn puts(message: [*:0]const u8) void {
    var i: usize = 0;
    while (message[i] != 0) : (i += 1) {
        terminal_putchar(message[i]) catch putCharErr(message[0..i], i);
        //i += 1;
    }
}

pub export fn putc(c: u8) void {
    terminal_putchar(c) catch {};
}

pub fn printExample() void {
    puts("Hello there" ++ [_]u8{0});
}
