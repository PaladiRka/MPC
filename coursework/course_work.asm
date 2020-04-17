$mod812
;____________________________________________________________________
;                                                   Port's define
START_STOP_PROCESS1  EQU     P0.7    ; Start stop toggle for main process
START_STOP_PROCESS2  EQU     P1.4    ; Start stop toggle for main process
DIGITAL_SENSOR_OUT  EQU     P2.3    ; P2.3 line for out digital sensor process
HEATER              EQU     P2.2    ; Heater to P2.2 on board
COOLER              EQU     P2.1    ; Cooler to P2.1 on board
INDICATION          EQU     P2.0    ; Led or buzzer assigned to P2.0 on board
;____________________________________________________________________
;                                                   Other define
CHANNEL_TEMP        EQU     07h     ; channel of adc with temperature
COUNT_TEMP_MEASURM  EQU     08h     ; count byte measurement for average

BASIC_ADR_FOR_TABL  EQU     40h     ; basic address for table for digital sensor

;____________________________________________________________________
                                    ; DEFINE VARIABLES IN INTERNAL RAM
DSEG
ORG 0050h
PC_MEM_DIGITAL:         DS  1       ; state digital sensor in shared PC part
PC_MEM_TEMP_AVERAGE_H:  DS  1       ; temperature average in shared PC part
PC_MEM_TEMP_AVERAGE_L:  DS  1       ; temperature average in shared PC part
PC_MEM_TEMPERATURE:     DS  8       ; temperature array in shared PC part

ORG 0060h
DIGITAL_SENS:           DS  1       ; digital sensor state
TEMP_AVERAGE_H:         DS  1       ; temperature average
TEMP_AVERAGE_L:         DS  1       ; temperature average
TEMPERATURE:            DS  8       ; temperature array

CSEG
ORG 0000h
    JMP     MAIN                    ; jump to main program
ORG 000Bh ; (Timer0 ISR)
    JMP     EMERGENCY_INDICATION
ORG 0013h ; (INT1 ISR)
    JMP     EMERGENCY_SENSOR
ORG 001Bh ; (Timer1 ISR)
    CLR     DIGITAL_SENSOR_OUT
    CLR     TR1
    RETI
ORG 0033H ; (ADC ISR)
    JMP     ANALOG_TEMPER_INT
org 004Bh

MAIN:
    MOV      SP,     #0080h
    MOV       P1,    #11100000b
    MOV	    P2,     #00h
    MOV	    P0,     #0FFh
    MOV	    P3,     #0FFh
; PRECONFIGURE for adc with Timer2
    MOV     ADCCON1,#062h           ; power up ADC & enable Timer2 mode
    MOV     ADCCON2,#CHANNEL_TEMP   ; select channel to convert
    MOV     RCAP2L, #0A2h           ; sample period = 2 * T2 reload prd
    MOV     RCAP2H, #0FFh           ;   = 2*(10000h-FFD2h)*1.085us
    MOV     TL2,    #0A2h           ;   = 2*46*1.085us
    MOV     TH2,    #0FFh           ;   = 99.8us
    MOV     T2CON,  #00000000b

; PRECONFIGURE for Timer1 and Timer0
    MOV     TMOD,   #011h           ; first mode Timer1 and Timer0
    SETB	PT0			      ; inter priority for Timer0
; PRECONFIGURE for INT1
    MOV     TCON,   #004h           ; edge INT1
; LAUNCH Timer2 DRIVEN CONVERSIONS...
    SETB	EA                      ; enable interrupts
    SETB    EX1                     ; enable INT1 interrupt
    SETB    ET0                     ; enable Timer0 interrupt
    SETB    ET1                     ; enable Timer1 interrupt
    SETB    EADC                    ; enable ADC interrupt
    ;SETB    PX1                     ; interrupt priority for INT1
    SETB    TR2                     ; run Timer2
; General processing
    CLR     DIGITAL_SENSOR_OUT
LOOP:
    JB      TR1, WAIT_START_SIGNAL
        MOV A, P0
        ANL A, #007h
        CLR C
        SUBB A, DIGITAL_SENS
        JZ WAIT_START_SIGNAL
            MOV     A, P0
            ANL     A, #007h
            MOV     DIGITAL_SENS, A
            ACALL   DIGITAL_SENSOR_1
            ACALL   NON_BLOCK_TIMER_FOR_DIG_SENS
    WAIT_START_SIGNAL:
        JB     START_STOP_PROCESS1, LOOP
        JNB     START_STOP_PROCESS2, WAIT_START_SIGNAL
    JMP     LOOP
;____________________________________________________________________
;                                                   Interrupt for INT1 for emergency sensor
EMERGENCY_SENSOR:
    MOV     A,                      DIGITAL_SENS
    ANL     A,                      #007h
    MOV     PC_MEM_DIGITAL,         A
    MOV     PC_MEM_TEMP_AVERAGE_H,  TEMP_AVERAGE_H
    MOV     PC_MEM_TEMP_AVERAGE_L,  TEMP_AVERAGE_L
    MOV     R5,                     #COUNT_TEMP_MEASURM
    MOV     R0,                     #TEMPERATURE
    MOV     R1,                     #PC_MEM_TEMPERATURE
    LOOP_TEMP_ARRAY:
        MOV     A,      @R0
        MOV     @R1,    A
        INC     R1
        INC     R0
    DJNZ    R5,                     LOOP_TEMP_ARRAY
    ; Indication with frequency 500Hz = period 2ms
    MOV     TH0,    #0FCh           ; 1ms = 1000us = 1000 tics = 1000(10) = 03E8(16)
    MOV     TL0,    #017h           ; State changes twice as often as the Period indication
    SETB    TR0
    JMP     $
RETI
EMERGENCY_INDICATION:
    CPL     INDICATION
    MOV     TH0,    #0FCh           ; 1ms = 1000us = 1000 tics = 1000(10) = 03E8(16)
    MOV     TL0,    #017h           ; State changes twice as often as the Period indication
RETI
;____________________________________________________________________
;                                                   Interrupt for temp ADC
ANALOG_TEMPER_INT:
;TODO bank switch
    PUSH	DPH
    PUSH	DPL
    PUSH    PSW
    PUSH    ACC
    MOV     PSW, #00010000b
    ; R6 - high byte temp average
    ; R7 - low  byte temp average
    ; R5 - counter measurement
    MOV     A, ADCDATAH
    ANL     A, #0F0h                ; Check channel
    CJNE    A, #CHANNEL_TEMP, END_ANALOG_TEMPER_INT
        MOV     A, ADCDATAL         ; Low byte processing
        ADD     A, R7
        MOV     R7, A
        JNC     WITHOUT_CARRY_TEMP_LBYTE
            INC     R6
        WITHOUT_CARRY_TEMP_LBYTE:
        MOV     A,  ADCDATAH         ; High byte processing
        ADD     A,  R6
        MOV     R6, A
        MOV     A,  #TEMPERATURE
        ADD     A,  R5

        MOV     R0, A
        MOV     A,  ADCDATAH
        MOV     @R0,A
        INC     R0
        MOV     A,  ADCDATAL
        MOV     @R0,A
        
        INC     R5
        INC     R5
        CJNE    R5, #COUNT_TEMP_MEASURM, END_ANALOG_TEMPER_INT
            ACALL   AVERAGE_R6_R7_FOUR
            MOV     R5, #00h        ; reset counter measurement
            MOV     TEMP_AVERAGE_L, R7
            MOV     TEMP_AVERAGE_H, R6
            MOV	    DPTR,   #LOW__TEMPERATURE
            MOV	    A,      #00h
            MOVC	A,      @A + DPTR
            CLR	    C
            SUBB	A,      R6
            JNZ	    HIGH_BYTES_NOT_EQUAL_1
                INC     A
                MOVC	A,		@A + DPTR
                CLR	    C
                SUBB	A,		R7
            HIGH_BYTES_NOT_EQUAL_1:
            JC	    NO_LOWEST_TEMPER
                SETB    HEATER      ; Turn on heater
                JMP     CONTIN_TEMPER_INT_1
            NO_LOWEST_TEMPER:
                CLR     HEATER      ; Turn off heater
            CONTIN_TEMPER_INT_1:
            MOV	    DPTR,	#HIGH_TEMPERATURE
            MOV	    A,		#00h
            MOVC	A,		@A + DPTR
            CLR	    C
            SUBB	A,		R6
            JNZ	HIGH_BYTES_NOT_EQUAL_2
                MOV	    A,		#01h
                MOVC	A,		@A + DPTR
                CLR	    C
                SUBB	A,		R7
            HIGH_BYTES_NOT_EQUAL_2:
            JNC     NO_HIGHEST_TEMPERATURE
            SETB    COOLER      ; Turn on cooler
            JMP     CONTIN_TEMPER_INT_2
            NO_HIGHEST_TEMPERATURE:
                CLR     COOLER      ; Turn off cooler
            CONTIN_TEMPER_INT_2:
            MOV R6, #00h
            MOV R7, #00h
    END_ANALOG_TEMPER_INT:
    POP     ACC
    POP     PSW
    POP	DPL
    POP	DPH
RETI
;____________________________________________________________________
;                                                   Timer's for digital begin
;-------------------------NON BLOCK DELAY----------------------------
NON_BLOCK_TIMER_FOR_DIG_SENS:
    JNC     NON_BLOCK_TIMER_FOR_DIG_SENS_END
SET_TIMER_FOR_DIGITAL_SENSOR:
    MOV     TH1,    #0FFh ; #04Eh
    MOV     TL1,    #020h           ; 20ms = 20000us = 20000 tics = 20000(10) = 4E20(16)
    SETB    DIGITAL_SENSOR_OUT
    SETB    TR1                    ; run Timer1
NON_BLOCK_TIMER_FOR_DIG_SENS_END:
RET
;---------------------------BLOCK DELAY------------------------------
BLOCK_TIMER_FOR_DIG_SENS:
    JNC     BLOCK_TIMER_FOR_DIG_SENS_END
    BLOCK_DELAY_FOR_DIG_SENS:
    ; Discard R4 and R3
    MOV     R4, #10                 ; 100 * 200us = 20000ms
    SETB    DIGITAL_SENSOR_OUT
    BLOCK_DELAY_20MS:
        MOV     R3, #20             ; 200 * 1us = 200us
        DJNZ    R3, $               ; sit here for 200us
    DJNZ    R4, BLOCK_DELAY_20MS; repeat 100 times (20ms total)
    CLR DIGITAL_SENSOR_OUT
BLOCK_TIMER_FOR_DIG_SENS_END:
RET
;                                                   Timer's for digital end
;____________________________________________________________________
;                                                   Average for temperature
AVERAGE_R6_R7_FOUR:
    ; R6 - high byte
    ; R7 - low  byte
    ; Sum of Temperature
    ; Result - R7 R6
    ; Double Right shift == div on 4 
    MOV     A, R6
    RRC     A ;R6
    MOV     R6, A
    
    MOV     A, R7
    RRC     A ;R7
    MOV     R7, A
    
    MOV     A, R6
    RRC     A ;R6
    ANL     A,  #00Fh
    MOV     R6, A

    MOV     A, R7
    RRC     A ;R7
    MOV     R7, A
RET
;____________________________________________________________________
;                                                   Digital processing begin
DIGITAL_SENSOR_1:
; P0.0, P0.1 and P0.2 is x1, x2 and x3 
; First type - bit function

    MOV     C, P0.0
    ANL     C, P0.1
    ANL     C, P0.2
    RET

DIGITAL_SENSOR_2:
; P0.0, P0.1 and P0.2 is x1, x2 and x3 
; Second type - tree algorithm

    JNB     P0.2, DIGITAL_SENSOR_ZERO
        JNB     P0.1, DIGITAL_SENSOR_ZERO
            JNB     P0.0, DIGITAL_SENSOR_ZERO
                SETB    C
                RET
    DIGITAL_SENSOR_ZERO:
    CLR     C
    RET

DIGITAL_SENSOR_3:
; P0.0, P0.1 and P0.2 is x1, x2 and x3 
; Third type - Table algorithm (WIP - no table )
    PUSH    DPH
    PUSH    DPL
    PUSH    ACC
    MOV     A, P0
    ANL     A,  #007h           
    MOV     DPTR, #truth_table
    MOVC    A, @A+DPTR
    MOV     C, ACC.0
    POP     ACC
    POP     DPL
    POP     DPH
    RET
;                                                   Digital processing end
;____________________________________________________________________
ORG 2000h
truth_table:            DB  0,0,0,0,0,0,0,1         ; Truth table for digital sensor
HIGH_TEMPERATURE:       ; top limit for temperature
	DW 0F30h
LOW__TEMPERATURE:       ; low limit for temperature
	DW 0F20h
END
