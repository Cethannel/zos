const kstd = @import("../../kernel_std.zig");
const Multiboot = @import("multiboot.zig");
const x86 = @import("x86.zig");
const std = @import("std");

const ENTRY_COUNT: usize = 512;

pub const PageTable = extern struct {
    entries: *[ENTRY_COUNT]PageTableEntry,
};

pub const PageTableEntry = packed struct {
    /// Specifies whether the mapped frame or page table is loaded in memory.
    PRESENT: bool,
    /// Controls whether writes to the mapped frames are allowed.
    ///
    /// If this bit is unset in a level 1 page table entry, the mapped frame is read-only.
    /// If this bit is unset in a higher level page table entry the complete range of mapped
    /// pages is read-only.
    WRITABLE: bool,
    /// Controls whether accesses from userspace (i.e. ring 3) are permitted.
    USER_ACCESSIBLE: bool,
    /// If this bit is set, a “write-through” policy is used for the cache, else a “write-back”
    /// policy is used.
    WRITE_THROUGH: bool,
    /// Disables caching for the pointed entry is cacheable.
    NO_CACHE: bool,
    /// Set by the CPU when the mapped frame or page table is accessed.
    ACCESSED: bool,
    /// Set by the CPU on a write to the mapped frame.
    DIRTY: bool,
    /// Specifies that the entry maps a huge frame instead of a page table. Only allowed in
    /// P2 or P3 tables.
    HUGE_PAGE: bool,
    /// Indicates that the mapping is present in all address spaces, so it isn't flushed from
    /// the TLB on an address space switch.
    GLOBAL: bool,
    /// Available to the OS, can be used to store additional data, e.g. custom flags.
    BIT_9: bool,
    /// Available to the OS, can be used to store additional data, e.g. custom flags.
    BIT_10: bool,
    /// Available to the OS, can be used to store additional data, e.g. custom flags.
    BIT_11: bool,
    addr: u20,

    comptime {
        if (@bitSizeOf(PageTableEntry) != @bitSizeOf(u32)) {
            @compileError(
                std.fmt.comptimePrint(
                    "Wrong size of page table entry, got: {}",
                    .{@bitSizeOf(PageTableEntry)},
                ),
            );
        }
    }

    pub fn is_unused(self: *const @This()) bool {
        return @as(usize, @bitCast(self.*)) == 0;
    }
};

pub fn getPageTable() PageTable {
    const addr = x86.readCR3();

    return PageTable{
        .entries = @ptrFromInt((addr & 0xffff_f000) + 0xC0000000),
    };
}
