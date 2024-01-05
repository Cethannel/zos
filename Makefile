zig-out/bin/zig-os: src/*.zig
	zig build

isodir/boot/myos.bin: zig-out/bin/zig-os
	cp zig-out/bin/zig-os isodir/boot/myos.bin

myos.iso: isodir/boot/myos.bin
	grub-mkrescue -o myos.iso isodir

run: myos.iso
	qemu-system-x86_64 -cdrom myos.iso
