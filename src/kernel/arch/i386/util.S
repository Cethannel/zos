
.global outb

outb:
		mov +4(%esp), %dx  // Fetch the port parameter.
		mov +8(%esp), %al   // Fetch the value parameter.
		outb %al, %dx       // Do the outb instruction.
		ret

.global inb

inb:
		mov +4(%esp), %edx  // Fetch the port parameter.
		inb %dx, %al        // Do the inb instruction.
		ret

