        ; 8080 assembler code
        .hexfile Palindrome.hex
        .binfile Palindrome.com
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

PALINDROME: dw ': Palindrome', 00AH, 00H
NOTPALINDROME: dw ': Not Palindrome', 00AH, 00H
STRING: ds 100 ; Reserve 100 characters for input string.
DIVRESULT: ds 1 ;
endl: dw 00AH

begin:
	LXI SP,stack 	; always initialize the stack pointer
    
    LXI B, STRING   ; Load input string into STRING address
    MVI A, READ_STR 
	CALL GTU_OS ; Read input number to B

    LXI D, STRING ; String index
    MVI H, 0

    mainLoop:
    LDAX D ; Load char into A
    SUI 0 ; Check if its null
    JZ endMainLoop ; Finish loop if its terminated
    
    INR H ; Increase string length
    INX D ; Increse string index
    JMP mainLoop
    endMainLoop:

    MOV A, H
    SUI 0
    JZ halt ; halt if string length is 0

    MOV B, H ; B is division result
    MVI C, 2
    CALL DIV
    MOV A, B
    STA DIVRESULT

    DCX D ; Last char address
    LXI H, STRING ; First char address

    LXI B, STRING   ; Print given string
    MVI A, PRINT_STR 
	CALL GTU_OS

palindromeLoop:
    MOV B, M ; LOAD Left char into B
    LDAX D ; LOAD  Rigth char into A
    
    SUB B ; Sets zero flag to 1 if left and rigth is same

    JNZ nonPalindrome

    INX H ; Increase left char index
    DCX D ; Decrease right char index

    LDA DIVRESULT ; Load Division result into A
    DCR A ; decrease it by one to iterate over string
    STA DIVRESULT ; Save new index into DIVRESULT
    
    SUI 0 ; check if its zero
    JNZ palindromeLoop 

    LXI B, PALINDROME   ; Print palindrome
    MVI A, PRINT_STR 
	CALL GTU_OS
    JMP halt

nonPalindrome:
    LXI B, NOTPALINDROME   ; Print non palindrome
    MVI A, PRINT_STR 
	CALL GTU_OS

halt:
    hlt		; end program

; Division for 1 byte values.
; B / C -> B Result, C Remainder
DIV:
    PUSH H
    PUSH D
    PUSH PSW

    MOV A, B
    MVI D, 0
    loop:
    INR D
    SUB C

    JZ zero
    JP loop

    DCR D ; Decrease if negative

    zero:
    MOV B, D ; Result
    MOV C, A ; Remainder
    POP PSW
    POP D
    POP H
    RET