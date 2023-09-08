use16
org 0x7c00

; Número de Sectores = Tamaño del Kernel / Tamaño del Sector

cli
xor ax, ax
mov ds, ax
mov es, ax
mov ss, ax
mov sp, 0x7000
sti

mov ah, 00h
int 0x13
mov al, dl
and al, 0x80

jz err_reset_disk

push bx

mov ah, 0x41
mov bx, 0x55aa
mov dl, 0x80
int 0x13

jc not_supported_lba

pop bx

mov si, welcome
call print

DAPACK:
	db 0x10
	db 0
blkcnt:	dw 1					; int 13 resets this to # of blocks actually read/written
db_add:	dw 0x1000			; memory buffer destination address (0:7c00)
	dw 0								; in memory page zero
d_lba: dd	1						; put the lba to read in this spot
	dd 0

mov si, DAPACK		; address of "disk address packet"
mov ah, 0x42		; AL is unused
mov dl, 0x80		; drive number 0 (OR the drive # with 0x80)

int 0x13
jc short error

; Read the root directory sector into memory (adjust for FAT16/FAT32)
mov ah, 0x02        ; Read sector function
mov al, 0x01        ; Number of sectors to read (1 sector)
mov ch, 0x00        ; Cylinder (adjust as needed)
mov cl, 1           ; Sector (use BX as sector number)
mov dh, 0x00        ; Head (adjust as needed)
mov dl, 0x80        ; Drive number (adjust as needed)
mov bx, 0x8200      ; Memory location to load the root directory

int 0x13            ; Call BIOS interrupt 0x13 to read

jc error            ; Handle read errors if necessary

; Now, you can search the root directory entries for the second-stage loader
; Parsing the directory entries and finding the loader is a complex task
; You need to look for a specific filename or marker to identify the loader

; If found, load the second-stage loader into memory and jump to it

success:
mov si, disk_read_ok
call print
jmp 0x8000:0x0000   ; Jump to the second-stage loader

 
error:
	mov si, disk_read_err
	call print
	jmp $

not_supported_lba:
  mov si, lba_ns_err
  call print
  ; Use CHS

err_reset_disk:
  mov si, disk_not_reseted
  call print



print:

.loop:
  lodsb              ; Load byte at address SI to AL
  or al, al          ; Test AL
  jz .done           ; If AL is zero, end of string
  mov ah, 0x0e       ; BIOS teletype output
  int 0x10           ; BIOS interrupt
  jmp .loop          ; Repeat for next character
.done:
  ret

lba_ns_err db "LBA not supported", 0
disk_not_reseted db " Disk not reseted", 0
disk_read_err db " Error Reading the disk", 0
disk_read_ok db " Disk read ok", 0
welcome db "Loading Os ...", 0

times 510 - ($ - $$) db 0
dw 0xaa55