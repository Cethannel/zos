const kstd = @import("../../kernel_std.zig");
const Memory = @import("memory.zig");

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

const TSSEntry = packed struct {
    prev_tss: u32,
    esp0: u32,
    ss0: u32,
    esp1: u32,
    ss1: u32,
    esp2: u32,
    ss2: u32,
    cr3: u32,
    eip: u32,
    eflags: u32,
    eax: u32,
    ecx: u32,
    edx: u32,
    ebx: u32,
    esp: u32,
    ebp: u32,
    esi: u32,
    edi: u32,
    es: u32,
    cs: u32,
    ss: u32,
    ds: u32,
    fs: u32,
    gs: u32,
    ldt: u32,
    trap: u32,
    iomap_base: u32,
};

extern fn gdt_flush(u32) void;
extern fn tss_flush() void;

var gdt: [6]GDTEntry = undefined;

var gdt_entries: [6]GDTEntry = undefined;
var gdt_ptr: GDTRegister = undefined;
var tss_entry: TSSEntry = undefined;

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
    writeTSS(5, 0x10, 0x0);

    gdt_flush(@intFromPtr(&gdt_ptr));
    tss_flush();
}

fn writeTSS(num: u32, ss0: u16, esp0: u32) void {
    var base: u32 = @intFromPtr(&tss_entry);
    var limit: u32 = base + @sizeOf(TSSEntry);

    setGdtGate(num, base, limit, 0xE9, 0x00);
    Memory.memset(@ptrCast(&tss_entry), 0, @sizeOf(TSSEntry));

    tss_entry.ss0 = ss0;
    tss_entry.esp0 = esp0;

    tss_entry.cs = 0x08 | 0x3;
    tss_entry.ss = 0x10 | 0x3;
    tss_entry.ds = 0x10 | 0x3;
    tss_entry.es = 0x10 | 0x3;
    tss_entry.fs = 0x10 | 0x3;
    tss_entry.gs = 0x10 | 0x3;
}
