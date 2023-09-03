MAKEFLAGS += --silent

bootloader: src/bootloader/bootloader.asm
	mkdir -p build
	nasm src/bootloader/bootloader.asm -f bin -o build/boot.bin

run: build/boot.bin
	qemu-system-x86_64 build/boot.bin
