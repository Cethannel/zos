const kstd = @import("../../kernel_std.zig");
const Multiboot = @import("../../multiboot.zig");

pub fn init(boot_info: *Multiboot.multiboot_info) void {
    var i: u32 = 0;
    while (i < boot_info.mmap_length) {
        var mmmt: *Multiboot.mmap_entry = @ptrFromInt(boot_info.mmap_addr + i);
        kstd.print("Low addr: {} | High addr: {} | Length low: {} | Length High: {} | Size: {} | Type: {}\n", .{ mmmt.base_addr_low, mmmt.base_addr_high, mmmt.length_low, mmmt.length_high, mmmt.size, mmmt.type });

        i += @sizeOf(Multiboot.mmap_entry);
    }
}
