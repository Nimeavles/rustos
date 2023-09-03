[BITS 16]                       ; Tell the assembler that its 16 bits code
[ORG 0x7C00]                    ; Tell the assembler where the code will be in memory
                                ; after being loaded
mov si, HelloWorld              ; Load String on SI
call PrintString                ; Call the function to print
jmp $                           ; Infinite loop

PrintCharacter:                 ; Procedure to print character
  mov ah, 0x0E                  ; Tell the bios we need to print a character on the screen
  mov bh, 0x00                  ; Use the first byte of the memory   
  mov bl, 0x07                  ; Light green color with black foreground

  int 0x10                      ; Call the video interrupt

  ret                           ; Return to the calling procedure

PrintString:                    ; Procedure to print a string on the screen

next_character:                 ; Label to fetch the next character
  mov al, [si]                  ; Get a byte from the si register where the string is stored
  inc si                        ; Increment si pointer
  or al, al                     ; Check if the value on al is zero
  jz exit_function              ; If end then return
  call PrintCharacter           ; Else PrintCharacter
  jmp next_character            ; Recursive Function

exit_function:
  ret                           ; Return to the calling procedure

HelloWorld db 'Hello World', 0  ; HelloWorld string with ending in 0

TIMES 510 - ($ - $$) db 0       ; Fill the file with 510 bytes of padding
DW 0xAA55                       ; Add boot signature for the BIOS

