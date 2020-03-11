$mod52

ORG 0h
BEGIN_AGAIN:
	MOV DPTR, #DATA_ARRAY
	ACALL MEAN_TEN_FUNC
	MOV R0, A
	MOV A, #00h
	MOV DPTR,  #QMAX
	MOVC A, @A + DPTR
	CLR C
	SUBB A, R0
	JNC NOT_BIGGEST
	MOV P1, #03h
	JMP BEGIN_AGAIN
NOT_BIGGEST:
	MOV A, #00h
	MOV DPTR,  #QMIN
	MOVC A, @A + DPTR
	CLR C
	SUBB A, R0
	JC NOT_LOWEST
	MOV P1, #00h
	JMP BEGIN_AGAIN
NOT_LOWEST:
	MOV P1, #01h
	JMP BEGIN_AGAIN

MEAN_TEN_FUNC:
	; input: 
	;	R0 - Data Pointer
	; Warning - R0 will be shifted by 10
	; output:
	;	result in ACC
	;
	MOV R1, #00h
	MOV R2, #00h
	MOV R3, #0Ah
MEAN_LOOP:
	MOV A, #00h
	MOVC A, @A+DPTR

	MOV B, #10
	DIV AB

	ADD A, R1
	MOV R1, A

	MOV A, B
	ADD A, R2

	MOV R2, #0Ah
	CLR C
	SUBB A, R2
	JC WITHOUT_CARRY
	INC R1
	JMP WITH_CARRY
WITHOUT_CARRY:
	ADD A, R2
WITH_CARRY:
	MOV R2, A
	INC DPTR
	DJNZ R3, MEAN_LOOP

	MOV A, #05h
	CLR C
	SUBB A, R2
	JNC LESS_HALF
	INC R1
LESS_HALF:
	MOV A, R1
	RET

ORG 2000h

DATA_ARRAY:
	DB 128,123,105,15,90,200,155,68,99,255

QMAX:
	DB 123
QMIN:
	DB 122

	END