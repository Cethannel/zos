////
// Load a new Interrupt Descriptor Table.
//
// Arguments:
//     idtr: Address of the IDTR register.
//
pub inline fn lidt(idtr: usize) void {
    asm volatile ("lidt (%[idtr])"
        :
        : [idtr] "r" (idtr),
    );
}
