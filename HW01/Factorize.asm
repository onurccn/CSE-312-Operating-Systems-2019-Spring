        ; 8080 assembler code
        .hexfile Factorize.hex
        .binfile Factorize.com
        ; try "hex" for downloading in hex format
        .download bin  
        .objcopy gobjcopy
        .postbuild echo "OK!"
        ;.nodump

	; OS call list
PRINT_B		equ 1
PRINT_MEM	equ 2
READ_B		equ 3
READ_MEM	equ 4
PRINT_STR	equ 5
READ_STR	equ 6

	; Position for stack pointer
stack   equ 0F000h

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

	;This program prints a null terminated string to the screen
seperator: dw ',', 00H ; Seperator for values
endl: dw 00AH

begin:
	LXI SP,stack 	; always initialize the stack pointer
    MVI A, READ_B 
	CALL GTU_OS ; Read input number to B
    MOV L, B ; Store B to L
    MVI D, 0 ; Start trying factors from 1 
    mainLoop:
    INR D

    MVI B, 0
    MOV C, L
    MOV A, D
    CALL DIV

    MOV A, C
    SUI 0
    JNZ ENDIF

    MOV B, D
    MVI A, PRINT_B
    CALL GTU_OS

    MOV A, L
    SUB D
    JZ ENDIF

    LXI B, seperator
    MVI A, PRINT_STR
    CALL GTU_OS

    ENDIF:
	
	MOV A, L
	SUB D
	JNZ mainLoop 

	LXI B, endl
    MVI A, PRINT_STR
    CALL GTU_OS
	
    hlt		; end program


; BC/A
DIV:
    PUSH H
    PUSH D
    PUSH PSW

    MOV D, A

	MOV H, B
	MOV L, C

    MVI E, 0
loop:
	MOV A, C
    INR E
    SUB D
    MOV C, A
    MOV A, B
    SBI 0
    MOV B, A

    JZ zero ; check lower byte
    JM finish_div_loop
    JMP loop

finish_div_loop:
    DCR E ; Decrease if negative
    MOV A, C
    ADD D
    JMP finish_div  ; Jump lower byte check

zero:
    MOV A, C
    CPI 0
    JNZ loop
    
finish_div:
    MOV B, E ; Result
    MOV C, A ; Remainder
    POP PSW
    POP D
    POP H
    RET