MAKEFLAGS += --silent

bootloader: src/bootloader/stage1.asm src/bootloader/bootloader.asm
	mkdir -p build
	nasm src/bootloader/stage1.asm -f bin -o build/stage1.bin
	nasm src/bootloader/bootloader.asm -f bin -o build/bootloader.bin

run: iso build/stage1.bin
	qemu-system-x86_64 build/boot.iso

iso: build/stage1.bin build/bootloader.bin  
	dd if=/dev/zero of=build/boot.iso bs=512 count=2880
	mkfs.fat -F 12 -n "RUSTOS" build/boot.iso
	dd if=build/stage1.bin of=build/boot.iso conv=notrunc bs=512 count=1
	dd if=build/bootloader.bin of=build/boot.iso bs=512 seek=1 conv=notrunc
