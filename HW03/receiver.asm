        ; 8080 assembler code
        .hexfile receiver.hex
        .binfile receiver.com
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

array	ds 400 ; will keep the array
index 	ds 2

begin:

	mvi a, 0
	sta index
	sta index + 1

loop:
	MVI A, WAIT
	MVI B, 1
	MVI C, 1		
	CALL GTU_OS		; Check if mailbox has an entry

	MVI C, 0		
	CALL GTU_OS		; Hold mutex lock in order to put random number in mailbox 1. enter critical region

	mvi H, 13h
	mvi L, 93h
	mov E, M	; empty slot index
	mvi L, 95h	

	mvi D, 0
	dad D		; Last full slot address

	mov D, m

	mvi A, SIGNAL
	mvi B, 1
	mvi C, 0
	CALL GTU_OS		; Lift mutex lock	leave critical region
	mvi C, 2
	CALL GTU_OS		; Signal empty semaphore

	; calculate local list index
	lda index
	mov b, a
	lda index + 1
	mov c, a
	lxi h, array
	dad b

	mov m, d

	mvi h, 0
	mvi l, 1
	dad b

	mov a, h
	sta index
	mov a, l
	sta index + 1

	jmp loop
	
	MVI A, PROCESS_EXIT
	CALL GTU_OS		; end program
