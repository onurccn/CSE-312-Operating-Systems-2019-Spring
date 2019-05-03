        ; 8080 assembler code
        .hexfile MicroKernel1.hex
        .binfile MicroKernel1.com
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
memory	equ 00400h
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

initName: dw 'init', 00H
currentProcessID: db 00H	; init process id
currentProcessEntry: ds 2
lastProcessID: db 00H
processCount: ds 1
nextProcessEntry: ds 2
randomNumber: ds 1
endLine: dw 00AH
seperator: dw ' | ', 00H
ProcessInfoLine: dw 'Next | ID | PC | BaseReg | Stack Pointer | State | Name', 00AH, 00H
prog1: dw 'sender.com', 00H
prog2: dw 'receiver.com', 00H
processTablePrinterIndex: ds 1

;; Need to make context switching here according to process table
;; First store everything to current stack
;; Then pick which process to run
;; Restore new process stack if its not first run of next process
SCHEDULER:
	;;; Save everything to stack and process table
	INX SP
	INX SP
	push D		; These will be popped by PCHL 
	push H		; These will be popped by PCHL 
	push psw	; This (condition flags) isn't saved during interrupt so push it to current stack asap
	push B
	
	CALL printProcessTable
	
	LHLD nextProcessEntry
	MOV A, H
	CPI 0
	JZ save_current_process
	MVI D, 0
	MVI E, 0
	XCHG
	SHLD nextProcessEntry
	XCHG
	jmp restoreProgram


save_current_process:
	LHLD currentProcessEntry
	
	MVI D, 0
	MVI E, 3
	DAD D
	LDA 266		; PC High
	MOV M, A
	INX	H
	LDA 265		; PC Low
	MOV M, A	; Save PC
	
	MVI E, 103
	DAD D
	XCHG 
	LDA 264
	MOV H, A
	LDA 263
	MOV L, A
	MVI B, 0FFH
	MVI C, 0F8H
	DAD B
	XCHG
	MOV M, D	
	INX H
	MOV M, E	; Save program stack pointer (check high - low order)

	INX H
	MVI M, 0 	; Set program state to 0: Ready.

	;;; Restore next process in process table
	LHLD currentProcessEntry
	MOV D, M
	INX H
	MOV E, M
	XCHG

	MOV A, M		; No need to check Low its always 0 since we use 200 and its multiplications
	CPI 0
	JZ revertHead	; There is no next, load first program in process table
	JMP restoreProgram
revertHead:
	LXI H, memory
	jmp restoreProgram
	
	org 110h
restoreProgram:
	SHLD currentProcessEntry	; Save next location
	MVI D, 0
	MVI E, 2
	DAD D
	MOV A, M
	STA currentProcessID

	MVI E, 107
	DAD D
	MVI M, 1					; Set status as Running
	
	LHLD currentProcessEntry
	MVI D, 0
	MVI E, 107
	DAD D
	MOV D, M
	INX H
	MOV	E, M
	XCHG
	SPHL 						; Restore next process' stack pointer

	LHLD currentProcessEntry 	; Get next process entry base address
	MVI D, 0
	MVI E, 105 
	DAD D
	MOV D, M
	INX H
	MOV E, M					; Store DE = base reg address for PCHL	

	LHLD currentProcessEntry
	MVI B, 0
	MVI C, 3
	DAD	B
	MOV B, M
	INX	H
	MOV C, M 					
	MOV H, B
	MOV L, C						; Store HL = PC for PCHL
	MOV A, L
	CPI 0
	JNZ process_continue
	MOV A, H
	CPI 0
	JNZ process_continue

;; First start of the process, just push HL and DE regs
	push D
	push H
	jmp start

process_continue:	
	pop B
	pop psw

start:
	EI
	PCHL	
	
	;;; END OF SCHEDULER
printProcessTable:
	PUSH H
	PUSH D
	PUSH PSW
	
	MVI A, PRINT_STR
	LXI B, ProcessInfoLine
	CALL GTU_OS

	LXI H, memory
printEntry:
	MOV A, H
	STA processTablePrinterIndex	; Save high process table entry head

	MOV D, M
	INX H
	MOV E, M
	XCHG
	CALL PRINT_NUM
	XCHG

	LXI B, seperator
	MVI A, PRINT_STR
	CALL GTU_OS			;;	SEPERATOR

	INX H
	MOV B, M
	MVI A, PRINT_B
	CALL GTU_OS			; Printd process ID
	
	LXI B, seperator
	MVI A, PRINT_STR
	CALL GTU_OS			;;	SEPERATOR

	INX H
	MOV D, M
	INX H
	MOV E, M
	XCHG
	CALL PRINT_NUM		; Print PC
	XCHG

	LXI B, seperator
	MVI A, PRINT_STR
	CALL GTU_OS			;;	SEPERATOR

	MVI B, 0
	MVI C, 101
	DAD B

	MOV D, M
	INX H
	MOV E, M
	XCHG
	CALL PRINT_NUM			; Print Base Reg
	XCHG

	LXI B, seperator
	MVI A, PRINT_STR
	CALL GTU_OS			;;	SEPERATOR

	INX H
	MOV D, M
	INX H
	MOV E, M
	XCHG
	CALL PRINT_NUM			; Print Stack Pointer
	XCHG

	LXI B, seperator
	MVI A, PRINT_STR
	CALL GTU_OS			;;	SEPERATOR

	INX H
	MOV B, M
	MVI A, PRINT_B
	CALL GTU_OS			; Print State

	LXI B, seperator
	MVI A, PRINT_STR
	CALL GTU_OS			;;	SEPERATOR

	MVI B, 0FFh
	MVI C, 098H
	DAD B
	MOV B, H
	MOV C, L
	MVI A, PRINT_STR
	CALL GTU_OS			; Print name

	LXI B, endLine
	CALL GTU_OS			; Print End line

	LDA processTablePrinterIndex
	MOV H, A
	MVI L, 0

	MOV D, M
	INX H
	MOV E, M
	XCHG
	MOV A, M
	CPI 0
	JZ finishPrint
	jmp printEntry
finishPrint:
	POP psw
	pop h
	pop d
	ret 

begin:
	DI
	LXI SP,stack 	; always initialize the stack pointer
	CALL initProcessTable

    LXI B, prog1
	CALL loadProgramIntoMemory
    LXI B, prog2
	CALL loadProgramIntoMemory
    
stop:
	LDA processCount
	CPI 0
	JNZ stop
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

	LXI B, initName
	LXI H, memory + 5
	CALL copyNameIntoProcessTable	; program name (entry + 5)

	MVI A, 0
	STA memory + 105
	STA memory + 106

	MVI A, 1
	STA memory + 109
	LXI H, memory
	SHLD currentProcessEntry
	
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
	MVI C, 5
	DAD B
	XCHG
	MOV M, D
	INX H
	MOV M, E	; store entry + 110 into base reg address entry (entry + 105 & 106) 
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
	MVI M, 0	; Program status 0: ready, 1: running, 2: blocked
	
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