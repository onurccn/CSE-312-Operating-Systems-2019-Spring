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