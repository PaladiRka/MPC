$mod52
org 00h
JMP MAIN1
org 0Bh
JMP INT_TIMER
org 30h

MAIN1:

	MOV	TMOD,	#00000001b
	MOV	TCON,	#00000001b
	MOV	R0,	#0000h	; Counter Interrupt
	SETB	EA			; Interrupt enable
	SETB	ET0			; Timer0 Interrupt enable
	SETB	PT0			; Inter prioriti
	;MOV	DPTR,	#DATA_ARRAY
	;INC	DPTR
	MOV	P1,	#00000000b
	MOV	R1,	#020h
	MOV	R5,	#001h
	MOV	B,	#004h
	ACALL	SET_TIMER

MAIN:
	MOV	A,	@R1
	CLR	C
	SUBB	A,	#004h
	JNC	TIME_END
	JMP	MAIN
TIME_END:
	CLR	TR0			; Timer0 stop
	DJNZ	R5,	NOT_END
	MOV	R5,	#004h
NOT_END:
	MOV	A,	R5
	MOV	DPTR,	#DATA_ARRAY
	MOVC	A,	@A+DPTR
	;INC	DPTR
	MOV	P1,	A
	MOV	R1,	#020h
	MOV	A,	#000h
	MOV	@R1,	A
	ACALL	SET_TIMER
	JMP	MAIN


INT_TIMER:

	;CLR	RS0
	;SETB	RS1
	PUSH	001h			; Push R1
	MOV	R1,	#020h
	INC	@R1
	CLR	TR0 			; Timer stop
	MOV	TH0,	#0FFH
	MOV	TL0,	#0F0H

	;CLR	RS1
	;SETB	RS0
	POP	001h			; Pop R1
	SETB	TR0			; Timer0 start
	RETI

SET_TIMER:
	CLR	TR0 			; Timer stop
	MOV	TH0,	#0FFH
	MOV	TL0,	#0F0H
	SETB	TR0			; Timer0 start
	RET

DATA_ARRAY:
	DB 00000000b,00011000b,00100100b,01000010b,10000001b

	END
