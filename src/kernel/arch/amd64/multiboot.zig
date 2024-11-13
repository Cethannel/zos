// zig fmt: off
const tty = @import("tty.zig");
//const Process = @import("process.zig").Process;

// This should be in EAX.
pub const MULTIBOOT_BOOTLOADER_MAGIC = 0x2BADB002;

// Is there basic lower/upper memory information?
pub const MULTIBOOT_INFO_MEMORY      = 0x00000001;
// Is there a full memory map?
pub const MULTIBOOT_INFO_MEM_MAP     = 0x00000040;


pub const AoutSymbolTable = extern struct
{
  tabsize: u32,
  strsize: u32,
  addr: u32,
  reserved: u32,
};

pub const ElfSectionHeaderTable = extern struct 
{
  num: u32,
  size: u32,
  addr: u32,
  shndx: u32,
};

// System information structure passed by the bootloader.
pub const MultibootInfo = extern struct {
  // Multiboot info version number */
  flags: u32,

  // Available memory from BIOS */
  mem_lower: u32,
  mem_upper: u32,

  // "root" partition */
  boot_device: u32,

  // Kernel command line */
  cmdline: u32,

  // Boot-Module list */
  mods_count: u32,
  mods_addr: u32,

  u: extern union {
        aout_sym: AoutSymbolTable,
        elf_sec: ElfSectionHeaderTable,
  },

  // Memory Mapping buffer */
  mmap_length: u32,
  mmap_addr: [*]MmapEntry,

  // Drive Info buffer */
  drives_length: u32,
  drives_addr: u32,

  // ROM configuration table */
  config_table: u32,

  // Boot Loader Name */
  boot_loader_name: u32,

  // APM table */
  apm_table: u32,

  // Video */
  vbe_control_info: u32,
  vbe_mode_info: u32,
  vbe_mode: u16,
  vbe_interface_seg: u16,
  vbe_interface_off: u16,
  vbe_interface_len: u16,

  framebuffer_addr: u64,
  framebuffer_pitch: u32,
  framebuffer_width: u32,
  framebuffer_height: u32,
  framebuffer_bpp: u8,
  framebuffer_type: u8,

  
    ////
    // Return the ending address of the last module.
    //
    pub fn lastModuleEnd(self: *const MultibootInfo) usize {
        if (self.mods_count > 0) {
            const mods: [*]MultibootModule = @ptrFromInt(self.mods_addr);
            return mods[self.mods_count - 1].mod_end;
        } else {
            return self.mods_addr + 4;
        }
    }
};

pub const MULTIBOOT_FRAMEBUFFER_TYPE_INDEXED=0;
pub const MULTIBOOT_FRAMEBUFFER_TYPE_RGB    =1;
pub const MULTIBOOT_FRAMEBUFFER_TYPE_EGA_TEXT =   2;

pub const MmapEntry = packed struct
{
  size: u32,
  addr_low: u32,
  addr_high: u32,
  //addr: u64,
  len_low: u32,
  len_high: u32,
  //len: u32,
  type: u32,
};

pub const MULTIBOOT_MEMORY_AVAILABLE             =1;
pub const MULTIBOOT_MEMORY_RESERVED              =2;
pub const MULTIBOOT_MEMORY_ACPI_RECLAIMABLE      =3;
pub const MULTIBOOT_MEMORY_NVS                   =4;
pub const MULTIBOOT_MEMORY_BADRAM                =5;


// Types of memory map entries.

// Entries in the memory map.
pub const MultibootMMapEntry = packed struct {
    size: u32,
    addr: u64,
    len:  u64,
    type: u32,
};

pub const MultibootModule = packed struct {
    // The memory used goes from bytes 'mod_start' to 'mod_end-1' inclusive.
    mod_start: u32,
    mod_end:   u32,

    cmdline:   u32,  // Module command line.
    pad:       u32,  // Padding to take it to 16 bytes (must be zero).
};

// Multiboot structure to be read by the bootloader.
const MultibootHeader = extern struct {
    magic:    u32,  // Must be equal to header magic number.
    flags:    u32,  // Feature flags.
    checksum: u32,  // Above fields plus this one must equal 0 mod 2^32.
    header_addr: u32 = 0,
    load_addr: u32 = 0,
    load_end_addr: u32 = 0,
    bss_end_addr: u32 = 0,
    entry_addr: u32 = 0,
    mode_type: u32 = 0,
    width: u32 = 800,
    height: u32 = 600,
    depth: u32 = 32,
};
// NOTE: this structure is incomplete.

// Place the header at the very beginning of the binary.
pub export const multiboot_header align(4) linksection(".multiboot") = multiboot: {
    const MAGIC  :u32= 0x1BADB002;  // Magic number for validation.
    const ALIGN  :u32= 1 << 0;      // Align loaded modules.
    const MEMINFO:u32= 1 << 1;      // Receive a memory map from the bootloader.
    const FLAGS  :u32= ALIGN | MEMINFO;  // Combine the flags.

    break :multiboot MultibootHeader {
        .magic    = MAGIC,
        .flags    = FLAGS,
        .checksum = ~(MAGIC +% FLAGS) +% 1,
    };
};
