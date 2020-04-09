$mod52
org    00h
JMP    INIT
org    03h
RETI
org    013h
JMP    TRANSMIT
org    023h
JMP    INTER_TRANSMIT
org    30h
 
INIT:
    MOV    TMOD,    #01100000b
    ;MOV    TCON,    #00000001b
    MOV    SCON,    #11010000b
    MOV    TH1,    #0E8h ; baud rate 1200
    ;MOV    TH1,    #0F4h ; baud rate 2400
    MOV    TL1,    #00F9h
    SETB    IT0   		 ; Posege interrupt port 0
    ;SETB    IT1   		 ; Posege interrupt port 1
    SETB    EA   		 ; Interrupt enable
    SETB    EX0   		 ; Port0 Interrupt enable
    ;SETB    EX1   		 ; Port1 Interrupt enable
    SETB    ES   		 ; Serial Port Interrupt enable
    SETB    TR1
 
    MOV    P2,    #0FFh
    ;MOV    C,    P3.4
    ;MOV    C,    P3.5
    ;MOV    A,    P3
 
WAITING:
 
    ;MOV    A,    SBUF
    ;JNB    RI,    TRANSMIT
    JMP    WAITING
 
INTER_TRANSMIT:
TRANSMIT:
    PUSH    PSW
    ;MOV    C,    RI
    MOV    C,    P3.4
    JC    END_TRANSMIT
    PUSH    ACC
    PUSH    DPL
    PUSH    DPH
    PUSH    00h
    MOV    TH1,    #0E8h ; baud rate 1200
    ;MOVX    A,    @DPTR
    
    ANL    PCON,    #11111110b
    MOV    PCON,    A
    MOV    A,    SBUF
; Get byte from serial port
 
    MOV    R0,    #20h
    MOV    DPH,    @R0
    INC    R0
    MOV    DPL,    @R0
 
    MOVX    @DPTR,A
    INC    @R0
    MOV    A,    @R0
    CJNE    A,    #00h,    NOT_CARRY_WRITE_BYTE
    DEC    R0
    INC    @R0
 
NOT_CARRY_WRITE_BYTE:
 
    POP    00h
    POP    DPH
    POP    DPL
    POP    ACC
END_TRANSMIT:
    ACALL    RECEIVE
    POP    PSW
    CLR    RI
    RETI
 
RECEIVE:
    PUSH    PSW
    MOV    C,    P3.5
    JC    END_RECEIVE
    PUSH    ACC
    PUSH    DPL
    PUSH    DPH
    PUSH    00h
    MOV    TH1,    #0F4h ; baud rate 2400
    MOV    R0,    #30h
    MOV    DPH,    @R0
    INC    R0
    MOV    DPL,    @R0
 
    ORL    PCON,    #00000001b
    MOV    PCON,    A
    MOVX    A,    @DPTR
 
    MOV    SBUF,    A
; Put byte to serial port
 
    INC    @R0
    MOV    A,    @R0
    CJNE    A,    #00h,    NOT_CARRY_READ_BYTE
    DEC    R0
    INC    @R0
NOT_CARRY_READ_BYTE:
    CLR    TI
    ;JMP    WAITING    
    POP    00h
    POP    DPH
    POP    DPL
    POP    ACC
END_RECEIVE:
    POP    PSW
    RET
END
