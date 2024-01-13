const kstd = @import("../../kernel_std.zig");

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
    //base: u32,
    base: *const GDTEntry,
};

extern fn loadGDT(gdtr: *const GDTRegister) void;
extern fn reloadSegments() void;
//fn loadGDT(gdtr: *const GDTRegister) void {
//    _ = gdtr;
//}

fn createEntry(base: u32, limit: u32, flag: u32) GDTEntry {
    return GDTEntry{
        .limit_low = @intCast(limit & 0x0000FFFF),
        .base_low = @intCast(base & 0x0000FFFF),
        .base_mid = @intCast((base >> 16) & 0x000000FF),
        .access = @intCast(flag & 0xFF),
        .limit_high = @intCast((limit >> 16) & 0x0F),
        .flags = @intCast((flag >> 8) & 0x0F),
        .base_high = @intCast((base >> 24) & 0x000000FF),
    };
}

var gdt: [5]GDTEntry = undefined;

fn initGDT() GDTRegister {
    gdt[0] = createEntry(0, 0, 0);
    gdt[1] = createEntry(0, 0xFFFFFFFF, 0x9A2E);
    gdt[2] = createEntry(0, 0xFFFFFFFF, 0x92AE);
    gdt[3] = createEntry(0, 0xFFFFFFFF, 0xFA2E);
    gdt[4] = createEntry(0, 0xFFFFFFFF, 0xF2AE);

    return GDTRegister{
        .limit = @intCast(@sizeOf(@TypeOf(gdt))),
        .base = &gdt[0],
    };
}

pub fn init() void {
    const gdtr = initGDT();
    loadGDT(&gdtr);
    reloadSegments();
}
