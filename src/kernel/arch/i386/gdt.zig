const kstd = @import("/kernel/kernel_std.zig");

const GDTEntry = packed struct {
    limit_low: u16,
    base_low: u16,
    base_mid: u8,
    access: u8,
    limit_high: u4,
    flags: u4,
    base_high: u8,
};

const GDTRegister = packed struct {
    limit: u16,
    base: *const GDTEntry,
};

extern fn loadGDT(gdtr: *const GDTRegister) void;

fn create_entry(base: u32, limit: u32, flag: u32) GDTEntry {
    var entry: GDTEntry = undefined;

    // Create the high 32 bit segment
    entry.limit_low = limit & 0x0000FFFF; // set limit bits 0:15
    entry.base_low = base & 0x0000FFFF; // set base bits 0:15
    entry.base_mid = @shrExact(base, 16) & 0x000000FF; // set base bits 16:23
    //entry.base_mid = (base >> 16) & 0x000000FF; // set base bits 16:23
    entry.access = flag & 0xFF; // set type, p, dpl, s, g, d/b, l and avl fields
    entry.limit_high = (limit >> 16) & 0x0F; // set limit bits 16:19
    entry.flags = (flag >> 8) & 0x0F; // set segment type, p, dpl, s, g, d/b, l and avl fields
    entry.base_high = (base >> 24) & 0x000000FF; // set base bits 24:31

    return entry;
}

const gdt = [_]GDTEntry{
    create_entry(0, 0, 0), // null segment
    create_entry(0, 0xFFFFFFFF, 0x9A2E), // kernel code segment
    create_entry(0, 0xFFFFFFFF, 0x92AE), // kernel data segment
    create_entry(0, 0xFFFFFFFF, 0xFA2E), // user code segment
    create_entry(0, 0xFFFFFFFF, 0xF2AE), // user data segment
};

const GDT = GDTRegister{
    .limit = @as(u16, @sizeOf(@TypeOf(gdt))),
    .base = &gdt[0],
};

pub fn init() void {
    loadGDT(&GDT);
}
