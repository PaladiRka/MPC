$mod52
org	00h
JMP	MAIN1
org	03h
JMP	INT_PORT
org	0Bh
JMP	INT_TIMER
org	30h

MAIN1:

	MOV	TMOD,	#00000110b
	MOV	TCON,	#00000000b
	MOV	R0,	#0000h	; Counter Interrupt
	SETB	EA			; Interrupt enable
	SETB	ET0			; Timer0 Interrupt enable
	SETB	EX0			; Port0 Interrupt enable
	SETB	PT0			; Inter prioriti for Timer0
	SETB	PX0			; Inter prioriti for Port0
	;MOV	DPTR,	#DATA_ARRAY
	;INC	DPTR
	MOV	P1,	#00000000b
	MOV	R1,	#020h
	MOV	R0,	#021h
	MOV	@R0,	#001h
	MOV	B,	#004h
	ACALL	SET_TIMER
MAIN:
	JMP	MAIN


TIME_END:
	CLR	TR0			; Timer0 stop
	DJNZ	21h,	NOT_END
	MOV	21h,	#004h
NOT_END:
	MOV	A,	21h
	MOV	DPTR,	#DATA_ARRAY
	MOVC	A,	@A+DPTR
	;INC	DPTR
	MOV	P1,	A
	MOV	R1,	#020h
	MOV	A,	#000h
	MOV	@R1,	A
	ACALL	SET_TIMER
	JMP	INTERR_END

INT_PORT:
	MOV	P1,	#055h
	RETI

INT_TIMER:

	PUSH	000h			; Push R0
	PUSH	001h			; Push R1
	PUSH	005h			; Push R5
	PUSH	DPH			; Push High DPTR byte
	PUSH	DPL			; Push Low DPTR byte
	PUSH	ACC			; Push A
	PUSH	PSW			; Push PWS
	MOV	R1,	#020h
	INC	@R1

	MOV	A,	@R1
	CLR	C
	SUBB	A,	#001h
	JNC	TIME_END
INTERR_END:
	POP	PSW			; Pop PSW
	POP	ACC			; Pop A
	POP	DPL			; Pop Low DPTR byte
	POP	DPH			; Pop High DPTR byte
	POP	005h			; Pop R5
	POP	001h			; Pop R1
	POP	000h			; Pop R0
	;ACALL	SET_TIMER
	RETI

SET_TIMER:
	CLR	TR0 			; Timer stop
	MOV	TH0,	#0F9h
	MOV	TL0,	#0F9h
	SETB	TR0			; Timer0 start
	RET

DATA_ARRAY:
	DB 00000000b,00011000b,00100100b,01000010b,10000001b
PORT_COUNTER:
	END
