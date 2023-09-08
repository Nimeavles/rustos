use16                           

mov si, welcome
call print

; PCI
mov ax, 0x5 
int 1ah
  
; If equal, PCI Exists
cmp al, 00h 
jne pci_error_detect 

;;;;;;;;;;;;;;;CPUID 32 Bits mode;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;MSRs 64 Bits mode;;;;;;;;;;;;;;;

;call enable_a20

;Infinite loop to halt the CPU
jmp $


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;A20 Gate;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_a20_state:
	pushf
	push si
	push di
	push ds
	push es
	cli
 
	mov ax, 0x0000					;	0x0000:0x0500(0x00000500) -> ds:si
	mov ds, ax
	mov si, 0x0500
 
	not ax							;	0xffff:0x0510(0x00100500) -> es:di
	mov es, ax
	mov di, 0x0510
 
	mov al, [ds:si]					;	save old values
	mov byte [.BufferBelowMB], al
	mov al, [es:di]
	mov byte [.BufferOverMB], al
 
	mov ah, 1						;	check byte [0x00100500] == byte [0x0500]
	mov byte [ds:si], 0
	mov byte [es:di], 1
	mov al, [ds:si]
	cmp al, [es:di]
	jne .exit
	dec ah
.exit:
	mov al, [.BufferBelowMB]
	mov [ds:si], al
	mov al, [.BufferOverMB]
	mov [es:di], al
	shr ax, 8
	sti
	pop es
	pop ds
	pop di
	pop si
	popf
	ret
 
	.BufferBelowMB:	db 0
	.BufferOverMB	db 0

;	out:
;		ax - a20 support bits (bit #0 - supported on keyboard controller
;        bit #1 - supported with bit #1 of port 0x92)
;		cf - set on error

query_a20_support:
	push bx
	clc
 
	mov ax, 0x2403
	int 0x15
	jc .error
 
	test ah, ah
	jnz .error
 
	mov ax, bx
	pop bx
	ret

.error:
	stc
	pop bx
  mov si, a20_not_supported
  call print
  ret

enable_a20:
  ;	clear cf
  clc									
	pusha

  ;	clear bh
	mov bh, 0							
 
	call get_a20_state
	jc .fast_gate
 
	test ax, ax
	jnz .done
 
	call query_a20_support
	mov bl, al

  ;	enable A20 using fast A20 gate
	test bl, 2							
	jnz .fast_gate

.bios_int:
	mov ax, 0x2401
	int 0x15
	jc .fast_gate
	test ah, ah
	jnz .failed
	call get_a20_state
	test ax, ax
	jnz .done

.fast_gate:
	in al, 0x92
	test al, 2
	jnz .done
 
	or al, 2
	and al, 0xfe
	out 0x92, al
 
	call get_a20_state
	test ax, ax
	jnz .done
 
.failed:
	stc
  mov si, a20_not_enabled
  call print

.done:
	popa
  mov si, a20_enabled_ok
  call print
	ret

pci_error_detect:
  ; If equal PCI doesn't Exist
  cmp al, 80h
  mov si, pci_not_present
  je print
  
  ; If Equal PCI isn't implemented
  cmp al, 81h
  mov si, unimplemented_pci
  je print

; Function to print a message
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

; Error messages
pci_not_present db " Service corresponding to PCI is not present", 0
unimplemented_pci db " Unimplemented function for BIOS PCI", 0

a20_not_enabled db " A20 gate isn't enabled", 0
a20_enabled db " A20 gate is enabled", 0
a20_failed_err db " A20 gate failed when trying to activete it", 0
a20_not_supported db " Int 15h interrupt is not supported for your BIOS", 0
a20_enabled_ok db " A20 gate is enabled successfully", 0

welcome db "  Welcome to the sencond stage!  ", 0
