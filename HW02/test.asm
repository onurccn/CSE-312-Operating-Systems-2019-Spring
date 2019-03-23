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
stack   equ 0F000h
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

	JMP SCHEDULER
	
	ret

prog1: dw 'ShowPrimes.com', 00H
initName: dw 'init', 00H
currentProcessID: db 00H	; init process id
lastProcessID: db 00H

;; Need to make context switching here according to process table
SCHEDULER:
	LDA currentProcessID
	CPI 0
	JNZ restoreProg
	
	MVI H, 0FFH
	MVI L, 7
	MOV E, M
	INX H
	MOV D, M
	SHLD memory + 107
	
	LXI H, memory + 1024 + 107
	MOV D, M
	INX H
	MOV	E, M
	XCHG
	SPHL 

	LXI D, memory + 1024 + 109
	MVI H, 0
	MVI L, 0
	INR A
	STA currentProcessID

	

	EI
	PCHL	

restoreProg:
	; Restore program stack pointer
	MVI H, 0FFH
	MVI L, 7
	MOV C, M
	INX H
	MOV B, M
	MOV H, B
	MOV L, C
	SPHL

	;; push D and H pairs into the stack
	LDA 0FF03H
	MOV D, A
	LDA 0FF04H
	MOV E, A
	PUSH D
	LDA 0FF05H
	MOV H, A
	LDA 0FF06H
	MOV L, A
	PUSH H

	; Restore base register
	MVI H, 0FFH
	MVI L, 11
	MOV E, M
	INX H
	MOV D, M
	
	

	; Restore pc counter
	MVI L, 9
	MOV C, M
	INX H
	MOV B, M
	MOV H, B
	MOV L, C

	LDA 0FF01H
	MOV B, A
	LDA 0FF02H
	MOV C, A
	LDA 0FF00H
	EI		; Enable Interrupts on the way out
	PCHL

begin:
	DI
	LXI SP,stack 	; always initialize the stack pointer
	CALL initProcessTable
    LXI B, prog1
	CALL loadProgramIntoMemory

    hlt

; Empty next process pointer
initProcessTable:
	push H
	push D

	LXI D, memory
	MVI H, 4
	MVI L, 0
	DAD D
	XCHG
	MOV M, D
	INX H
	MOV M, E
	LXI D, memory + 107
	XTHL
	XCHG
	MOV M, E
	INX H
	MOV M, D
	pop D
	pop H
	ret

loadProgramIntoMemory:
	DI
	push psw
	push H
	push D
	push B
	
	MVI D, 0
	MVI E, 0
	LXI H, memory

try_next:
	MOV D, H
	MOV E, L
	MOV A, M
	CPI 0
	JNZ load_next
	INX H
	MOV A, M
	CPI 0

	JNZ load_next
	JMP load_here

load_next:		;; Load next entries lower byte address into HL
	XCHG
	MOV D, M
	INX H
	MOV E, M
	XCHG

	JMP try_next

load_here:
	MVI B, 4
	MVI C, 0
	MOV H, D
	MOV L, E
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
	MOV D, H
	MOV E, L
	
	MVI B, 3
	MVI C, 93H
	DAD B
	MVI M, 0	; next pointer address high set to 0
	INX H
	MVI M, 0	; next pointer address low set to 0



	XCHG
	pop B
	push B
	MVI A, LOAD_EXEC
	CALL GTU_OS	; load program content into memory here
	
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
