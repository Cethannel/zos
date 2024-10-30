const kstd = @import("../../kernel_std.zig");
const Memory = @import("memory.zig");
const x86 = @import("x86.zig");
const std = @import("std");

pub const KERNEL_CODE = 0x08;
pub const KERNEL_DATA = 0x10;
pub const USER_CODE = 0x18;
pub const USER_DATA = 0x20;
pub const TSS_DESC = 0x2B;

// Privilege level of segment selector.
pub const KERNEL_RPL = 0b00;
pub const USER_RPL = 0b11;

// Access byte values.
const KERNEL = 0x90;
const USER = 0xF0;
const CODE = 0x0A;
const DATA = 0x02;
const TSS_ACCESS = 0x89;

// Segment flags.
const PROTECTED: u4 = (1 << 2);
const BLOCKS_4K: u4 = (1 << 3);

extern fn gdt_load(*GdtPtr) void;

const GdtPtr = packed struct {
    limit: u16,
    base: u32,
};

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
    base: *const GDTEntry,
};

// Task State Segment.
const TSS = packed struct {
    prev_tss: u32 = 0,
    esp0: u32 = 0,
    ss0: u32 = 0,
    esp1: u32 = 0,
    ss1: u32 = 0,
    esp2: u32 = 0,
    ss2: u32 = 0,
    cr3: u32 = 0,
    eip: u32 = 0,
    eflags: u32 = 0,
    eax: u32 = 0,
    ecx: u32 = 0,
    edx: u32 = 0,
    ebx: u32 = 0,
    esp: u32 = 0,
    ebp: u32 = 0,
    esi: u32 = 0,
    edi: u32 = 0,
    es: u32 = 0,
    cs: u32 = 0,
    ss: u32 = 0,
    ds: u32 = 0,
    fs: u32 = 0,
    gs: u32 = 0,
    ldt: u32 = 0,
    trap: u32 = 0,
    iomap_base: u32 = 0,
};

////
// Generate a GDT entry structure.
//
// Arguments:
//     base: Beginning of the segment.
//     limit: Size of the segment.
//     access: Access byte.
//     flags: Segment flags.
//
fn makeEntry(base: u32, limit: u32, access: u8, flags: u8) GDTEntry {
    return GDTEntry{
        .base_low = @truncate(base & 0xFFFF),
        .base_mid = @truncate((base >> 16) & 0xFF),
        .base_high = @truncate((base >> 24) & 0xFF),
        .limit = @truncate(limit & 0xFFFF),
        .flags = @as(u8, @truncate((limit >> 16 & 0x0F))) | (flags & 0xF0),
        .access = access,
    };
}

// Fill in the GDT.
var gdt align(4) = [_]GDTEntry{
    makeEntry(0, 0, 0, 0),
    makeEntry(0, 0xFFFFF, KERNEL | CODE, 0xCF),
    makeEntry(0, 0xFFFFF, KERNEL | DATA, 0xCF),
    makeEntry(0, 0xFFFFF, USER | CODE, 0xCF),
    makeEntry(0, 0xFFFFF, USER | DATA, 0xCF),
    makeEntry(0, 0, 0, 0), // TSS (fill in at runtime).
};

// GDT descriptor register pointing at the GDT.
var gdtr = GDTRegister{
    .limit = @sizeOf(@TypeOf(gdt)),
    .base = undefined, // &gdt[0],
};

// Instance of the Task State Segment.
var tss = TSS{
    .esp0 = undefined,
    .ss0 = KERNEL_DATA,
    .iomap_base = @sizeOf(TSS),
};

////
// Set the kernel stack to use when interrupting user mode.
//
// Arguments:
//     esp0: Stack for Ring 0.
//
pub fn setKernelStack(esp0: usize) void {
    tss.esp0 = esp0;
}

////
// Load the GDT into the system registers (defined in assembly).
//
// Arguments:
//     gdtr: Pointer to the GDTR.
//
extern fn loadGDT(gdtr: *const GDTRegister) void;

fn wrietTSS(ss0: u32, esp0: u32) void {
    const base: u32 = @intFromPtr(&tss);
    const limit = base + @sizeOf(TSS);
    gdt[gdt.len - 1] = makeEntry(base, limit, 0xE9, 0x00);

    tss = TSS{};
    tss.ss0 = ss0;
    tss.esp0 = esp0;
    tss.cs = 0x08 | 0x3;
    inline for ([_][]const u8{ "ds", "es", "fs", "gs" }) |field| {
        @field(tss, field) = 0x10 | 0x3;
    }
}

pub fn init() void {
    gdtr.base = &gdt[0];
    gdtr.limit = @sizeOf(GDTEntry) * 6 - 1;
    //loadGDT(@ptrFromInt(0x100));
    // Initialize TSS.
    wrietTSS(0x10, 0x0);
    loadGDT(&gdtr);

    tss_flush();
}

extern fn tss_flush() void;
