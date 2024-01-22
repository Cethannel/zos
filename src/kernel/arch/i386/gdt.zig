const kstd = @import("../../kernel_std.zig");

const GDTEntry = packed struct {
    limit: u16,
    base_low: u16,
    base_mid: u8,
    access: u8,
    flags: u8,
    base_high: u8,
};

const GDTRegister = packed struct {
    limit: u16,
    base: u32,
};

extern fn gdt_flush(u32) void;

var gdt: [5]GDTEntry = undefined;

var gdt_entries: [5]GDTEntry = undefined;
var gdt_ptr: GDTRegister = undefined;

fn setGdtGate(num: u32, base: u32, limit: u32, access: u8, gran: u8) void {
    gdt_entries[num].base_low = @intCast(base & 0xFFFF);
    gdt_entries[num].base_mid = @intCast((base >> 16) & 0xFF);
    gdt_entries[num].base_high = @intCast((base >> 24) & 0xFF);

    gdt_entries[num].limit = @intCast(limit & 0xFFFF);
    gdt_entries[num].flags = @intCast((limit >> 16) & 0x0F);
    gdt_entries[num].flags |= @intCast(gran & 0xF0);

    gdt_entries[num].access = access;
}

pub fn init() void {
    gdt_ptr.limit = (@sizeOf(GDTEntry) * 6) - 1;
    gdt_ptr.base = @intFromPtr(&gdt_entries);

    setGdtGate(0, 0, 0, 0, 0); // null segment
    setGdtGate(1, 0, 0xFFFFFFFF, 0x9A, 0xCF); //Kernel code segment
    setGdtGate(2, 0, 0xFFFFFFFF, 0x92, 0xCF); //Kernel data segment
    setGdtGate(3, 0, 0xFFFFFFFF, 0xFA, 0xCF); //User code segment
    setGdtGate(4, 0, 0xFFFFFFFF, 0xF2, 0xCF); //User data segment

    gdt_flush(@intFromPtr(&gdt_ptr));
}
