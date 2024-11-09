ZIG_FILES := $(shell find src -name '*.zig')
ASM_FILES := $(shell find src -name '*.S')

#MKRESCUE=grub2-mkrescue
MKRESCUE=grub-mkrescue
#BOCHS=bochs-debugger
BOCHS=bochs
QEMU=qemu-system-x86_64
QEMU_FLAGS=-cdrom myos.iso -audiodev alsa,id=speaker -machine pcspk-audiodev=speaker\
  -serial stdio                                  \

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
	$(MKRESCUE) --modules="fat" -o myos.iso isodir

bochs: myos.iso
	$(BOCHS) -q

run: myos.iso
	$(QEMU) $(QEMU_FLAGS)

debug: myos.iso
	$(QEMU) $(QEMU_FLAGS) -S -s &

lldb: debug
	lldb zig-out/bin/zig-os --one-line "gdb-remote 1234"
