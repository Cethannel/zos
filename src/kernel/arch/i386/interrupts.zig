const InterruptDescriptor32 = struct {
    offset_1: u16, // offset bits 0..15
    selector: u16, // a code segment selector in GDT or LDT
    zero: u8, // unused, set to 0
    type_attributes: u8, // gate type, dpl, and p fields
    offset_2: u16, // offset bits 16..31
};
