zig-out/bin/zig-os: src/*.zig
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

run: myos.iso
	qemu-system-x86_64 -cdrom myos.iso
