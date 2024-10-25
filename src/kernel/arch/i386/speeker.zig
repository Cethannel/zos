const x86 = @import("x86.zig");

fn play_sound(nFrequence: u32) void {
    var Div: u32 = 0;
    var tmp: u8 = 0;

    //Set the PIT to the desired frequency
    Div = 1193180 / nFrequence;
    x86.outb(0x43, 0xb6);
    x86.outb(0x42, @truncate(Div));
    x86.outb(0x42, @truncate(Div >> 8));

    //And play the sound using the PC speaker
    tmp = x86.inb(0x61);
    if (tmp != (tmp | 3)) {
        x86.outb(0x61, tmp | 3);
    }
}

fn nosound() void {
    const tmp: u8 = x86.inb(0x61) & 0xFC;

    x86.outb(0x61, tmp);
}

pub fn beep() void {
    play_sound(1000);
    nosound();
}
