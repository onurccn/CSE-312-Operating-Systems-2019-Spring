        ; 8080 assembler code
        .hexfile Collatz.hex
        .binfile Collatz.com
        ; try "hex" for downloading in hex format
        .download bin  
        .objcopy gobjcopy
        .postbuild echo "OK!"
        ;.nodump

	; OS call list
PRINT_B		equ 4
PRINT_MEM	equ 3
READ_B		equ 7
READ_MEM	equ 2
PRINT_STR	equ 1
READ_STR	equ 8
PROCESS_EXIT    equ 9

	org 000H
	jmp begin

	; Start of our Operating System
GTU_OS:	PUSH D
	push D
	push H
	push psw
	nop	; This is where we run our OS in C++, see the CPU8080::isSystemCall()
		; function for the detail.
	pop psw
	pop h
	pop d
	pop D
	ret
	; ---------------------------------------------------------------
	; YOU SHOULD NOT CHANGE ANYTHING ABOVE THIS LINE        


limit:	ds 1
iteration: ds 1
prettyPrint: dw ': ', 00H
seperator: dw ' ', 00H
endLine: dw 00AH

begin:
    MVI A, 24
    STA limit

outerLoop:
    LDA limit
    CPI 1
    JZ finish
    MOV D, A
    MOV B, A
    MVI A, PRINT_B
    CALL GTU_OS

    LXI B, prettyPrint
    MVI A, PRINT_STR
    CALL GTU_OS
    MOV A, D
innerLoop:
    CALL MOD2
    MOV D, A        ; Save current iteration to D
    MOV A, B
    CPI 0
    JNZ odd

    MOV A, D
    RRC
    MOV D, A
    jmp print

odd:
    MOV A, D
    ADD D       
    ADD D           
    ADI 1
    MOV D, A

print:
    MOV B, A
    MVI A, PRINT_B
    CALL GTU_OS

    MOV A, B
    CPI 1
    JZ nextNumber

    LXI B, seperator
    MVI A, PRINT_STR
    CALL GTU_OS

    MOV A, D
    jmp innerLoop

nextNumber:
    LXI B, endLine
    MVI A, PRINT_STR
    CALL GTU_OS

    LDA limit
    SBI 1
    STA limit
    jmp outerLoop

finish:
	MVI A, PROCESS_EXIT
	CALL GTU_OS		; end program

; store value to the A reg
; Return 1 if odd or 0 in B reg
MOD2:
    PUSH psw

    ANI 1
    MOV B, A
    
    POP psw
    ret
