/* Link.ld -- Linker script for the kernel - ensure everything goes in the */
/*            Correct place.  */
/*            Original file taken from Bran's Kernel Development */
/*            tutorials: http://www.osdever.net/bkerndev/index.php. */

ENTRY(_start)
SECTIONS
{
    . = 0x00100000;

    .multiboot ALIGN(4K): {
        KEEP(*(.multiboot))
        *(.boot)
    }

    .note.gnu.build-id ALIGN(4K): {
        *(.note.gnu.build-id)
    }

    . += 0xC0000000;

    _kernel_start = .;

	/* Add a symbol that indicates the start address of the kernel. */
	.text ALIGN (4K) : AT (ADDR (.text) - 0xC0000000)
	{
		*(.text)
	}
	.rodata ALIGN (4K) : AT (ADDR (.rodata) - 0xC0000000)
	{
		*(.rodata)
	}
	.data ALIGN (4K) : AT (ADDR (.data) - 0xC0000000)
	{
		*(.data)
	}
	.bss ALIGN (4K) : AT (ADDR (.bss) - 0xC0000000)
	{
		*(COMMON)
		*(.bss)
		        __bss_end = .;
        __debug_info_start = .;
        __debug_info_end = .;
        __debug_abbrev_start = .;
        __debug_abbrev_end = .;
        __debug_str_start = .;
        __debug_str_end = .;
        __debug_line_start = .;
        __debug_line_end = .;
        __debug_ranges_start = .;
        __debug_ranges_end = .;
	}

    _kernel_end = .;
}
