        ; 8080 assembler code
        .hexfile test.hex
        .binfile test.com
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
LOAD_EXEC   equ 5
SET_QUANTUM equ 6
PROCESS_EXIT    equ 9

	; Position for stack pointer
stack   equ 0FF00h
memory	equ 00200h
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


INTBUFFER: ds 27 ; Buffer is needed in order to be in rst5 location.
INTERRUPT5:
    DI ; Disable Interrupts during interrupt handling
    ;CALL SCHEDULER

	
    EI ; Enable Interrupts on the way out
	ret

prog1: dw 'Factorize.com', 00H
initName: dw 'init', 00H
currentProcessID: db 00H	; init process id
lastProcessID: db 00H
totalProcessCount: db 00H

;; Need to make context switching here according to process table
SCHEDULER:
    LXI H, memory + 110
	MVI D, 0
	MVI C, 109

	DAD D
	XCHG
	MVI H, 1
	MVI L, 9
	MOV C, M
	INX H
	MOV B, M
	MOV H, B
	MOV L, C
	EI
	PCHL 
    ret

begin:
	DI
	LXI SP,stack 	; always initialize the stack pointer
	CALL initProcessTable
    LXI B, prog1 
	CALL loadProgramIntoMemory
	
	LXI H, memory + 110
	MVI D, 0
	MVI C, 109

	DAD D
	XCHG
	MVI L, 0
	PCHL 

    hlt

loadProgramIntoMemory:
	DI
	push psw
	push H
	push D
	push B
	
	MVI D, 0
	MVI E, 0
	LXI H, memory + 110 ; init process offset
try_next:

	MOV A, M
	CPI 0
	JNZ load_next
	DCX H
	MOV A, M
	CPI 0

	JNZ load_next
	JMP load_here

load_next:		;; Load next entries lower byte address into HL
	MOV D, M
	INX H
	MOV E, M
	DAD D
	INX H		; set cursor to lower byte

	JMP try_next

load_here:
	MVI B, 4
	MVI C, 0
	MOV D, H
	MOV E, L
	DAD B
	XCHG
	MOV M, D	; next process location is entry + 1024 (entry + 0)
	INX H
	MOV M, E
	INX H

	LDA lastProcessID
	INR A
	STA lastProcessID
	MOV M, A	; process id (entry + 2)
	INX H
	MVI M, 0	; program counter higher byte (entry + 3)
	INX H
	MVI M, 0	; program counter lower byte (entry + 4)
	
	INX H
	pop B
	push B
	CALL copyNameIntoProcessTable	; program name (entry + 5)
	DCX H
	MVI B, 0
	MVI C, 100	; max 100 char supported for name
	DAD B		; entry + 105
	MOV D, H
	MOV E, L
	MVI C, 4
	DAD B
	XCHG
	MOV M, D
	INX H
	MOV M, E	; store entry + 109 into base reg address entry (entry + 105 & 106) 
	INX H
	MOV D, H
	MOV E, L
	MVI B, 2
	MVI C, 95H
	DAD B
	XCHG		; DE pair has value of entry + 768 for stack pointer address
	MOV M, D	; stack pointer high (entry + 107)
	INX H		
	MOV M, E	; stack pointer low (entry + 108)
	
	INX H
	pop B
	push B
	MVI A, LOAD_EXEC
	CALL GTU_OS	; load program content into memory here
	
	MVI D, 3
	MVI E, 93H
	DAD D
	MVI M, 0	; next pointer address high set to 0
	INX H
	MVI M, 0	; next pointer address low set to 0
	
	pop B
	pop D
	pop H
	pop psw
	EI
	ret

;; Load string to BC pair and mem location to write to HL register
copyNameIntoProcessTable:
	push psw
	push B
	push H
	
	load_name:
	MVI M, 0	; init current character
	LDAX B		
	CPI 0
	JZ load_name_done

	MOV M, A
	INX B
	INX H
	JMP load_name 
	
	load_name_done:
	pop H
	pop B
	pop psw
	ret

;; Initialize process table with init as first entry (program content isn't in the table since its the first thing loaded into memory)
initProcessTable:
	DI
	push psw
	push H
	push D
	
	LXI H, memory ; memory starting address
	MVI D, 0	; 4 	default value
	MVI E, 110	; 0		default value as it represents 1024 with its higher byte combined
	DAD D		; next process table entry location is (entry + 110)
	XCHG
	LXI H, memory
	MOV M, D	; next process location higher byte (entry + 0)
	INX H
	MOV M, E	; next process locationg lower byte (entry + 1)
	INX H	; increase mem pos
	MVI M, 0	; process id (entry + 2)
	INX H
	MVI M, 0	; program counter higher byte (entry + 3)
	INX H
	MVI M, 0	; program counter lower byte (entry + 4)

; load program name into mem location (entry + 5)
	INX H
	LXI B, initName
	CALL copyNameIntoProcessTable
	DCX H
	MVI D, 0
	MVI E, 100	; max 100 char supported for name
	DAD D
	MVI M, 0	; memory base register address higher byte (entry + 105)
	INX H
	MVI M, 0	; memory base reg address lower byte (entry + 106)
	
	INX H
	XCHG
	MVI H, 0
	MVI L, 0
	DAD SP
	XCHG
	MOV M, D	; stack pointer address higher byte (entry + 107)
	INX H
	MOV M, E	; stack pointer address lower byte (entry + 108)

	INX H
	MVI M, 0	; program content (entry + 109) has space until address offset 1024
	
	; set next entries next entry to 0
	LXI H, memory + 110
	MVI M, 0
	INX H
	MVI M, 0

	pop D
	pop H
	pop psw
	EI
	ret




