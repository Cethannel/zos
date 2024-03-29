ZIG_FILES := $(shell find src -name '*.zig')
ASM_FILES := $(shell find src -name '*.S')

zig-out/bin/zig-os: $(ZIG_FILES) $(ASM_FILES)
	zig build

isodir/boot:
	mkdir -p isodir/boot

isodir/boot/grub:
	mkdir -p isodir/boot/grub

isodir/boot/grub/grub.cfg: isodir/boot/grub
	cp grub.cfg isodir/boot/grub

isodir/boot/myos.bin: zig-out/bin/zig-os isodir/boot
	cp zig-out/bin/zig-os isodir/boot/myos.bin

myos.iso: isodir/boot/myos.bin isodir/boot/grub/grub.cfg
	grub-mkrescue -o myos.iso isodir

bochs: myos.iso
	bochs -f bochs -q

run: myos.iso
	qemu-system-x86_64 -cdrom myos.iso
