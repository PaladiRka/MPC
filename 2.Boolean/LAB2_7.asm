$mod52
ORG 00h
BEGIN_AGAIN:
	MOV C, P0.0
	MOV ACC.0, C

	MOV C, P0.1
	CPL C
	ORL C, ACC.0

	MOV ACC.0, C

	MOV C, P0.2
	CPL C
	MOV B.0, C

	MOV C, P0.3
	ANL C, B.0
	MOV B.0, C

	XRL A, B
	RRC A
	JC TRUE
FALSE:
	MOV P1, #00h
JMP BEGIN_AGAIN
TRUE:
	MOV P1, #0FFh
JMP BEGIN_AGAIN
END
	