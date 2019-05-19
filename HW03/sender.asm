        ; 8080 assembler code
        .hexfile sender.hex
        .binfile sender.com
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
RAND_INT    equ 12
WAIT        equ 13
SIGNAL      equ 14

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

	;This program adds numbers from 0 to 10. The result is stored at variable
	; sum. The results is also printed on the screen.

begin:
	mvi H, 17h
	mvi L, 92h
	mvi M, 1	; Initialize mutex for mailbox 1.
	mvi L, 93h
	mvi M, 0	; Initialize full semaphore for mailbox 1.
	mvi L, 94h
	mvi M, 50	; Initialize empty semaphore for mailbox 1.

    mvi H, 1
	mvi L, 91h
	mvi D, 0FFh
	mvi E, 0FFh
loop:
	MVI A, RAND_INT
	CALL GTU_OS		; Reg B has random number
	push D
	push H
	push B


	MVI A, WAIT
	MVI B, 1
	MVI C, 0		
	CALL GTU_OS		; Hold mutex lock in order to put random number in mailbox 1. enter critical region

	MVI C, 2		
	CALL GTU_OS		; Check if mailbox has empty slot

	mvi H, 17h
	mvi L, 93h
	mov E, M	; empty slot index
	mvi L, 95h	

	mvi D, 0
	dad D		; empty slot address
	pop B
	mov m, b

	mvi A, SIGNAL
	mvi B, 1
	mvi C, 1
	CALL GTU_OS		; Signal full semaphore
	mvi C, 0
	CALL GTU_OS		; Lift mutex lock	leave critical region


	pop H
	pop D
	DAD D
	MOV A, L
	SBI	0
	JNZ loop
	MOV A, H
	SBI 0
	JNZ loop


	MVI A, PROCESS_EXIT
	CALL GTU_OS		; end program