.global gdt_flush
gdt_flush:
		mov +4(%esp), %eax
		lgdt (%eax)

		mov $0x10, %eax
		mov %ax, %ds
		mov %ax, %es
		mov %ax, %fs
		mov %ax, %gs
		mov %ax, %ss
		jmp $0x08, $.flush

.flush:
		ret

.global tss_flush
tss_flush:
        mov $0x2B, %ax
        ltr %ax
        ret
