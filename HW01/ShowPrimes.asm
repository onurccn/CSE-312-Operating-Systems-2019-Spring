        ; 8080 assembler code
        .hexfile ShowPrimes.hex
        .binfile ShowPrimes.com
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

primeString:	dw ' is Prime',00AH,00H ; null terminated string
nonPrimeString:	dw ' is not Prime',00AH,00H ; null terminated string
INDEX: ds 2 ; Index init
LIMIT: dw 1001 ; will keep Limit

begin:
	LXI SP,stack 	; always initialize the stack pointer
	LXI D, LIMIT ; Max number 
	LHLD INDEX ; Index
	mainLoop:

	CALL PRINT_NUM

	CALL LOAD_B_PRIME_STRING
	MVI A, PRINT_STR
	CALL GTU_OS

	; Increment Index
	LHLD INDEX	; Load Index to HL
	XCHG		; Exchange with DE pair
	MVI H, 0	
	MVI L, 1	; Increment step
	DAD D		; Add DE and HL into HL
	SHLD INDEX	; Store Index
	

	; Loop condition check
	LHLD LIMIT
	XCHG
	LHLD INDEX
	MOV A, D
	SUB H
	JNZ mainLoop ; Higher bits comparison
	MOV A, E
	SUB L
	JNZ mainLoop ; Lower bits comparison
	
	hlt		; end program

; Print HL register pair values
PRINT_NUM:
	PUSH PSW
	PUSH H
	PUSH D
	
	MOV B, H
	MOV C, L
	MVI A, 100
	CALL DIV

	MOV A, B
	CPI 0
	JZ not_print_hundred
	CALL PRINT_DIGIT

	MOV A, C
	CPI 10
	JM below_ten
	JMP not_print_hundred
below_ten:
	MVI B, 0
	CALL PRINT_DIGIT

not_print_hundred:
	MOV B, C
	CALL PRINT_DIGIT

	POP D
	POP H
	POP PSW
	RET

PRINT_DIGIT:
	PUSH PSW

	MVI A, PRINT_B
	CALL GTU_OS

	POP PSW
	RET

; Load n to BC
; Directly call os with PRINT_STR in A
; Simple 6k+1 Primality test algroithm
LOAD_B_PRIME_STRING:
	PUSH PSW
	PUSH H
	PUSH D
	
	LHLD INDEX
	MOV A, H
	CPI 0
	JNZ check_div

	MOV A, L
	CPI 0
	JZ notPrime
	MOV A, L
	CPI 1
	JZ prime
	MOV A, L
	CPI 2
	JZ prime
	MOV A, L
	CPI 3
	JZ prime
	MOV A, L
	CPI 5
	JZ prime

check_div:
	; Check if n is multiplication of 2
	MOV B, H
	MOV C, L
	MVI A, 2
	CALL DIV
	MOV A, C ; A = n % 2
	CPI 0
	JZ notPrime

	; Check if n is multiplication of 3
	MOV B, H
	MOV C, L
	MVI A, 3
	CALL DIV
	MOV A, C ; A = n % 3
	CPI 0
	JZ notPrime

	; loop through other elements till n
	MVI E, 5 	; i = 5
primeLoop:
	MOV A, E 	; Load i
	CPI 100
	JP prime 	; if i < 100 continue iteration
	MOV A, H
	CPI 0
	JNZ go_on
	MOV A, E
	CMP L
	JZ prime

go_on:
	MOV B, H
	MOV C, L
	MOV A, E
	CALL DIV
	MOV A, C 	; A = n % i
	CPI 0
	JZ notPrime

	
	MOV A, E
	ADI 2
	MOV E, A
	JMP primeLoop

notPrime:
	LXI B, nonPrimeString
	JMP returnPRIME
prime: 
	LXI B, primeString

returnPRIME:
	POP D
	POP H
	POP PSW
	RET

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