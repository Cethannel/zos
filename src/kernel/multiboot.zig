pub const multiboot_aout_symbol_table = extern struct {
    tabsize: u32,
    strsize: u32,
    addr: u32,
    reserved: u32,
};

pub const multiboot_elf_section_header_table = extern struct {
    num: u32,
    size: u32,
    addr: u32,
    shndx: u32,
};

const multiboot_table = extern union {
    multiboot_aout_symbol_table: multiboot_aout_symbol_table,
    multiboot_elf_section_header_table: multiboot_elf_section_header_table,
};

pub const multiboot_info = extern struct {
    flags: u32,
    mem_lower: u32,
    mem_upper: u32,
    boot_device: u32,
    cmdline: u32,
    mods_count: u32,
    mods_addr: u32,
    u: multiboot_table,
    mmap_length: u32,
    mmap_addr: u32,
    drives_length: u32,
    drives_addr: u32,
    config_table: u32,
    boot_loader_name: u32,
    apm_table: u32,
    vbe_control_info: u32,
    vbe_mode_info: u32,
    vbe_mode: u16,
    vbe_interface_seg: u16,
    vbe_interface_off: u16,
    vbe_interface_len: u16,
};

pub const mmap_entry = packed struct {
    size: u32,
    base_addr_low: u32,
    base_addr_high: u32,
    length_low: u32,
    length_high: u32,
    type: u32,
};

pub const MULTIBOOT_MEMORY_AVAILABLE = 1;
pub const MULTIBOOT_MEMORY_RESERVED = 2;
pub const MULTIBOOT_MEMORY_ACPI_RECLAIMABLE = 3;
pub const MULTIBOOT_MEMORY_NVS = 4;
pub const MULTIBOOT_MEMORY_BADRAM = 5;

const MultibootHeader = extern struct {
    magic: u32, // Must be equal to header magic number.
    flags: u32, // Feature flags.
    checksum: u32, // Above fields plus this one must equal 0 mod 2^32.
};

export const multiboot_header align(4) linksection(".multiboot") = multiboot: {
    const MAGIC: u32 = 0x1BADB002; // Magic number for validation.
    const ALIGN: u32 = 1 << 0; // Align loaded modules.
    const MEMINFO: u32 = 1 << 1; // Receive a memory map from the bootloader.
    const FLAGS: u32 = ALIGN | MEMINFO; // Combine the flags.

    break :multiboot MultibootHeader{
        .magic = MAGIC,
        .flags = FLAGS,
        .checksum = ~(MAGIC +% FLAGS) +% 1,
    };
};
