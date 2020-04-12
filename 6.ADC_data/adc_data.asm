$mod812
ORG 0h
JMP BEGIN_AGAIN
ORG 2bh
RETI

ORG 0033H ; (ADC ISR)
	JMP	ADC_INTR


ORG 4bh
BEGIN_AGAIN:
	MOV	R0,		        #030h ; (DPTR store)
	MOV	@R0,		    #00000
	;Init ADC
	MOV	    DMAL,		#000	; First addr for ADC date
	MOV     ADCCON1,	#062h	; power up ADC & enable Timer2 mode
	MOV	    ADCCON2,	#00000000b
	MOV	    TH2,		#0FFh
	MOV	    TL2,		#0F0h
	MOV	    RCAP2L,	    #0D2h	; sample period = 2 * T2 reload prd
	MOV	    RCAP2H,	    #0FFh	;   = 2*(10000h-FFD2h)*1.085us
	SETB	EADC		; enable ADC interrupt
	SETB	EA		    ; enable Interrupt
	SETB	TR2		    ; Start Timer2

	MOV	    R0,		    #030h ; Addr DPL
WAIT:	
    CJNE	@R0,		#14h,		WAIT
	CLR	    TR2		; Stop Timer2
	CLR	    EA		; interrupt disable
	MOV	    DPTR,		#00

	ACALL	MEAN_TEN_FUNC
	; R1 - low byte
	; R4 - high byte
	MOV	    DPTR,		#QMAX
	MOV	    A,		#00h
	MOVC	A,		@A + DPTR
	CLR	    C
	SUBB	A,		R4
	JNZ	    HIGH_BYTES_NOT_EQUAL_1
	MOV	    A,		#01h
	MOVC	A,		@A + DPTR
	CLR	    C
	SUBB	A,		R1
HIGH_BYTES_NOT_EQUAL_1:
	JNC	    NOT_BIGGEST
	MOV	    P1,		#03h
	JMP	    BEGIN_AGAIN
NOT_BIGGEST:
	MOV	    DPTR,		#QMIN
	MOV	    A,		#00h
	MOVC	A,		@A + DPTR
	CLR	    C
	SUBB	A,		R4
	JNZ	HIGH_BYTES_NOT_EQUAL_2
	MOV	    A,		#01h
	MOVC	A,		@A + DPTR
	CLR	    C
	SUBB	A,		R1
HIGH_BYTES_NOT_EQUAL_2:
	JC	    NOT_LOWEST
	MOV	    P1,		#00h
	JMP	    BEGIN_AGAIN
NOT_LOWEST:
	MOV	    P1,		#01h
	JMP	    BEGIN_AGAIN

MEAN_TEN_FUNC:
	; input:
	;	R0 - Data Pointer
	; Warning - R0 will be shifted by 10
	; output:
	;	result in ACC
	;
	MOV	R1,		#00h	; Sum of div of low byte
	MOV	R2,		#00h	; Sum of remainder of low byte
	MOV	R3,		#0Ah	; Amount of numbers
	MOV	R4,		#00h	; Sum of div of high byte
	MOV	R5,		#00h	; Integer of low byte
	MOV	R6,		#00h	; Integer of high byte

MEAN_LOOP:
	;	Hihg byte processing
	MOVX	A,		@DPTR ; Get high byte
	INC	DPTR

	MOV	R6,		A
	MOVX	A,		@DPTR ; Get low byte

	ANL	A,		#0F0h
	ORL	A,		R6
	SWAP	A

	MOV	B,		#10
	DIV	AB

	ADD	A,		R4
	MOV	R4,		A

	SWAP	A
	MOV	R5,		A



	;	Low byte processing

	MOVX	A,		@DPTR ; Get low byte again
	INC	DPTR

	ANL	A,		#00Fh
	ORL	A,		R5	; Add mod of high byte

	MOV	B,		#10
	DIV	AB

	ADD	A,		R1
	MOV	R1,		A

	MOV	A,		B
	ADD	A,		R2

	MOV	R2,		#0Ah
	CLR	C
	SUBB	A,		R2
	JC	WITHOUT_CARRY
	INC	R1
	JMP	WITH_CARRY
WITHOUT_CARRY:
	ADD	A,		R2
WITH_CARRY:
	MOV	R2,		A

	DJNZ	R3,		MEAN_LOOP

	MOV	A,		#05h
	CLR	C
	SUBB	A,		R2
	JNC	LESS_HALF
	INC	R1
LESS_HALF:
	MOV	A,		R4
	SWAP	A
	ANL	A,		#0F0h
	ADD	A,		R1
	MOV	R1,		A
	MOV	A,		R4
	SWAP	A
	ANL	A,		#00Fh
	MOV	R4,		A
	MOV	A,		R1
	MOV	B,		R4
	RET

ADC_INTR:
	PUSH	DPH
	PUSH	DPL
	PUSH	PSW
	PUSH	ACC

	MOV	PSW,		#00010000b
	MOV	R0,		#030h		; (DPTR store)
	MOV	DPL,		@R0
	MOV	DPH,		#000h
	MOV	A,		ADCDATAH
	MOVX	@DPTR,		A
	INC	DPTR
	MOV	A,		ADCDATAL
	MOVX	@DPTR,		A
	INC	DPTR

	MOV	@R0,		DPL

	CJNE	@R0,	#14h, NON_STOP_ADC
	CLR	EA
NON_STOP_ADC:

	POP	ACC
	POP	PSW
	POP	DPL
	POP	DPH
	RETI

ORG 2000h
QMAX:
	DW 0588h
QMIN:
	DW 00079h

	END
