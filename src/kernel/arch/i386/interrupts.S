.global   irq8
.align   4
 
irq8:
    pusha
    cld
    call 	timer_handler
    popa
    iret

.global load_idt

load_idt:
    mov +4(%esp), %eax  // Fetch the gdtr parameter.
		lidt (%eax)         // Load the IDT.
		ret


.global outb

outb:
		mov +4(%esp), %edx  // Fetch the port parameter.
		mov +8(%esp), %al   // Fetch the value parameter.
		outb %al, %dx       // Do the outb instruction.
		ret

.global inb

inb:
		mov +4(%esp), %edx  // Fetch the port parameter.
		inb %dx, %al        // Do the inb instruction.
		ret
