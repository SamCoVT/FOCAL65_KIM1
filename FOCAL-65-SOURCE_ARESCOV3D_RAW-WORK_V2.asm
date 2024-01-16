; *** BEGIN MIKE B'S SECTION

                        ;
        ; HERE TO TYPE OUT A STRING VARIABLE
                        ;
TPSTR   LDA #$24        ; '$' INDICATE IT'S A STRING VARIABLE
        JSR PRINTC      ;
        LDA #$3D        ; '=' DON'T PRINT A SUBSCRIPT ON A $ VARIB
        JSR PRINTC      ;
        LDA #$22        ; '"' DELIMIT STRING WITH QUOTES
        JSR PRINTC      ;
        LDY #$02        ; POINT TO STRING LENGTH
        LDA (VARADR),Y  ; PICK UP THE STRING LENGTH
        STA VSIZE       ; SAVE IT
        INY             ; POINT TO FIRST BYTE OF STRING
        TYA             ; NOW UPDATE 'VARADR' TO BASE ADDR OF $
        JSR UPDVAR      ;
        LDY #$00        ; POINT TO FIRST BYTE OF STRING
TPNXTC  TYA             ; SAVE OFFSET
        PHA             ;
        LDA (VARADR),Y  ; GET BYTE FROM STRING
        JSR PRINTC      ; PRINT THE BYTE
        PLA             ; RESTORE POINTER
        TAY             ;
        INY             ; POINT TO NEXT BYTE
        CPY VSIZE       ; PRINTED ALL OF STRING YET?
        BNE TPNXTC      ; BRANCH IF MORE TO PRINT
        TYA             ; YES, THEN SKIP OVER STRING BY
        JSR UPDVAR      ;   UPDATING 'VARADR'
        LDA #$22        ; '"' CLOSE OFF STRING WITH CLOSING QUOTE
        JSR PRINTC      ;
        JMP TDNEXT      ; AND DUMP NEXT VARIABLE
                        ;
JTDUMP  JMP TDUMP       ; BRANCH AID
                        ;
        ; 'TYPE - ASK COMMAND PROCESSOR'
                        ; 
TASK1   JSR PUSHJ       ; GO GET THE VARIABLE
        .WORD GETVAR    ; ($1B43 in ww -- mtb)
        JSR BOMSTV      ; BOMB OUT IF A $ VARIABLE IS USED IN 'ASK'
        LDA CHAR        ; SAVE DELIMITER
        PHA             ;   ON HARDWARE STACK
        INC INSW        ; FLAG INPUT FROM KEYBOARD
ASKAGN  LDX #VARADR     ; SAVE THE VARIABLE'S ADDRESS
        JSR PUSHB2      ;
        JSR PUSHJ       ; NOW GO GET USER SUPPLIED DATA
        .WORD EVALM1    ; ($19F5 in ww -- mtb)
                        ;
;        LDA #$41        ; RESTORE 'ATSW' (SINCE WE MUST BE RECURSIVE!)
;        STA ATSW        ; (in ww -- mtb)
        LDX #VARADR+1   ; RESTORE VARIABLE'S ADDRESS
        JSR POPB2       ;
        LDA CHAR        ; GET DELIMITER FROM EVAL
        CMP #LINCHR     ; WAS IT 'LINE-DELETE' CHARACTER?
        BNE STODAT      ; BRANCH IF NOT, STORE VALUE AWAY
        LDA IDEV        ; YES, IS THE INPUT DEVICE
        CMP CONDEV      ;   THE CONSOLE?
        BNE ASKAGN      ; BRANCH IF NOT, ASK AGAIN
        JSR CRLF        ; YES, ADVANCE A LINE
        BPL ASKAGN      ;   AND ASK AGAIN
STODAT  JSR PUTVAR      ; PLACE DATA IN VARIABLE
        DEC INSW        ; FLAG INPUT FROM CORE AGAIN
        PLA             ; GET DELIMITER BACK AGAIN
        STA CHAR        ;
        BPL TASK        ; UNCONDITIONALLY CONTINUE PROCESSING
                        ;
TFORM   JSR GETC        ; MOVE PAST '%'
        JSR GETLNS      ; GET GG.SS
        LDA GRPNO       ; GET GG
        STA M           ; SAVE AS NUMBER BEFORE DECIMAL POINT
        LDA LINENO      ; GET SS
        STA N           ; SAVE AS NUMBER AFTER DECIMAL POINT
        JMP TASK        ;   AND CONTINUE PROCESSING
                        ;
TYPE    STA ATSW        ; FLAG WHICH ONE IT IS
TASK    LDA #$00        ; ENABLE THE TRACE
        STA DEBGSW      ;
        JSR SPNOR       ; LOOK FOR NEXT NON-BLANK
        CMP #$24        ; '$'
        BEQ JTDUMP      ; DUMP OUT THE VARIABLE LIST
        CMP #$25        ; '%' FORMAT CONTROL?
        BEQ TFORM       ; BRANCH IF YES
        CMP #$21        ; '!' SEE IF SPECIAL
        BEQ TCRLF       ; GIVE OUT A CARRIAGE RETURN-LINE FEED
        CMP #$23        ; '#'
        BEQ TCR         ; CARRIAGE RETURN ONLY
        CMP #$22        ; '"'
        BEQ TQUOT       ; TYPE OUT A QUOTED STRING
        CMP #$2C        ; ','
        BEQ TASK4       ; IGNORE IN CASE USER WANTS IT TO LOOK PRETTY
        CMP #$3B        ; ';' END OF COMMAND?
        BEQ TPROC       ; YES, THEN BRANCH
        CMP #$0D        ; 'CR' END OF LINE?
        BEQ TPC1        ; YES, THEN GO HANDLE IT
        LDA ATSW        ; NOT SPECIAL CHAR, GET COMMAND SWITCH
        CMP #$41        ; 'A' WHICH COMMAND ARE WE DOING?
        BEQ TASK1       ; BRANCH IF 'ASK', AS IT DIFFERS
        JSR PUSHJ       ; CALL 'EVAL' TO EVALUATE THE EXPRESSION
        .WORD EVAL      ; ($19F8 in ww -- mtb)
;        LDA #$54        ; RESTORE 'ATSW' (SINCE WE MUST BE RECURSIVE!)
;        STA ATSW        ; (in ww -- mtb)
        JSR FPRNT       ; GO OUTPUT IT
        LDA CHAR        ; GET TERMINATOR FROM 'EVAL'
        CMP #$29        ; ')' SO "TYPE 3)" DOESN'T DIE!
        BEQ TASK4       ; FLUSH IF WE DON'T LIKE IT
        CMP #$3D        ; '=' ALSO FLUSH OTHER NASTIES
        BEQ TASK4       ;
        CMP #$2E        ; '.'
        BEQ TASK4       ;
        BNE TASK        ; OTHERWISE, CONTINUE PROCESSING
                        ;
ASK     = TYPE          ; ($1488 in ww -- mtb)
                        ;
TCRLF   JSR CRLF        ; OUTPUT A CR FOLLOWED BY A LF
        BPL TASK4       ; UNCONDITIONAL BRANCH
TCR     LDA #$0D        ; 'CR' OUTPUT A CARRIAGE RETURN
        JSR PRINTC      ;
TASK4   JSR GETC        ; SKIP OVER THIS CHARACTER
        BPL TASK        ; UNCONDITIONALLY CONTINUE PROCESSING
                        ;
TQUOT   INC DEBGSW      ; DISABLE TRACE SO LITERAL ONLY PRINTS ONCE
TQUOT1  JSR GETC        ; GET NEXT CHAR
        CMP #$22        ; '"' CLOSING QUOTE?
        BEQ TASK4       ; BRANCH IF YES
        CMP #$0D        ; 'CR' END OF LINE?
        BEQ TPC1        ; BRANCH IF YES (IT TERMINATES STRING)
        JSR PRINTC      ; OTHERWISE, PRINT THE CHARACTER
        BPL TQUOT1      ; UNCONDITIONALLY LOOP UNTIL DONE
TPC1    LDA #$00        ; ENABLE TRACE JUST IN CASE
        STA DEBGSW      ;
FPC1    JMP PC1         ; EXIT 'PROCESS'
TPROC   JMP PROCES      ; CONTINUE PROCESSING ON THIS LINE
                        ;
        ; "FOR" LOOP ITERATION COMMAND
                        ;
FOR     JSR PUSHJ       ; GO GET THE VARIABLE (mtb)
        .WORD GETVAR    ; ($2B51; $1B43 in ww -- mtb)
        LDA CHAR        ; GET TERMINATOR
        CMP #$3D        ; '=' SIGN?
        BEQ FOR2        ; BRANCH IF YES
        BRK             ; NO, TRAP
        .BYTE NOEQLS    ; ?NO '=' IN 'FOR' OR 'SET' (#$F3)
FOR2    LDX #VARADR     ; SAVE THE ADDRESS OF THE VARIABLE
        LDY #$05        ;   AND ITS PROPERTIES
        JSR PUSHB0      ;   ON STACK
        JSR PUSHJ       ; CALL 'EVAL' TO EVALUATE RIGHT HAND
        .WORD EVALM1    ;    SIDE OF '=' ($2A03; $19F5 in ww -- mtb)
        LDX #VARADR+4   ; GET ADDR OF VARIABLE BACK AGAIN
        LDY #$05        ;
        JSR POPB0       ;
        JSR BOMSTV      ; BOMB OUT IF LOOP COUNTER IS STR. VARIB.
        JSR PUTVAR      ; NOT A STRING, SO STORE INITIAL VALUE
        LDA CHAR        ; GET THE EXPRESSION TERMINATOR
        CMP #$2C        ; ',' COMMA?
        BEQ FINCR       ; BRANCH IF IT'S A 'FOR' COMMAND
BTFOR   BRK             ; TRAP
        .BYTE FBDTRM    ; ?BAD TERMINATOR IN 'FOR' (#$F2)
                        ;
        ; "SET" COMMAND
                        ;
;SET1    JSR GETC        ; SKIP OVER COMMA (in ww -- mtb)
SET     JSR PUSHJ       ; CALL 'EVAL' TO EVALUATE EXPRESSION
        .WORD EVALM1    ; 'EVALM1' ($2A03; $19F5 was 'EVAL' $19F8 in ww -- mtb)
        LDA CHAR        ; GET TERMINATOR
        CMP #$2C        ; ',' COMMA?
        BEQ SET         ; BRANCH IF YES, LOOP FOR ANOTHER EXPRESS (SET1 in ww -- mtb)
        JMP PROC        ; NO. ALL DONE, CONTINUE ON THIS LINE
                        ;
; there is a handwritten note here: 'Best cmmd exit points $1304'
; ($2302 in this Aresco version code)
                        ;
                        ;
        ; 'FOR' COMMAND PROCESSING
                        ;
FINCR   LDX #VARADR     ; SAVE THE ADDR OF THE LOOP VARIABLE ON STACK
        JSR PUSHB2      ;
        JSR PUSHJ       ; GO GET THE INCREMENT
        .WORD EVALM1    ; ($2A03; $19F5 in ww -- mtb)
        LDA CHAR        ; GET TERMINATOR
        CMP #$2C        ; ',' DID WE GET AN INCREMENT?
        BEQ FLIMIT      ; YES, GO GET THE UPPER LIMIT OF LOOP
        CMP #$3B        ; ';' WAS NO INCREMENT SPECIFIED?
        BEQ FINCR1      ; BRANCH IF NO INCREMENT GIVEN
        CMP #$0D        ; 'CR' CARRIAGE RETURN?
        BNE BTFOR       ; NO, THEN BAD TERMINATOR
        BRK             ; YES, TRAP
        .BYTE UFL       ; ?USELESS 'FOR' LOOP (#$F1)
FINCR1  LDX #$FB        ; GET NEGATIVE OF NUMBER OF BYTES (-5)
FI1C    LDA FONE+NUMBF,X ; GET NEXT BYTE
        JSR PUSHA       ; PUSH IT ON STACK
        INX             ; POINT TO NEXT ONE
        BMI FI1C        ;   AND LOOP UNTIL ALL PUSHED
        BPL FSHORT      ; UNCONDITIONAL BRANCH
FLIMIT  JSR PHFAC1      ; SAVE INCREMENT ON STACK
        JSR PUSHJ       ; NOW EVALUATE THE UPPER LIMIT
        .WORD EVALM1    ; ($2A03; $19F5 in ww -- mtb)
FSHORT  JSR PHFAC1      ; SAVE UPPER LIMIT ON STACK AND ENTER LOOP
                        ;
        ; 'LOOP PROCESSOR FOR "FOR" COMMAND'
                        ;
FCONT   JSR PUSHTP      ; NOW SAVE THE TEXT POINTERS ON STACK
        LDA PC          ; SAVE PC ACROSS CALL
        JSR PUSHA       ;
        JSR PUSHJ       ; NOW EXECUTE THE REST OF THE LINE
        .WORD PROCES    ; 'PROCES' ($22FF; $1301 in ww -- mtb)
        JSR POPA        ; SET PC BACK
        STA ITEMP1      ; SAVE IT IN TEMPORARY
        JSR POPTP       ; SAVE POINTERS FOR POSSIBLE RE-ENTRY
        JSR PLTMP       ; RESTORE UPPER LOOP LIMIT INTO TEMPORARY
        JSR POPIV       ; RESTORE INCREMENT AND VARIABLE ADDR
        LDA PC          ; GET PC
        CMP #RETCMD     ; WAS A 'RETURN' COMMAND JUST EXECUTED?
        BEQ FORXIT      ; BRANCH IF YES, THEN EXIT THE LOOP NOW!
        LDA M2          ; GET THE SIGN OF THE INCREMENT (+ OR -)
        PHP             ; SAVE STATUS ON STACK FOR LATER
        JSR PUSHIV      ; SAVE AGAIN FOR POSSIBLE REPEAT OF LOOP
        JSR FETVAR      ; GO GET THE VARIABLE'S CURRENT VALUE
        JSR FADD        ; ADD THE INCREMENT TO FLAC
        JSR PUTVAR      ; STORE AS NEW LOOP COUNTER VALUE
        JSR PHTMP       ; SAVE TEMPORARY ON STACK
        JSR PLFAC2      ; PLACE INTO FAC2
        JSR FSUB        ; SUBTRACT COUNTER FROM UPPER LIMIT (mtb)
        PLP             ; GET SIGN OF THE INCREMENT
        BMI CNTDWN      ; BRANCH IF NEGATIVE, WE ARE COUNTING DOWN
        LDA FLCSGN      ; GET THE SIGN OF THE NUMBER
        BPL MORFOR      ; BRANCH IF REPEAT NECESSARY
FOREND  JSR POPIV       ; CLEAN UP STACK
FORXIT  LDA ITEMP1      ; RESTORE PC
        STA PC          ;   IN CASE 'RETURN' ENCOUNTERED
        JSR POPJ        ; EXIT 'FOR' COMMAND
CNTDWN  LDA FLCSGN      ; ARE WE LESS THAN THE LOOP LIMIT?
        BEQ MORFOR      ; NO, THEN KEEP GOING
        BPL FOREND      ; YES, THEN THAT'S ALL
MORFOR  JSR PHTMP       ; PLACE UPPER LIMIT BACK ON THE STACK
        BPL FCONT       ; UNCONDITIOANALLY REPEAT LOOP
                        ;
        ; LINE NUMBER MANIPULATION ROUTINES
                        ;
        ; "GETLN" GET A LINE NUMBER FROM PROGRAM TEXT.
        ; RETURNS WITH V=1 IF "ALL" (00.00), OTHERWISE
        ; IT RETURNS WITH Z=1 IF GROUP NUMBER ONLY (GG.00)
        ; AND Z=0 IF INDIVIDUAL LINE NUMBER (GG.LL).
                        ;
GETLNC  JSR FINP        ; ONLY ALLOW NUMERIC INPUT
        JMP GETLN1      ;   AND ENTER REST OF CODE
                        ;
GETLNS  JSR SPNOR       ; GET NEXT NON-BLANK
GETLN   LDA #$00        ; ASSUME LINE NUMBER IS ZERO
        STA GRPNO       ;
        STA LINENO      ;
        LDA CHAR        ; GET FIRST CHARACTER OF EXPRESSION?
        CMP #$2C        ; ',' IS EXPRESSION NULL?
        BEQ GOTLNO      ; BRANCH IF YES, THEN WE HAVE THE NUMBER
        CMP #$0D        ; 'CR' ANOTHER FORM OF NULL?
        BEQ GOTLNO      ; BRANCH IF YES, THEN WE HAVE THE NUMBER
        JSR TESTN       ; DOES EXPRESSION BEGIN WITH A NUMBER?
        BCS GETLNX      ; BRANCH IF NOT, THEN MUST BE COMPLEX 
        JSR GETILN      ; CALL INTEGER LINE NUMBER INPUT FOR SPEED
        JMP GOTLNO      ; WE NOW HAVE THE LINE NUMBER
GETLNX  JSR PUSHJ       ; CALL 'EVAL' TO EVALUATE EXPRESSION
        .WORD EVAL      ; ($2A06; $19F8 in ww -- mtb)
GETLN1  JSR PHFAC1      ; SAVE EXPRESSION VALUE ON STACK
        JSR GETL        ; INTEGERIZE AND RANGE CHECK
        STA GRPNO       ; SAVE AS GROUP NUMBER
        JSR FLOAT       ; NOW FLOAT THE GROUP NUMBER
        JSR PLFAC2      ; POP FULL GG.SS INTO FAC2
        JSR FSUB        ; SUBTRACT OFF THE GROUP NUMBER (mtb)
        JSR GMUL10      ; MULTIPLY BY 100
        JSR GMUL10      ;
        LDX #FHALF      ; MOVE CONSTANT .50
        LDY #X2         ;
        JSR MOVXY       ;
        JSR FADD        ; NOW ADD IN THE .50 FOR ROUNDING
        JSR GETL        ; INTEGERIZE AND RANGE CHECK
        STA LINENO      ; SAVE AS LINE NUMBER (STEP NUMBER)
GOTLNO  CLV             ; ASSUME NOT 00.00
        LDA GRPNO       ; GET GROUP NUMBER
        ORA LINENO      ; 'OR' IN THE LINE NUMBER
        BEQ GOTALL      ; BRANCH IF BOTH ARE ZERO
        LDA GRPNO       ; GET GROUP NUMBER AGAIN
        BEQ BADLNO      ; BAD LINE NUMBER IS GROUP ONLY IS ZERO
        LDA LINENO      ; GROUP NUMBER OK, GET LINE (STEP) NO.
RTS3    RTS             ; RETURN WITH Z=1 IF GROUP ONLY
                        ;
GOTALL  BIT BITV1       ; EXIT WITH V=1, (n=1 ??)
        RTS             ;
                        ;
        ; 'LINE NUMBER MANIPULATION ROUTINES'
                        ;
GETL    JSR FIX         ; FIX THE NUMBER IN FAC1
        LDA M1          ; GET HIGH ORDERS
        ORA M1+1        ; SMASH THEM TOGETHER
        BNE BADLNO      ; LINE NUMBER CAN ONLY BE POSITIVE
        LDA M1+2        ;
        CMP #$64        ; AND < 100 ?
        BMI RTS3        ;
BADLNO  BRK             ; TRAP
        .BYTE ILLNO     ; ILLEGAL LINE NUMBER (#$FC)
GMUL10  LDX #FTEN       ; MOVE 10.0
        LDY #X2         ;   INTO FAC2
        JSR MOVXY       ;
        JMP FMUL        ; * PJMP *  FAC1*FAC2=FAC1
                        ;
        ; 'PRINTLN - PRINT A LINE NUMBER'
                        ; 
        ; "PRINTLN" PRINT A LINE NUMBER TO OUTPUT DEVICE
                        ; 
PRNTLN  LDY TEXTP       ; GET TEXT POINTER
        LDA (TXTADR),Y  ; GET GROUP NUMBER
        BNE PRNTL1      ; BRANCH IF NOT ZERO
        INY             ; DO NOT PRINT GROUP ZERO LINE NUMBERS
        INY             ;
        STY TEXTP       ; POINT TO FIRST CHARACTER IN LINE
        RTS             ;   AND RETURN
                        ;
PRNTL1  PHA             ; SAVE THE GROUP NUMBER FOR LATER
        INY             ; POINT TO THE STEP NUMBER
        LDA (TXTADR),Y  ; GET STEP NUMBER
        INY             ; MOVE PAST IT
        STY TEXTP       ; SAVE POINTER
        JSR PFLT        ; FLOAT THE STEP NUMBER
        JSR DIV10       ; DIVIDE BY 100
        JSR DIV10       ;
        JSR PHFAC1      ; SAVE 00.SS FOR LATER
        PLA             ; GET THE GROUP NUMBER BACK
        JSR PFLT        ; FLOAT IT
        JSR PLFAC2      ; RESTORE 00.SS INTO FAC2
        JSR FADD        ; ADD TOGETHER TO FORM GG.SS
                        ; * PFALL * INTO OUTPUT ROUTINE
        LDA #$02        ; ASSUME TWO DIGITS BEFORE THE DECIMAL PT.
        TAX             ;   AND TWO DIGITS AFTER
        BNE OUTLN       ; UNCONDITIONAL BRANCH
OUTLN0  LDA #$02        ; ASSUME TWO DIGITS BEFORE DECIMAL
OUTLN1  LDX #$00        ; ASSUME NO DECIMAL POINT (mtb)
OUTLN   TAY             ; SAVE NUMBER BEFORE DECIMAL IN Y REG
        LDA M           ; SAVE OLD FORMAT ON HARDWARE STACK (mtb)
        PHA             ; (COULD BE CALLED FROM ERROR TRAP)
        LDA N           ;
        PHA             ;
        STY M           ; STORE NEW FORMAT
        STX N           ;
        JSR FPRNT       ; PRINT NUMBER IN TEMPORARY FORMAT
        PLA             ; RESTORE OLD FORMAT
        STA N           ;
        PLA             ;
        STA M           ;
        RTS             ; AND RETURN
                        ;
PFLT    STA M1+1        ; SAVE IN LOW ORDER
        LDA #$00        ; MAKE HIGH ORDER ZERO
        STA M1          ;
        JMP FLT16       ; * PJMP * AND FLOAT IT
                        ;
        ; 'FINDLN - FIND A LINE IN THE STORED PROGRAM'
                        ; 
        ; "FINDLN"  RETURNS WITH C=1 IF THE LINE WAS FOUND.
        ;           TXTAD2 POINTS TO THE GROUP NUMBER,
        ;           RETURNS WITH C=0 IF THE LINE WAS NOT LOCATED
        ;           TXTAD2 POINTS TO THE GROUP NUMBER OF THE NEXT HIGHEST NO.
        ;           (I.E., WHERE YOU WOULD INSERT THIS LINE)
                        ; 
FINDLN  LDA GRPNO       ; PLACE LINE NUMBER OF LINE WE ARE
        STA ITMP2H      ;   LOOKING FOR INTO TEMPORARY
        LDA LINENO      ; STEP PART ALSO
        STA ITMP2L      ;
        LDA #$00        ; SET FLAG INDICATING FIRST SEARCH
        STA FSWIT       ;
        STA TEXTP       ; ALSO RESET TEXT POINTER TO BEGINNING OF
        LDA PC          ;   CURRENT LINE. IS CURR LN DIRECT CMD?
        BPL CHKLIN      ; NO, THEN START SEARCHING FOR PRESENT POS
FNDINI  JSR TXTINI      ; YES, THEN RESET TEXT POINTERS TO START
        INC FSWIT       ;   OF PROGRAM, INDICATE LAST SEARCH
CHKLIN  LDY TEXTP       ; GET TEXT POINTER
        LDA (TXTADR),Y  ; GET THE GROUP NUMBER
        CMP #EOP        ; END OF TEXT?
        BEQ NOFIND      ; BRANCH IF YES
        STA ITMP1H      ; SAVE FOR COMPARISON
        STA TGRP        ; ALSO SAVE IN CASE THIS ONE IS IT
        INY             ; POINT TO STEP NUMBER
        LDA (TXTADR),Y  ; GET IT
        STA ITMP1L      ; SAVE IT FOR COMPARISON
        STA TLINE       ; ALSO SAVE IN CASE THIS IS IT
        INY             ; POINT TO FIRST CHAR IN LINE
        STY TEXTP       ; UPDATE TEXT POINTER
        SEC             ; SET UP FOR SUBTRACT
        LDA ITMP1L      ; GET LOW ORDER
        SBC ITMP2L      ;
        STA ITMP1L      ; SAVE FOR LATER
        LDA ITMP1H      ; NOW HIGH ORDERS
        SBC ITMP2H      ;
        BMI FNEXT       ; BRANCH IF THE ONE IN THE TEXT AREA IS <
        ORA ITMP1L      ; NOT BIGGER, IS IT EQUAL?
        BEQ FOUNDL      ; BRANCH IF WE LOCATE THE LINE
        LDA FSWIT       ; LAST SEARCH ATTEMPT?
        BEQ FNDINI      ; BRANCH IF NOT, TRY AGAIN FROM START OF
                        ;   PROGRAM
NOFIND  CLC             ; FLAG THE FACT WE DIDN'T FIND IT
FNEXIT  LDY #$00        ; RESET POINTER TO GROUP NUMBER
        STY TEXTP       ;
        RTS             ;
FNEXT   JSR EATCR       ; FLUSH TO START OF NEXT LINE
        BPL CHKLIN      ; UNCONDITIONALLY LOOP FOR MORE
FOUNDL  SEC             ; FLAG THE FACT WE FOUND IT
        BCS FNEXIT      ;   AND RETURN
                        ;
        ; UTILITY ROUTINES FOR TEXT MANIPULATION
                        ;
        ; FLUSH UNTIL A CARRIAGE RETURN
                        ;
EATCR   INC DEBGSW      ; DISABLE TRACE
EATCRC  JSR GETC        ; GET NEXT CHAR
        BPL EATCNT      ; UNCONDITIONAL BRANCH
EATCR1  INC DEBGSW      ; DISABLE TRACE
EATCNT  LDA CHAR        ; GET THE CHAR
        CMP #$0D        ; 'CR' ?
        BNE EATCRC      ; BRANCH IF NOT
        LDA TXTADR      ; YES, CALCULATE THE START OF NEXT LINE
        CLC             ;
        ADC TEXTP       ; ADD IN THE TEXT POINTER
        STA TXTADR      ; SAVE IN POINTER
        STA TXTAD2      ;   AND ALTERNATE POINTER
        LDA TXTADR+1    ; NOW HIGH ORDER
        ADC #$00        ;
        STA TXTADR+1    ;
        STA TXTAD2+1    ; AND ALTERNATE POINTER
        LDA #$00        ; AND RESET THE POINTER
        STA TEXTP       ;
        STA TEXTP2      ;
        DEC DEBGSW      ; ALLOW TRACE AGAIN
        RTS             ;   AND RETURN
                        ;
        ; FLUSH UNTIL END OF COMMAND (SEMI-COLON OR CARRIAGE RETURN)
                        ;
EATEC1  JSR GETC        ; GET NEXT CHAR
        BPL EATECC      ; UNCONDITIONAL BRANCH
EATECM  INC DEBGSW      ; TURN OFF TRACE
EATECC  LDA CHAR        ; GET THE CHAR
        JSR TSTEOC      ; GO SEE IF ';' OR CARRIAGE RETURN
        BNE EATEC1      ; BRANCH IF NOT
        DEC DEBGSW      ; ENABLE TRACE AGAIN
        RTS             ;   AND RETURN
                        ;
        ; PUSH THE TEXT POINTERS ON THE STACK
                        ;
PUSHTP  LDX #TXTADR     ;
        LDY #$04        ; THREE PLUS 'CHAR'
        JMP PUSHB0      ; * PJMP *
                        ;
        ; POP THE TEXT POINTERS OFF THE STACK
                        ;
POPTP   LDX #TXTADR+3   ;
        LDY #$04        ;
        JMP POPB0       ; * PJMP *
                        ;
        ; INIT TEXT POINTER TO BEGINNING OF TEXT
                        ;
TXTINI  LDA TXTBEG      ; POINT TO START OF STORED TEXT
        STA TXTADR      ;
        LDA TXTBEG+1    ;
        STA TXTADR+1    ;
        LDA #$00        ; INIT OFFSET TO ZERO
        STA TEXTP       ;
        RTS             ;
                        ;
        ; 'NEWLIN' SETUP TEXT POINTERS AND PC FOR NEW LINE NUMBER
                        ;
NEWLIN  LDA GRPNO       ; GET THE LINE NUMBER
        STA PC          ; STORE IN THE PROGRAM COUNTER
        LDA LINENO      ;
        STA PC+1        ;
        LDY #$02        ; POINT TO FIRST CHAR 0N LINE
        STY TEXTP       ;
        RTS             ; AND RETURN
                        ;
        ; 'NXTLIN' SETUP TEXT POINTERS AND PC FOR NEXT LINE NUMBER
                        ;
NXTLIN  LDY TEXTP       ; GET TEXT POINTER
        LDA (TXTADR),Y  ; PICK UP GROUP NUMBER
        CMP #EOP        ; END OF PROGRAM?
        BEQ NONEXT      ; BRANCH IF NO NEXT LINE
        STA PC          ; SAVE AS NEW LINE NUMBER
        INY             ;
        LDA (TXTADR),Y  ; GET STEP NUMBER
        STA PC+1        ; STORE IT
        INY             ; POINT TO FIRST CHAR ON THE LINE
        STY TEXTP       ;
        JSR GETC        ; GET THE FIRST CHAR OF NEW LINE
        SEC             ; FLAG THE FACT WE HAVE A NEW LINE
        RTS             ;   AND RETURN
NONEXT  CLC             ; INDICATE WE HAVE NO NEW LINE
        RTS             ;   AND RETURN
                        ;
        ; 'DELETE' A LINE OF STORED PROGRAM
                        ;
DELETE  JSR PUSHTP      ; SAVE TEXT POINTERS
        LDY #$02        ; SKIP OVER LINE NUMBER
        STY TEXTP       ;
        JSR EATCR       ; SKIP TO THE CARRIAGE RETURN
        JSR POPTP       ; RESTORE POINTER TO START OF LINE TO ZAP
        JSR PUSHTP      ;   BUT KEEP THEM AROUND
        LDY #$00        ; SET OFFSET TO ZERO
DMVLOP  LDA (TXTAD2),Y  ; GET A CHAR
        STA (TXTADR),Y  ; MOVE IT DOWN
        CMP #EOP        ; END OF TEXT REACHED YET?
        BEQ DELDON      ; BRANCH IF YES
        INY             ; NO, POINT TO NEXT CHAR TO MOVE
        BNE DMVLOP      ; BRANCH IF NO OVERFLOW ON OFFSET
        INC TXTADR+1    ; OVERFLOW, BUMP HIGH ORDERS
        INC TXTAD2+1    ;
        BNE DMVLOP      ; UNCONDITIONALLY MOVE NEXT BYTE
DELDON  INY             ;
        STY TEXTP       ; SAVE OFFSET
        LDA TXTADR      ; GET BASE ADDR
        CLC             ;
        ADC TEXTP       ; ADD IN THE OFFSET
        STA VARBEG      ; SAVE AS START OF VARIABLE LIST
        LDA TXTADR+1    ; GET HIGH ORDER
        ADC #$00        ; ADD IN THE CARRY
        STA VARBEG+1    ; SAVE IT
        JSR INSDON      ; FLAG VARIABLE LIST AS EMPTY
        JMP POPTP       ; * PJMP * RESTORE POINTERS TO POINT TO
                        ;   WHERE WE WOULD INSERT LINE.
                        ;
        ; 'INSERT' A LINE IN THE STORED PROGRAM TEXT AREA
                        ;
INSERT  JSR PUSHTP      ; SAVE TEXT POINTERS ACROSS CALL
        JSR FINDLN      ; TRY TO LOCATE THE LINE
        BCC INSCNT      ; BRANCH IF LINE DOES NOT EXIST
        JSR DELETE      ; LINE EXISTS, DELETE IT
        JSR FINDLN      ; RE-FIND TO SET UP POINTERS AGAIN
INSCNT  JSR POPTP       ; GET COMBUF POINTERS BACK
        DEC TEXTP       ; POINT TO THE LINE NUMBER DELIMITER
        JSR PUSHTP      ;   BUT KEEP THEM AROUND
        LDX #TXTAD2     ; SAVE POINTER TO PLACE TO INSERT
        LDY #$04        ;   ON STACK
        JSR PUSHB0      ;
        LDX #$02        ; SET COUNTER FOR 3 BYTES MINIMUM
IFCR    INX             ; COUNT THIS BYTE
        JSR GETC        ; GET IT FROM COMMAND BUFFER
        CMP #$0D        ; 'CR' ?
        BNE IFCR        ; NO, KEEP COUNTING
        STX TEMP1       ; SAVE COUNTER TEMPORARILY
        LDY #$00        ; OFFSET TO ZERO
        LDA (TXTAD2),Y  ; GET THE LAST CHAR TO SLIDE DOWN
        PHA             ; SAVE FOR LATER
        LDA #UMARK      ; FLAG THE LOC WITH ALL ONES
        STA (TXTAD2),Y  ;
        LDA VARBEG      ; GET ADDR OF START OF VARIABLE LIST
        STA TXTADR      ; SAVE FOR LATER
        CLC             ;
        ADC TEMP1       ; ADD IN AMOUNT TO MOVE DOWNWARD
        STA TXTAD2      ; SAVE FOR LATER
        STA VARBEG      ; SAVE AS NEW START OF VARIABLE LIST
        LDA VARBEG+1    ; NOW HIGH ORDER
        STA TXTADR+1    ;
        ADC #$00        ;
        STA TXTAD2+1    ;
        STA VARBEG+1    ; AND FALL INTO MOVE LOOP
IMVLOP  LDA (TXTADR),Y  ; PICK UP A BYTE
        CMP #UMARK      ; END OF MOVE?
        BEQ IMVDON      ; BRANCH IF YES
        STA (TXTAD2),Y  ; NO, THEN SLIDE IT DOWN
        DEY             ; DECREMENT OFFSET?
        CPY #$FF        ; OVERFLOW?
        BNE IMVLOP      ; BRANCH IF NOT
        DEC TXTADR+1    ; OVERFLOW, BUMP HIGH ORDER
        DEC TXTAD2+1    ;   ADDRESSES
        BNE IMVLOP      ; UNCONDITIONALLY LOOP FOR MORE
IMVDON  PLA             ; GET THE LAST BYTE BACK AGAIN
        STA (TXTAD2),Y  ; STORE IT AWAY
        JSR POPTP       ; RESTORE POINTERS TO PLACE TO INSERT
        LDX #TXTAD2+3   ; RESTORE POINTERS TO COMBUF
        LDY #$04        ;
        JSR POPB0       ;
        LDY TEXTP       ; GET OFFSET
        LDA GRPNO       ; GET THE GROUP NUMBER
        STA (TXTADR),Y  ; STRORE IT IN PROGRAM AREA
        INY             ;
        LDA LINENO      ; GET THE STEP NUMBER
        STA (TXTADR),Y  ; STRORE IT IN PROGRAM AREA
        INY             ; POINT TO WHERE FIRST CHARACTER GOES
        STY TEXTP       ; SAVE IT FOR LATER
INSLOP  LDY TEXTP2      ; GET POINTER TO CHAR
        LDA (TXTAD2),Y  ; PICK IT UP
        INY             ; BUMP IT
        STY TEXTP2      ; STORE IT BACK
        LDY TEXTP       ; POINT TO WHERE IT GOES
        STA (TXTADR),Y  ; PUT IT THERE
        CMP #$0D        ; CARRIAGE RETURN YET?
        BEQ INSDON      ; BRANCH IF YES
        INY             ; NO, POINT TO NEXT
        STY TEXTP       ; SAVE POINTER
        BNE INSLOP      ; UNCONDITIONALLY LOOP FOR MORE
INSDON  LDY #$00        ; OFFSET TO ZERO
        LDA #EOV        ; FLAG VARIABLE LIST AS EMPTY
        STA (VARBEG),Y  ;
        LDA VARBEG      ; AND UPDATE 'VAREND'
        STA VAREND      ;
        LDA VARBEG+1    ;
        STA VAREND+1    ;
        RTS             ; AND RETURN
                        ;

; *** BEGIN AZIN67 SECTION (COMPLETED BY DAVE. H)

; 
; 
;           'SOFTWARE STACK MANIPULATION ROUTINES'
; 
; "PUSHJ" - PUSH-JUMP TO A ROUTINE
; 
; CALLING SEQUENCE IS:
; 
; JSR  PUSHJ	; CALL THIS SUBROUTINE
; .WORD ROUTINE	; TWO BYTE ADDR OF ROUTINE TO GO TO
;               ; *** NOTE! THIS WORD CANNOT OVERLAP
;               ; *** A PAGE BOUNDARY.
;        <----- ; RETURN IS HERE VIA "POPJ" ROUTINE
; 
; *** this routine has self-modifying code at $282F.
;     (I'm unsure how to write this in 'modern' assembly) --dhh
; 
PUSHJ     PLA		; GET LOW ORDER RETURN ADDR FROM STACK
          TAY		; PLACE IN Y REGISTER
          INY		; INCREMENT TO GET LOW ORDER TO JUMP INDIR
          STY PJADR1	; STORE IN JUMP INDIRECT INSTRUCTION
          INY		; BUMP FOR THE RTS IN "POPJ"
          TYA		; PLACE IN ACCUMULATOR
          JSR PUSHA	; SAVE ON STACK FOR LATER
          PLA		; GET HIGH ORDER RETURN ADDR
          STA PJADR1+1	; STORE IN JUMP INDIRECT INSTRUCTION
          JSR PUSHA	; SAVE FOR LATER RETURN VIA "POPJ"
          JMP ($0000)	; ADDR IS OVERWRITTEN FROM ABOVE CODE
            		; THIS JUMP WILL GO TO "ROUTINE".
; 
; "PUSHA" - PUSH THE ACCUMULATOR ON THE SOFTWARE STACK
; 
; CALLING SEQUENCE IS:
; JSR  PUSHA
; 
PUSHA     LDY PDP	; GET THE SOFTWARE STACK POINTER
          STA (PDPADR),Y	; STORE THE ACC VIA POINTER
          DEY		; DECREMENT THE SOFT STACK POINTER
          CPY #$FF	; IS NEW VALUE $FF ?
          BNE PUSHRT	; NO, THEN BASE ADDR IS OK
          DEC PDPADR+1	; YES, DEC BASE ADDR BY ONE
PUSHRT    STY PDP	; STORE UPDATED POINTER
          RTS		; AND RETURN
; 
; "POPA" - POP ITEM OFF SOFTWARE STACK INTO THE ACCUMULATOR
; 
; CALLING SEQUENCE IS:
; JSR  POPA
; 
POPA      LDY PDP	; load software stack pointer
          INY		; increment so it points to new item
          BNE PHOK	; branch if high-order base addr is OK
          INC PDPADR+1	; if not OK, increment by one page
PHOK      LDA (PDPADR),Y	; get item from soft stack
          STY PDP	; store updated pointer
          RTS		; and return
; 
; "POPJ" - RETURN TO ADDRESS SAVED BY A CALL TO "PUSHJ"
; 
; CALLING SEQUENCE IS:
; JSR  POPJ
; 
POPJ      TSX		; load X w/ hw stack pointer
          JSR POPA	; get hi order addr to ret to
          STA STACK+2,X	; overwrite return addr
          JSR POPA	; get lo order byte to ret to
          STA STACK+1,X	; overwrite return addr
          RTS		; return to proper place, past
                        ;   JSR PUSHJ and .WORD routine
                        ; SEQUENCE --->
; 
; "POPB0"  pop bytes off of stack into zero page
; 
POPB2     LDY #$02	; entry point when we need 2 bytes only
POPB0     STY TEMP1	; save Y register
          JSR POPA	; get a byte from stack
          STA $00,X	; store it in zero page
          LDY TEMP1	; get Y register back
          DEX		; count X down
          DEY		; done yet?
          BNE POPB0	; loop for more
          RTS		; yes, return
; 
; "PUSHB0"  push bytes from page zero onto stack   
; 
PUSHB2    LDY #$02	; entry point, 2 bytes only
PUSHB0    STY TEMP1	; save Y
          LDA $00,X	; get value from Z Pg
          JSR PUSHA	; save on stack
          LDY TEMP1	; get Y back
          INX		; next byte
          DEY		; done yet?
          BNE PUSHB0	; loop if >0
          RTS		; return
; 
; PUSH AND POP F.P. NUMBERS
; 
; PUSH FAC1 ONTO STACK
; 
PHFAC1    LDX #$FB	; get neg of num of bytes to push
PHF1B     LDA $85,X	; get a byte of number
          JSR PUSHA	; push onto software stack
          INX		; point to next one
          BMI PHF1B	; loop til all pushed
          RTS               
; 
; PUSH FAC2 ONTO STACK
; 
PHFAC2    LDX #$FB	; get neg of num of bytes to push
PHF2B     LDA $80,X	; get a byte of number
          JSR PUSHA	; etc
          INX
          BMI PHF2B
          RTS
; 
; PUSH F.P. TEMP ONTO STACK
; 
PHTMP     LDX #$FB	; get neg of num of bytes to push
PHTB      LDA $A5,X	; get a byte of number
          JSR PUSHA	; etc
          INX
          BMI PHTB
          RTS
; 
; POP NUMBER ON STACK INTO FAC2
; 
PLFAC2    LDX #$04	; point to last byte
PLF2B     JSR POPA	; pop item from stack into ACC
          STA X2,X	; store into FAC2
          DEX		; point to next byte
          BPL PLF2B	; loop until all popped 
          RTS
; 
; POP NUMBER ON STACK INTO F.P. TEMP
; 
PLTMP     LDX #$04	; point to last byte
PLTB      JSR POPA	; get item from stack into ACC
          STA $A0,X	; store in temp area
          DEX		; point to next byte
          BPL PLTB	; loop til done
          RTS
; 
;           'CHARACTER MANIPULATING ROUTINES'
; 
; READ ONE CHARACTER WITH NO ECHO
; 
RNOECH    LDA ECHFLG	; get echo ctrl flag
          PHA		; save on stack
          LDA #$01	; no disable echo
          STA ECHFLG
          JSR READC	; get a char from input device
          TAX		; save char into X
          PLA		; get old echo flag value back
          STA ECHFLG
          TXA		; get the char input
          RTS
; 
; "READC" - READ ONE CHARACTER FROM INPUT DEVICE
; 
READC     LDX IDEV	; GET CURRENT INPUT DEVICE NUMBER
          BPL READC1	; BRANCH IF DEVICE NUMBER IS POSITIVE
          JMP RSTRNG	; * PJMP * NEG, READ FROM STRING AND RET
READC1    LDA IDSPH,X	; GET HIGH ORDER DISPATCH ADDRESS
          STA TEMP1+1	; STORE IT AWAY
          LDA IDSPL,X	; GET LOW ORDER
          STA TEMP1	; STORE IT AWAY
          JSR JSRIND	;   AND CALL THE INPUT ROUTINE
          BCC READCC	; BRANCH IF NO ERRORS
IERRI     JSR CLRDEV	; RESET DEVICES ON AN I-O ERROR
          BRK		; TRAP
          .BYTE ERRI	; ?I-O ERROR ON INPUT DEVICE (#$E9)
READCC    STA CHAR	; SAVE CHAR
          CMP #$7F	; here the Aresco code differs from the
          BEQ RTS1	; ProgExch/6502Grp original. Was only a
          CMP #$5F	; test for CR, but now testing for RUBOUT,
          BEQ RTS1	; LF and CXL LINE.
          CMP #$0A	;   --dhh
          BEQ RTS1
          LDA ECHFLG	; ECHO FLAG
          BEQ READCE
READCR    LDA CHAR	; GET CHAR BACK
          RTS

READCE    LDA CHAR	; this is also not in original ProgExch code...
          JSR PRINTC
          CMP #$0D
          BNE RTS1	; ... to here. Next line was label READCE
          LDA #$0A	; FOLLOW CARRIAGE RETS WITH A LINE FEED
          JSR PRINTC	; PRINT IT
          BPL READCR	; UNCONDITIONAL BRANCH
; 
; PRINTC - PRINT THE CHAR IN ACCUMULATOR OR 'CHAR'
; 
PSPACE    LDA #$20	; OUTPUT A SPACE
PRINTC    AND #$FF	; here we're testing for a null ($00),
          BNE PRNTC	; otherwise, routine branches to the
          LDA CHAR	; original ProgExch 'PRINTC'
PRNTC     PHA		; SAVE THE CHAR IN THE AC
          LDX ODEV	; GET CURRENT OUTPUT DEVICE NUMBER
          BPL PUSEA1	; BRANCH IF DEVICE NUMBER IS POSITIVE
      
       ; ProgExch source has a 'patch' here (literally pasted on!)
       ; covering the next six bytes:
       ; LDY STOPNT   ; get pntr to next char
       ; JMP WSTRNG   ; *PJMP* write to string
       ; NOP            ; patch fill

          JSR WSTRNG     
          JMP PRRET
PUSEA1    LDA ODSPH,X	; GET HIGH ORDER ADDR OF OUTPUT ROUTINE
          STA TEMP1+1	; SAVE IT
          LDA ODSPL,X	; GET LOW ORDER ADDR OF OUTPUT ROUTINE
          STA TEMP1	; SAVE IT
          PLA		; GET CHAR BACK
          PHA		; BUT SAVE ACROSS CALL
          JSR JSRIND	; CALL THE ROUTINE TO DO THE OUTPUT
          BCC PRRET	; BRANCH IF NO ERRORS
OEERO     JSR CLRDEV	; RESET I-O DEVICES IF ERROR
          BRK		; TRAP
          .BYTE ERRO	; ?I-O ERROR ON OUTPUT DEVICE (#$DE)
PRRET     PLA		; RESTORE THE CHARACTER
          RTS		; AND RETURN
; 
; PACKC - PACK A CHAR INTO MEMORY
; 
PACKC     LDA CHAR	; get character
PACKC1    LDY TEXTP	; get text pointer
          CMP #$7F	; rubout?
          BEQ RUB1	; yes, branch
          CMP #LINCHR	; 'line delete' char?
          BEQ RUBLIN	; yes, branch
          STA (TXTADR),Y     ; store char to memory
PCKRUB    INY		; +1 text pointer
          CPY #$7F	; over max line length?
          BPL PBIG	; yes, branch
PCKRET    STY TEXTP	; save text pointer
RTS1      RTS		; and return
PBIG      BRK		; trap
          .BYTE LTL	; ?line too long
; 
; ROUTINE TO RUB OUT ONE CHARACTER
; 
RUB1      CPY #$00	; anything to rubout?
          BEQ PCKRET	; nope, branch
          LDY ECHFLG	; has user enabled character echo?
          BNE RUB1CC	; branch if disabled
          LDY DELSPL	; need special CRT rubout?          
          BEQ RUB1C	; branch if not
          JSR EATTVC	; yes, eat the char          
          BPL RUB1CC	; uncond. branch
RUB1C     LDA #$5C	; echo sp char '\' for rubout
          JSR PRNTC
RUB1CC    LDY TEXTP	; load Y with text pointer
          DEY		; -1
          BPL PCKRET	; RET if positive
          BMI PCKRUB	; if past beginning, set to 0
; 
; ROUTINE TO RUB OUT THE ENTIRE LINE
; 
;	*** this routine is visibly patched in the ProgExch code; Aresco code
;	    below is different.  -dhh
;
RUBLIN    CPY #$00	; anything to rubout?
          BEQ PCKRET	; branch if not
          LDY ECHFLG	; has user enabled char echo?
          BNE RUBLR	; branch if disabled
          LDY DELSPL	; need special CRT rubout proc?
          BEQ RUBLC	; branch if not
RUBLCL    JSR EATTVC	; eat a char off CRT screen
          DEC TEXTP	; zap it from buffer
          BNE RUBLCL	; loop til all zapped
          RTS     
RUBLC     LDA #$5F	; echo 'line del' character
          JSR PRNTC
RUBLR     LDY #$00	; reset text pointer
          BEQ PCKRET	; and RET
; 
; EAT A CRT CHAR WITH BS-SPC-BS SEQUENCE
; 
EATTVC    JSR BACKSP	; output a BS
          JSR PSPACE	; followed by a space
BACKSP    LDA #$08	; get BS char
          JMP PRINTC	; * PJMP * output it and return
; 
; 'GETC' GET A CHAR FROM MEMORY, ECHO IF TRACE ON
; 
GETCX     LDY DEBGSW	; is trace disabled?
          BNE GETC1	; yes, don't look at flag
          LDA DMPSW	; flip state of the dump switch
          EOR #$FF
          STA DMPSW	; and store it back
GETC      LDA INSW	; where do we get the char from?
          BEQ GETCC	; from memory
          JMP READC	; * PJMP * go get from input dev
GETCC     LDY TEXTP	; get text pointer
          INC TEXTP	; +1 to next char
          LDA (TXTADR),Y	; get it
          CMP #$3F	; is it '?'
          BEQ GETCX	; yes, go handle
GETC1     STA CHAR	; store away for others
          LDA DEBGSW	; check to see if we print it
          ORA DMPSW	; for debugging
          BNE GETRT1	; no
          JSR READCE	; print only if both are 0
GETRT1    LDA CHAR	; get char back
          RTS		; and RET
;
    ; the ProgramExchange/6502Group code has a 'patch'
    ; over GETC1:
    ; GETC1     STA CHAR     ; STORE IT
    ;           PHA          ; SAVE ON STACK
    ;           LDA DEBGSW     ; DO WE PRINT IT?
    ;           ORA DMPSW     ; FOR DEBUGGING
    ;           BNE TESTN+7     ; NO
    ;           PLA          ; GET CHAR BACK
    ;           JSR TRACBG     ; FIX FOR TRACE BUG
    ;           RTS          ; CHAR IS RETURNED
; 
; 'SPNOR' ROUTINE TO IGNORE LEADING SPACES
; 
GSPNOR    JSR GETC	; CALL GETC FIRST
SPNOR     LDA CHAR	; GET THE CHAR
          CMP #$20	; IS IT A SPACE?
          BEQ GSPNOR	; YES, THEN IGNORE
          RTS		; NO, RETURN
; 
; "TESTN"  TESTS TO SEE IF CHARACTER IS A NUMBER
; 
TESTNS    JSR GSPNOR	; GET NEXT NON-BLANK
TESTN     LDA CHAR	; GET CHAR
TESTN1    PHA		; SAVE CHAR ON STACK
          EOR #$30	; CONVERT TO BCD (IF A NUMBER)
          CMP #$0A	; SET C BIT IF GREATER THAN 9
          PLA		; RETORE CHARACTER TO ACCUMULATOR
          RTS		; RETURN (C BIT CLEAR IF NUMBER)
; 
;           'EVAL' - EXPRESSION EVALUATOR
; 
; 'EVAL' - EVALUATE AN EXPRESSION (RECURSIVE)
; 
EFUN      LDA #$00	; GET A ZERO
EFUNL     ASL A		; ROTATE LEFT TO HASH
          STA ETEMP1	; SAVE IT
          JSR GETC	; GET NEXT CHARACTER OF FUNCTION NAME
          JSR TTERMS	; TERMINATOR?
          BEQ EFNAME	; BRANCH IF END OF NAME
          AND #$1F	; KEEP ONLY 5 BITS
          CLC
          ADC ETEMP1	; ADD IN THE HASH
          BNE EFUNL     ; UNCONDITIONALLY LOOP FOR MORE
EFNAME    CMP #$28	; '(' LEFT PAREN?
          BEQ EFUNC     ; BRANCH IF YES
          BRK		; TRAP
          .BYTE PFERR	; ?PARENTHESES ERROR IN FUNCTION
EFUNC     LDA ETEMP1	; GET THE HASH CODE FOR FUNCTION NAME
          JSR PUSHA     ; SAVE FOR LATER
          JSR PUSHJ     ; MOVE PAST PAREN, EVALUATE 1ST ARGUMENT
          .BYTE $3,$2A
          JSR POPA	; GET THE NAME BACK AGAIN
          TAX		; TRANSFER TO X REGISTER
          JSR PUSHJ     ; AND GO DO THE FUNCTION
          .WORD	EVALM1
          JMP ERPAR     ; GO SEE IF TERMINATOR IS A RIGHT PAREN.
; 
; HERE FOR A QUOTED CONSTANT
; 
ECHAR     JSR GETC	; GET CHARACTER FOLLOWING QUOTE
          JSR FLT8	; AND MAKE IT A FLOATING POINT NUMBER
          JSR GETC	; MOVE PAST CHARACTER
          JMP OPNEXT	; AND CHECK FOR OPERATOR
; 
; *** MAIN ENTRY POINT(S) TO 'EVAL' ***
; 
EVALM1    JSR GETC	; ENTER HERE TO GET PAST CURRENT CHARACTER
EVAL      LDA #$00	; ASSUME LOWEST LEVEL ARITHMETIC OPERATION
          STA LASTOP
          STA STRSWT	; MAKE SURE STRING VAR SWITCH IS OFF
          JSR ZRFAC1	; ASSUME VALUE OF EXPRESSION IS ZERO
ARGNXT    LDA LASTOP	; SAVE LAST OPERATION ON STACK
          JSR PUSHA
          JSR TTERMS	; GO SEE IF THIS CHARACTER IS A TERMINATOR
          BNE ECHKC	; BRANCH IF NOT
          JMP ETERM1	; YES, THEN HANDLE
ECHKC     CMP #$46	; 'F' IS IT A FUNCTION?
          BEQ EFUN	; BRANCH IF YES
          CMP #$27	; ''' IS IT A CHARACTER CONSTANT?
          BEQ ECHAR     ; BRANCH IF YES
          CMP #$2E	; '.' IS IT A FRACTION?
          BEQ ENUM	; BRANCH IF YES, CALL FLOATING P. ROUTINE
          JSR TESTN1	; NO, BUT IS IT A NUMBER?
          BCS EGTVAR	; BRANCH IF NOT A NUMBER
              ; *** START OF KLUDGE HACK
              ;     TO SPEED THINGS UP ***
          LDA INSW	; ARE WE INPUTTING FROM INPUT DEVICE?
          BNE ENUM	; BRANCH IF YES, CALL FLOAT PT ROUTINE
          LDX #$02	; NO, THEN WE CAN LOOK AHEAD TO SEE IF
          LDY TEXTP     ;   CONSTANT IS IN RANGE 0-99
KLOOP     LDA (TXTADR),Y	; GET NEXT CHAR
          INY		; BUMP POINTER
          CMP #$2E	; '.' DOES NUMBER HAVE A FRACTIONAL PART
          BEQ ENUM	; BRANCH IF IT DOES, CALL F.P. ROUTINE
          JSR TESTN1	; IS THIS CHAR A DIGIT 0-9 ALSO?
          BCS FSTNUM	; BRANCH IF NOT, THEN CALL FAST INPUT
          DEX		; CAN ONLY HAVE UP TO TWO DIGITS
          BNE KLOOP     ; LOOK AT NEXT ONE
                        ; IF WE FALL OUT OF THE LOOP, WE HAVE TO
ENUM      JSR FINP	;   CALL FLOAT PT. INPUT ROUTINE (SLOW!)
          JMP OPNEXT	; AND LOOP FOR OPERATOR
FSTNUM    LDA CHAR	; GET FIRST DIGIT OF NUMBER
          JSR L2DC2     ; CALL FAST INPUT ROUTINE FOR #S 0-99
          JSR FLT8	; CALL FAST ONE-BYTE FLOAT ROUTINE
          JMP OPNEXT	;    AND LOOK FOR OPERATOR
		; *** END OF KLUDGE HACK ***
EGTVAR    JSR PUSHJ     ; IT MUST BE A VARIABLE, GET VALUE
          .WORD GETVAR	; or .WORD GETVAR
          LDA CHAR	; GET CHARACTER THAT TERMINATED THE VARIB
          CMP #$3D	; '=' DOES HE WANT SUBSTITUTION?
          BNE OPNEXT	; BRANCH IF NOT, JUST A TERM
          LDX #VARADR	; YES, THEN SAVE THE INFO ABOUT THIS VARIB
          LDY #$05
          JSR PUSHB0	;   ONTO THE STACK
          JSR PUSHJ     ; CALL OURSELVES TO EVAL THE EXPRESSION
          .WORD EVALM1	; or .WORD EVALM1
          LDX #VARADR+4	; RESTORE POINTERS TO VARIABLE
          LDY #$05
          JSR POPB0
          LDA STRSWT	; WAS THE VARIABLE A STRING VARIABLE?
          BNE SETSTR	; BRANCH IF IT WAS
          JSR PUTVAR	; NO, THEN STORE EXPRESS VALUE AS VARIB'S
          BEQ OPNEXT	;   VALUE - IS ALSO VALUE OF THIS TERM
SETSTR    JSR INTGER	; KEEP ONLY 8 BITS FOR VALUE
          LDY VSUB+1	; POINT TO POSITION IN STRING
          STA (VARADR),Y	; STORE IT INTO $, FALL INTO...
OPNEXT    JSR TTERMS	; GO SEE IF NEXT NON-SPACE IS SPECIAL
          BNE MISOPR	; BRANCH IF NOT
          CPX #$06	; LEFT PAREN?
          BNE OPNXT1	; NO, THAT'S GOOD AS WE CAN'T HAVE 1 HERE
MISOPR    BRK		; TRAP TO ERROR HANDLER
          .BYTE OPRMIS	; ?OPERATOR MISSING - EVAL
JARGN     JMP ARGNXT	; BRANCH AID
EVALRT    JSR POPJ	; RETURN FROM CALL TO "EVAL"

OPNXT1    CPX #$07	; IS THIS A DELIMITER?
          BMI OPNXT2	; BRANCH IF NOT
          LDX #$00	; YES, THEN THE OPERATION LEVEL IS LOWEST
OPNXT2    JSR POPA	; GET LAST OPERATION LEVEL
          STA TEMP1     ; SAVE IT FOR COMPARE
          CPX TEMP1     ; IS THIS OPER LVL < OR = TO LAST ONE?
          BMI DOBOP     ; BRANCH IF YES
          BNE ESTACK	; BRANCH IF NO
DOBOP     ORA #$00	; TO RESET FLAGS AFTER CPX
          STA LASTOP	; YES, THEN GET THE LAST OPERATOR
          BEQ EVALRT	; IF LOWEST LEVEL, THEN WE ARE ALL DONE
          TXA		; SAVE 'THISOP'
          PHA		; ON HARDWARE STACK
          JSR PLFAC2	; POP PARTIAL RESULT BACK INTO FAC2
          JSR EVBOP     ; AND GO DO THE OPERATION LEAVING THE
			;   RESULT IN FLAC
          PLA		; GET 'THISOP' BACK
          TAX
          BPL OPNXT2	; UNCOND. BRANCH WITH NEW PARTIAL RESULT.

ESTACK    JSR PUSHA	; SAVE BACK ON STACK FOR LATER COMPUTATION
          STX LASTOP	; NOW UPDATE 'LASTOP' TO 'THISOP'
          JSR PHFAC1	; SAVE PARTIAL RESULT ON STACK
          JSR GETC	; SKIP OVER THE OPERATOR
          BPL JARGN	; UNCOND. BRANCH TO PICK UP NEXT ARGUMENT
ETERM1    CPX #$06	; LEFT PAREN?
          BNE ETERM2	; BRANCH IF NOT
          JSR PUSHJ	; ENTERING NEW LEVEL OF NESTING, SO CALL
          .WORD EVALM1	; OURSELVES TO EVALUATE IT!
ERPAR     LDA CHAR	; GET THE DELIMITER THAT ENDED THIS LEVEL
          PHA		; SAVE IT MOMENTARILY
          JSR GETC	; MOVE PAST IT
          PLA		; GET DELIMITER BACK
          CMP #$29	; ')' RIGHT PAREN?
          BEQ OPNEXT	; YES. GO PICK UP NEXT OPERATOR
EPMISS    BRK		; TRAP TO ERROR HANDLER
          .BYTE PMATCH	; ?PARENTHESIS MISMATCH - EVAL
ETERM2    CPX #$07	; DELIMITER ON RIGHT-HAND SIDE?
          BPL ETERM3	; BRANCH IF YES
          CPX #$03	; OR UNARY OPERATOR
          BPL MISOPN	; NO, THEN IT CAN'T BE HERE
ETERM3    LDA LASTOP	; PICK UP OPERATION LEVEL
          BEQ OPNXT1	; ONLY ALLOW IF AT LOWEST LEVEL
MISOPN    BRK		; TRAP TO ERROR HANDLER
          .BYTE OPNMIS	; ?OPERAND MISSING - EVAL

EVBOP     LDX LASTOP	; GET THE ARITHMETIC OPERATION TO PERFORM
          LDA EVDSPH,X	; GET THE HIGH-ORDER ADDR OF ROUTINE
          STA TEMP1+1	; STORE IT
          LDA EVDSPL,X	; GET THE LOW-ORDER ADDR OF ROUTINE
          STA TEMP1	; STORE IT
          JMP ($005F)	; * PJMP * TO ROUTINE TO DO THE OPERATION
; 
; 
;           EVALUATE A POWER
; 
; *** NOTE: THIS ROUTINE IS CURRENTLY RESTRICTED TO RAISING
;           THE NUMBER TO AN INTEGER POWER WITHIN THE RANGE
;           OF + OR - 32,767          (label: EVPOWR)
; 
          JSR INTFIX	; GET EXPONENT
          STA ITMP1L	; STORE IT AWAY
          LDA M1+1	; AS NUMBER OF TIMES TO DO OPERATION
          STA ITMP1H
          LDX #FONE	; GET THE CONSTANT 1.0 INTO FAC1
          LDY #FAC1
          JSR MOVXY
          LDA ITMP1H	; RAISING TO A NEGATIVE POWER?
          BMI NPOWR	; BRANCH IF WE ARE
POWRLP    LDA #$FF	; POSITIVE POWER, ARE WE DONE YET?
          DEC ITMP1L
          CMP ITMP1L
          BNE POWR1	; BRANCH IF HIGH ORDER OK
          DEC ITMP1H	; DECREMENT HIGH ORDER
POWR1     CMP ITMP1H	; DONE YET?
          BEQ TTRET	; YES, THEN RETURN
          JSR PHFAC2	; NO, SAVE FAC2
          JSR FMUL	; NUMBER TIMES ITSELF (EXCEPT FIRST TIME)
          JSR PLFAC2	; RESTORE NUMBER TO FAC2
          JMP POWRLP	; AND KEEP MULTIPLYING
; 
; HERE IF RAISING TO A NEGATIVE POWER
; 
NPOWR     LDA ITMP1H	; DONE YET?
          BEQ TTRET     ; BRANCH IF ALL DONE
          INC ITMP1L	; NO, THEN COUNT UP SINCE COUNT IS NEG.
          BNE NPOWR1
          INC ITMP1H	; INCREMENT HIGH ORDER ALSO
NPOWR1    JSR SWAP	; PUT PARTIAL INTO FAC2, 'X' INTO FAC1
          JSR PHFAC1	; SAVE 'X'
          JSR FDIV	; 1/(X*X*X*X...)
          JSR PLFAC2	; RESTORE 'X'
          JMP NPOWR     ; AND LOOP TILL DONE
; 
;           'ROUTINES USED BY "EVAL" '
; 
; TEST TO SEE IF CHARACTER IS A SPECIAL TERMINATOR
; 
TTERMS    JSR SPNOR     ; IGNORE SPACES, GET NEXT NON-BLANK CHAR
          LDX #$0C	; GET MAX TABLE OFFSET; 'trmax in ProgExch code'
TRMCHK    CMP TRMTAB,X	; MATCH?
          BEQ TTRET	; YES, RETURN WITH Z=1
          DEX		; POINT TO NEXT ENTRY
          BPL TRMCHK	; AND CHECK IT
TTRET     RTS		; RETURN (NOTE: Z=0 IF CANNOT FIND)
; 
;           'GETVAR' - GET A VARIABLE FROM VARIABLE LIST
; 
; "GETVAR" - GET A VARIABLE FROM THE VARIABLE LIST
;            OTHERWISE CREATE IT AND ASSIGN IT A VALUE OF ZERO
; 
GPMISS    JMP EPMISS	; BRANCH AID
GTERR3    BRK		; TRAP
          .BYTE FUNILL	; ?FUNCTION ILLEGAL HERE
GETVAR    LDA #$00	; ASSUME VARIABLE IS NOT A STRING
          STA STRSWT
          JSR SPNOR	; (DEFENSIVE!) GET THE CHARACTER
          CMP #$26	; '&' IS IT SPECIAL 'FSBR' SCRATCH VARIB?
          BEQ VAROK	; YES, THEN NAME IS OK
          CMP #$41	; 'A' IS IT ALPHABETIC?
          BMI VARBAD	; BRANCH IF NOT
          CMP #$5B	; '[' Z+1
          BMI VAROK     ; BRANCH IF ALPHABETIC
VARBAD    BRK		; NOT ALPHABETIC
          .BYTE BADVAR	; ?BAD VARIABLE NAME
VAROK     CMP #$46	; 'F' FUNCTION?
          BEQ GTERR3	; BRANCH IF YES
          ASL A
          ASL A
          ASL A		; SHIFT ALPHA LEFT 3
          PHA		; SAVE IT
          JSR GETC	; GET NEXT CHARACTER
          EOR #$30	; CONVERT TO BCD IF A NUMBER
          CMP #$08	; IS IT 0-7?
          BCS VARDUN	; IF NOT, NAME IS ON STACK
          STA VCHAR	; IF YES, SAVE IT
          PLA		; GET BACK ALPHA PART
          ORA VCHAR	; PUT THE PARTS TOGETHER
          PHA		; AND STICK ON STACK
          JSR GETC	; GET A NEW CHARACTER IN CHAR
; 
; 
; X X X X X X X X X X X X X X X X X X X X X X X X X X X
;
; *** here begins transcription work done by Nils Andreas (2023)
; 
; 


VARDUN    LDA CHAR
          CMP #$24	; '$' STRING VARIABLE?
          BNE VARDN1	;BRANCH IF NOT, PRESS ON
          STA STRSWT	;YES, FLAG THE FACT
          JSR GETC	;AND MOVE TO THE '3'
VARDN1    PLA		;GET VARIABLE OFF STACK
          JSR PUSHA	;PUT NAME ON SOFT STACK
          JSR SPNOR	;GET NEXT NON-BLANK
          CMP #$28	; '(' LEFT PAREN?
          BEQ VARSUB	;BRANCH IF VARIABLE HAS A SUBSCRIPT
          LDA #$00	;OTHERWISE ASSUME 0
          STA VSUB+1	;ZERO THE SUBSCRIPT
          BEQ VARSOK	;AND PROCESS IT
VARSUB    LDA STRSWT	;SAVE STRING FLAG
          JSR PUSHA
          JSR PUSHJ	;CALL EAVL TO CALCULATE SUBSCRIPT
          .WORD EVALM1          
          JSR POPA	;RESTORE STRING FLAG
          STA STRSWT
          LDA CHAR	;GET TERMINATOR
          CMP #$29	; ')' PAREN MATCH?
          BNE GPMISS	;BRANCH IF NOT
          JSR GETC	;MOVE PAST THE RIGHT PAREN (TYPO?)
          JSR FIX	;MAKE SUBSCRIPT AN INTEGER
          LDA X1+3	;GET LOW ORDER BYTE
          STA VSUB+1	;STORE IT
          LDA X1+2	;GET HIGH ORDER BYYTE (NOTE:16 BIT)
VARSOK    STA VSUB	;SAVE FOR LATER
          JSR POPA	;GET THE VARIABLE NAME BACK
          STA VCHAR	;SAVE IT
FNDVAR    JSR VARINI	;SET ADDR TO START OF VARIABLE LIST
CHKVAR    LDY #$00	;SET OFFSET TO ZERO
          LDA(VARADR),Y	;GET THE VARIABLE NAME
          CMP #EOV	;IS THIS THE END OF THE VARIABLE LIST?     
          BEQ NOVAR	;BRANCH IF END OF LIST
          CMP #STRMRK	;IS THIS VARIABLE IN THE LIST A STRING VARIABLE?
          BEQ CHKSTR	;BRANCH IF YES, WE HANDLE DIFFERENTLY
          CMP VCHAR	;ARE THE NAMES THE SAME
          BEQ CHKSUB	;YES, GO SEE IF THE SUBSCRIPTS ARE EQUAL
NOTVAR    JSR NXTVAR	;POINT TO NEXT VARIABLE IN LIST
          BNE CHKVAR	;UNCONDITIONAL BRANCH TO CHECK NEXT VARIABLE
CHKSTR    LDA STRSWT	;ARE WE LOOKING FOR A STRING VARIABLE?
          BEQ SKPSTR	;BRANCH IF NOT, JUST SKIP OVER THIS STRING VARIB
          LDA VCHAR	;YES, THEN GET IT'S NAME
          INY		;POINT TO NAME OF STRING VARIABLE IN VAR LIST 
          CMP(VARADR),Y	;IS THIS THE ONE WE ARE LOOKING FOR?
          BNE SKPST1	;BRANCH IF NOT, JUST SKIP IT OVER
          INY		;YES, THIS IS THE ONE, GET THE SIZE OF THE
          LDA(VARADR),Y	;STRING
          STA VSIZE	;STORE FOR THOSE WHO NEED IT
          INY		;AND UPDATE
          TYA
          JSR UPDVAR	;'VARADR' TO POINT TO BASE ADDR OF STRING
GETSTC    LDY VSUB+1	;GET SUBSCRIPT (POSITION) OF BYTE WE WANT
          LDA(VARADR),Y	;GET THE BYTE WE WANT
          STA M1+1	;STORE AS LOW ORDER 8 BITS
          LDA #$00
          STA M1	;ZERO HIGH ORDER
          JMP FL16PJ	;*PJMP* FLOAT AND RETURN THE VALUE
SKPSTR    INY		;MOVE OVER STRING VARIABLE'S NAME
SKPST1    INY		;POINT TO STRING VARIABLE'S LENGTH
          LDA(VARADR),Y	;GET THE STRING LENGTH
          PHA		;SAVE IT
          INY		;POINT TO FIRST BYTE IN STRING
          TYA		;UPDATE 'VARADR' TO BASE OF STRING
          JSR UPDVAR               
          PLA		;GET SIZE OF STRING
          JSR UPDVAR	;UPDATE 'VARADR' BY PROPER AMOUNT
          BNE CHKVAR	;AND LOOK FOR NEXT VARIABLE IN LIST
CHKSUB    LDA STRSWT	;ARE WE LOOKING FOR A STRING VARIABLE
          BNE NOTVAR	;BRANCH IF WE ARE, CAN'T BE THIS NUMERIC VARIABLE
          LDA VSUB	;GET HIGH ORDER SUBSCRIPT WE ARE LOOKING FOR
          INY		;POINT TO SUBSCRIPT IN LIST
          CMP(VARADR),Y	;ARE THEY THE SAME?     
          BNE NOTVAR	;BRANCH IF THIS ONE IS NOT IT
          LDA VSUB+1	;ARE LOW ORDERS ALSO THE SAME?
          INY
          CMP(VARADR),Y          
          BNE NOTVAR	;BRANCH IF THEY ARE NOT THE SAME
LOCVAR    JSR FETVAR	;GET THE VARIABLE'S VALUE INTO FLAC
          JSR POPJ	;AND RETURN TO CALLER 
NOVAR     LDA STRSWT	;IS THIS STRING A VARIABLE 
          BNE NOSTR	;BRANCH IF IT IS A STRING VARIABLE 
          LDA VCHAR	;GET THE VARIABLE'S NAME 
          STA (VARADR),Y	;STORE IT IN LIST
          INY		;POINT TO NEXT IN LIST
          LDA VSUB	;GET HIGH ORDER SUBSCRIPT
          STA (VARADR),Y	;SAVE IT IN LIST
          INY		;POINT TO NEXT
          LDA VSUB+1	;GET LOW ORDER SUBSCRIPT
          STA (VARADR),Y	;SAVE IT IN LIST
          LDA #$00	;GET A ZERO
          LDX #NUMBF+1	;GET COUNT OF NUMBER OF BYTES IN NUMBER
ZERVAR    INY		;POINT TO THE NEXT VARIABLE
          STA (VARADR),Y	;ZERO OUT VARIABLES VALUE
          DEX		;COUNT THIS BYTE
          BNE ZERVAR	;LOOP TILL DONE. NOTE: EXTRA ZERO AT END
          LDA #EOV	;FLAG END OF VARIABLE LIST
          STA (VARADR),Y	;FLAG END OF VARIABLE LIST
          JSR UPDEND	;UPDATE THE END OF THE VARIABLE LIST
          BNE LOCVAR	;UNCONDITIONAL BRANCH, AS WE HAVE FOUND
			;THE VARIABLE

; *** BEGIN GAVIN D. SECTION

;
; 
;  HERE WHEN STRING VARIABLE WAS NOT FOUND
; 

NOSTR     LDA #STRMRK	;ADD A STRING MARKER AT THE END OF VARIABLE LIST
          STA (VARADR),Y
          INY
          LDA VCHAR	;ADD IT'S NAME
          STA (VARADR),Y
          INY
          LDA STRSIZ	;GET DEFAULT STRING SIZE
          STA (VARADR),Y	;STORE AS SIZE OF STRING
          STA VSIZE	;ALSO STORE FOR OTHERS WHO NEED TO KNO
          INY		;POINT TO FIRST BYTE OF STRING
          TYA		;UPDATE 'VARADR'
          JSR UPDVAR
          LDY #$00	;POINT TO FIRST BYTE OF STRING
          LDA #$20	;GET A BLANK
STRINI    STA (VARADR),Y	;SET STRING TO ALL BLANKS
          INY
          CPY STRSIZ	;DONE YET?
          BNE STRINI	;NO, LOOP TILL STRING IS ALL BLANKS
          LDA #EOV	;GET THE END OF VARIABLE LIST MARKER
          STA (VARADR),Y	;FLAG END OF LIST
          TYA		;UPDATE 'VARADR'
          JSR UBDENV
          JMP GETSTC	;GET BYTE FROM STRING AND RETURN
VARINI    LDA VARBEG	;GET ADDR OF START OF VARIABLE LIST
          STA VARADR	;AND SET POINTER
          LDA VARBEG+1
          STA VARADR+1
          RTS		;AND RETURN

NXTVAR    LDA #VARSIZ	;ADD IN SIZE OF NUMERIC VARIABLE
UPDVAR    CLC		;SETUP FOR ADDITION
          ADC VARADR	;TO 'VARADR'
          STA VARADR
          LDA VARADR+1
          ADC #$00
          STA VARADR+1
          RTS
;
; ROUTINE TO UPDATE THE END OF THE VARIABLE LIST
;
UPDEND    LDA #VARSIZ	;ADD SIZE OF NUMERIC VARIABLE
UBDENV    CLC
          ADC VARADR	;ADD NUMBER IN ACCUMULATOR 'VARADR'
          STA VAREND	;AND STORE RESULT IN 'VAREND'
          LDA VARADR+1
          ADC #$00	;ADD IN THE CARRY
          STA VAREND+1
BOMSVR    RTS		;AND RETURN
;
;ROUTINE TO BOMB OUT IF THE VARIABLE IS A STRING VARIABLE
;
BOMSTV    LDA STRSWT	;GET A STRING FLAG
          BEQ BOMSVR	;RETURN IF NOT A STRING
          BRK		;TRAP
          .BYTE SVNA	;?STRING VARIABLE NOT ALLOWED HERE 
;
;          'VARIABLE MANIPULATION UTILITIES
;
;"PUTVAR" PUT NUMBER IN FAC1 INTO THE VARIABLE
;
PUTVAR    LDY #$03	;POINT TO START OF VALUE
PUTV1     LDA X1-3,Y	;GET A BYTE FROM FAC1
          STA (VARADR),Y	;STORE IT INTO VARIABLE
          INY		;POINT TO NEXT BYTE
          CPY #VARSIZ	;REACHED END OF VARIABLE YET?          
          BNE PUTV1	;NO, THEN MOVE SOME MORE
          RTS		;*** MUST RETURN WITH Z BIT = ! ! ***

; "FETVAR" FETCH VARIABLE VALUE INTO FAC1

FETVAR    LDY #$03	;POINT TO START OF VALUE
FETV1     LDA (VARADR),Y	;GET A BYTE FROM VARIABLE
          STA X1-3,Y	;PUT IT INTO FAC1
          INY		;POINT TO NEXT BATE
          CPY #VARSIZ	;REACHED THE END OF VARIABLE YET?
          BNE FETV1	;NO, THEN MOVE ANOTHER BYTE
          RTS		;YES, RETURN

;"PUSHIV" PUSH INCREMENT AND VARIABLE ADDR ON STACK USED BY "FOR" COMMAND

PUSHIV    LDX #VARADR	;POINT TO VARIABLE ADDR
          JSR PUSHB2	;PUSH IT INTO STACK
          JMP PHFAC2	;* PJMP * PUSH FAC2 INTO STACK AND RETURN

;"POPIV" POP INCREMENT AND VARIABLE ADDR OFF STACK

POPIV     JSR PLFAC2	;RESTORE INTO FAC2
          LDX #VARADR+1	;POINT TO VARIABLE ADDR
          JMP POPB2	;* PJMP * RESTORE INTO VARIABLE ADDR AND RETURN

;ZERO THE FLOATING POINT ACCUMULATOR FACE1

ZRFAC1    LDX #NUMBF-1	;POINT TO LAST BYTE
          LDA #$00	;LOAD A ZERO
ZRFAC     STA X1,X	;ZERO THE BYTE
          DEX		;POINT TO NEXT ONE
          BNE ZRFAC	;LOOP TILL ALL OF MANTISSA ZEROED
          LDA #$80	;NOW SET EXPONENT
          STA X1
          RTS		;AND RETURN
;
;          'INTERRUPT HANDLERS'
;
NOTBRK    PHA		;SAVE THE PROCESSOR STATUS          
          LDA #UNKINT	;UNKNOWN INTERRUPT
          PHA		;SAVE CODE ON STACK
          BNE BERROR	;AND PRINT ERROR CODE
NMISRV    NOP		;CURRENTLY PUNT NMI'S AS UNKNOWNS
INTSRV    STA ACSAV	;SAVE ACCUMULATOR
          PLA		;GET THE PROCESSOR STATUS
          BIT MSKBRK	;IS B BIT ON?
          BEQ NOTBRK	;BRANCH TO INTERRUPT SERVICE CHAIN
          STA STATUS	;SAVE OLD PROCESSOR STATUS     
          PLA		;GET THE LOW ORDER RETURN ADDRESS
          CLC		;GET READY FOR ADD
          ADC #$FF	;ADD IN A -1
          STA ITEMP1	;STORE IT IN PAGE ZERO
          PLA		;GET HIGH ORDER RETURN ADDR
          ADC #$FF	;ADD IN A -1
          STA ITEMP1+1	;STORE IN PAGE ZERO
          TYA		;GET Y REGISTER
          PHA		;SAVE ON STACK
          LDY #$00	;OFFSET OF ZERO
          LDA (ITEMP1),Y	;GET BRK CODE     
          PHA		;SAVE ON STACK
          BMI BERROR	;BRANCH IF A SOFTWARE DETECTED ERROR
          PLA		;POSITIVE ERROR CODE, GET IT BACK
          LDA #UNRBRK	;UNRECOGNIZABLE BREAK
          PHA		;SAVE ON STACK
;
;          ERROR CODE OUTPUT ROUTINE
;
BERROR    LDA #$FF	;GET -1
          STA M1	;FOR HIGH ORDER
          PLA		;GET THE NEG ERROR CODE
          STA M1+1	;STORE INIC LOW ORDER
          JSR FLT16	;FLOAT IT
          JSR SETUP	;RESET AND INITIALIZE IMPORTANT STUFF
          JSR CRLF	;ADVANCE A LINE
          LDA #$3F	;'?' INDICATE AN ERROR
          JSR PRINTC	;
          JSR OUTLN0	;OUTPUT IT
          LDA PC	;GET HIGH ORDER FOCAL STATEMENT COUNTER
          BPL BERR1	;BRANCH IF ERROR OCCURED IN A STORED STATEMENT
          CMP #STRLIN	;DID ERROR OCCUR WHILE EXECUTING A STRING?
          BNE BERRC	;NO, THEN ERROR OCCURED IN DIRECT COMMAND
BERR1     LDA #$20	;SPACE FOR LOOKS
          JSR PRINTC	;
          LDA #$40	;NOW AN '@'
          JSR PRINTC          
          LDA #$20	;ANOTHER SPACE FOR THE LOOKS
          JSR PRINTC
          JSR PUSHTP	;SAVE THE TEXTPOINTERS
          LDA PC	;EXECUTING A STRING WHEN ERROR OCCURED?
          BPL BERR2	;BRANCH IF NOT, PRINT STATEMENT NUMBER
          LDA PC+1	;YES, THEN GET THE STRING NAME
          JSR PRTVNM	;AND PRINT IT
          LDA #$24	;INDICATE IT'S A STRING
          JSR PRINTC          
          BNE BERR3	;AND UNCONDITIONALLY PRESS ON
BERR2     LDA #PC	;GET ADDR OF WHERE PROGRAM COUNTER IS STORED
          STA TXTADR	;MAKE TEXT POINTER POINT TO IT
          LDA #$00
          STA TXTADR+1	;HIGH ORDER IS ZERO
          STA TEXTP
          JSR PRNTLN	;OUTPUT THE LINE NUMBER
BERR3     JSR POPTP	;RESTORE TEXT POINTERS
			;FALL INTO 'BERRC'
;
;          'MORE INTERRUPT HANDLERS'
;
BERRC     JSR CRLF2	;ADVANCE TWO LINES
          LDY #$00	;POINT TO FIRST CHAR IN LINE
          LDA PC	;DIRECT COMMAND OR STRING?
          BMI OUTCMD	;BRANCH IF YES
          LDY #$02	;NO, THEN POINT PAST LINE NUMBER
OUTCMD    CPY TEXTP	;ARE WE AT FRONT OF LINE?
          BEQ BERRET	;BRANCH IF YES, DON'T OUTPUT SPECIAL ERROR AID
OUTCML    TYA		;SAVE Y OUTPUT ACROSS OUTPUT CALL
          PHA
          LDA (TXTADR),Y	;OUTPUT CHAR FROM COMMAND LINE SO USER CAN SEE
          JSR PRINTC
          CMP #$0D	;REACHED END OF LINE YET?
          BEQ EREOL	;BRANCH IF YES,
          PLA		;RESTORE Y REG
          TAY
          INY		;POINT TO THE NEXT CHAR IN THE COMMAND LINE
          BNE OUTCML	;AND LOOP TILL ALL OF THE COMMAND LINE HAS BEEN OUTPUT
EREOL     PLA		;ADJUST STACK
          JSR OUTLF	;FOLLOW WITH A LINE FEED
CHKERR    DEC TEXTP	;COUNT DOWN NUMBER OF BYTES TILL ERROR
          LDY #$00	;ASSUME WE COUNT BACK TO ZERO
          LDA PC	;DIRECT COMMAND OR STRING
          BMI CHKERC	;BRANCH IF YES
          LDY #$02	;NO, THEN WE ONLY COUNT BACK TO LINE NUMBER
CHKERC    CPY TEXTP	;HAVE WE OUTPUT ENOUGH SPACES TO GET ERROR BYTE?
          BEQ EARROW	;BRANCH IF YES, OUTPUT UPARROW TO FLAG CHARACTER
          LDA #$20	;NO, THEN ADVANCE ONE SPACE
          JSR PRINTC          
          BPL CHKERR	;AND UNCONDITIONALLY CHECK AGAIN
EARROW    LDA #$5E	;OUTPUT UPARROW TO INDICATE WHERE ERROR IS
          JSR PRINTC
          JSR CRLF2	;AND ADVANCE FOR LOOKS
BERRET    JMP START	;AND RESTART
;
;
CRLF2     JSR CRLF          ;ADVANCE TWO LINES
CRLF      LDA #$0D          ;A CARRIAGE RETURN
          JSR PRINTC
OUTLF     LDA #$0A          ;AND A LF
          JMP PRINTC          ;* PJMP * TO PRINT ROUTINE
;
;          'INTEGER LINE NUMBER INPUT ROUTINE'
;
; 'GETLIN' THIS ROUTINE IS CALLED IF THE FIRST CHAR OF A LINE NUMBER
; IS 0-9 FOR ADDED SPEED, AS THE CALL TO 'EVAL' IS POWERFUL
; BUT SLOW (SEE 'GETLN').
;
GETILN    JSR GETIN	;GET A TWO-DIGIT INTEGER
          STA GRPNO	;SAVE AS GROUP NUMBER
          JSR TTERMS	;IS TERMINATOR ONE WE RECOGNIZE?
          BEQ GETIR	;YES, THEN RETURN
          CMP #$2E	;NO, IS IT A PERIOD?
          BNE GETBAD	;NO, THEN A BAD LINE NUMBER
          JSR TESTNS	;ANOTHER NUMBER?
          BCS GETBAD	;NO, THEN ERROR
          JSR GETIN	;YES, THEN GET NEXT NUMBER
          BCC LNOK	;BRANCH, IF TWO-DIGIT OUTPUT
          TAX		;MOVE INTO X
          LDA TENS,X	;YES, THEN ASSUME TRAILING ZERO
LNOK      STA LINENO	;SAVE THE LINE (STEP) NUMBER
          RTS		;AND RETURN
;
GETIN     AND #$0F	;MAKE 0-9
          PHA		;SAVE ON STACK
          JSR TESTNS	;TEST NEXT NON-BLANK
          PLA		;RESTORE SAVED NUMBER
          BCS GETIR	;RETURN IF NOT A DIGIT
          TAX		;PLACE SAVED NUMBERINTO X
          LDA CHAR	;GET NEW DIGIT
          AND #$0F	;FORM 0-9
          ADC TENS,X	;ADD IN PROPER HIGH ORDER
          PHA		;SAVE NUMBER ON STACK
          JSR TESTNS	;TEST NEXT NON-BLANK
          PLA		;GET SAVED NUMBER BACK
          BCS GETIRC	;BRANCH IF NOT A NUMBER
GETBAD    JMP BADLNO	;BAD LINE NUMBER BRANCH AID
GETIRC    CLC		;INDICATE TWO DIGITS INPUT
GETIR     RTS		;RETURN
;
TENS      .BYTE 0
          .BYTE 10
          .BYTE 20
          .BYTE 30
          .BYTE 40
          .BYTE 50          ; Aresco code has a $15 here, clearly wrong
          .BYTE 60                 
          .BYTE 70
          .BYTE 80             
          .BYTE 90                  
;
;
;
;               FOCAL FUNCTIONS
;
;
FUNC      LDY #$00	; SET OFFSET TO ZERO
          TXA		;PLACE HASH CODE INTO ACCUMULATOR
FUNC1     LDX FUNTAB,Y	;GET TABLE VALUE
          BEQ BADFUN	;END OF TABLE AND NOT FOUND
          CMP FUNTAB,Y	;MATCH YET?
          BEQ GOTFUN	;YES, WE FOUND IT
          INY		;NO, POINT TO NEXT ENTRY
          BNE FUNC1	;AND TRY IT
GOTFUN     LDA FUNADL,Y	;GET LOW ORDER ARRD OFROUTINE TO HANDLE
          STA TEMP1	;FUNCTION
          LDA FUNADH,Y	;GET HIGH ORDER
          STA TEMP1+1	;STORE IT
          JMP (TEMP1)	;AND GO TO IT (TEMP1)

BADFUN    BRK		;TRAP
          .BYTE UNRFUN	;?UNRECOGNIZABLE FUNCTION NAME
;
;     FABS - ABS. VALUE FUNCTION
;
FABS      JSR ABSF1	;TAKE ABSOLUTE VALUE OF FAC1
          JMP FPOPJ	;*PJMP* AND RETURN
;
;     FINT & FINR - RETURN INTEGER FUNCTIONS
;
FINT      JSR INTFIX	; MAKE FAC1 AN INTEGER
FLPOPJ    JSR FLOAT	; FLOAT ALL BITS
FPOPJ     JSR POPJ	; *FJMP* AND RETURN
;
; 'FINR' INTEGERIZE AFTER ROUNDING
;
FINR      JSR INTGER	; FORM ROUNDED INTEGER
          JMP FLPOPJ	;*PJMP*FLOAT AND RETURN
;
;              ROUTINES TO CHECK RANGE INPUT AND OUTPUT DEVICE NUMBERS
;
CHKODV    CMP #$03	;COMPARE AC AGAINST MAX ALLOWED
          BPL RNGDEV	;BRANCH IF ERROR
CHKRTS    RTS		;RETURN IF OK
CHKIDV    CMP #$03	;COMPARE AGAINST MAX
          BMI CHKRTS	;RETURN IF OK
RNGDEV    CMP #$FF	;MINUS 1?
          BEQ CHKRTS	;BRANCH IF YES, ALWAYS IN RANGE
          BRK		;TRAP
	  .BYTE DEVRNG	;DEVICE NUMBER OUT OF RANGE
;
;              "FINI" INITIALIZE INPUT DEVICE 
;
FINI      JSR INTGER	;MAKE ARGUMENT INTEGER
          BMI INIRET	;IGNORE IF NEGATIVE
          JSR CHKIDV	;CHECK FOR VALIDITY
          JSR INI	;GO CALL APPROPRIATE ROUTINE     
INIRET    JMP FLPOPJ	;NO ERRORS, RETURN
;
;            'FINO' INITIALIZE OUTPUT DEVICE
;
FIND      JSR INTGER	;MAKE ARGUMENT AN INTEGER
          BMI INIRET	;IGNORE IF NEGATIVE
          JSR CHKODV	;CHECK FOR VALIDITY
          JSR INO	;GO CALL APPROPRIATE ROUTINE
          JMP FLPOPJ	;NO ERRORS - RETURN
;
;            'FCLI' CLOSE INPUT DEVICE
;
FCLI      JSR INTGER	;MAKE ARGUMENT AN INTEGER
          BMI CLIRET	;IGNORE IF NEGATIVE
          JSR CHKIDV	;RANGE CHECK THE DEVICE NUMBER
          JSR CLI	;CALL DEVICE DEPENDENT CODE
CLIRET    JMP FLPOPJ	;NO ERRORS - RETURN
;
;           "FCLO" CLOSE OUTPUT DEVICE
;
FCLO      JSR INTGER	;MAKE ARGUMENT AN INTEGER
          BMI CLIRET	;IGNORE IF NEGATIVE
          JSR CHKODV	;RANGE CHECK THE DEVICE NUMBER
          JSR CLO	;CALL DEVICE DEPENDENT CODE
          JMP FLPOPJ	;NO ERRORS - RETURN
;
;           "FCON" SET CONSOLE DEVICE
;
FCON      JSR INTGER	;MAKE ARGUMENT AN INTEGER
          BMI RETCON	;BRANCH IF NEGATIVE
          JSR CHKIDV	;MAKE SURE DEVICE IS IN RANGE FOR BOTH INPUT
          JSR CHKODV	;AND OUTPUT
          STA CONDEV	;MAKE IT CURRENT CONSOLE     
          JSR CLRDEV	;MAKE CURRENT IO DEVICE
          JSR INIDEV	;INITIALIZE IT FOR INPUT AND OUTPUT
          JMP FLPOPJ	;*PJMP* NO ERRORS - RETURN
RETCON    LDA CONDEV	;GET THE DEVICE NUMBER OF CONSOLE
          JSR FLT8	;FLOAT IT
          JMP FPOPJ	;*PJMP* AND RETURN
;
;           "FCUR" CONSOLE CURSOR ADDRESSING FUNCTION
;          NOTE:     THIS FUNCTION IS DEVICE DEPENDENT, AND IS HERE
;                    PRIMARILY BY POPULAR DEMAND. THE FUNCTION HAS
;                    TWO ARGUMENTS. THE FIRST IS THE ROW, THE SECOND     
;                    IS THE COLUMN, OF THE PLACE TO POSITION ON THE CONSOLE
;                    DEVICE (USUALLY ASSUMED TO BE CRT).
;
FCUR      JSR FI2ARG	;PICK UP TWO INTEGER ARGS
          JSR CONCUR	;*** CALL THE DEVICE DEPENDENT CODE ***
          BCS JOERRO	;BRANCH IF ERROR HAS OCCURED
          JMP FLPOPJ	;* PJMP * AND RETURN
;
;ROUTINES TO DISPATCH TO DEVICE DEPENDENT INITIALIZATION ROUTINE
;ENTER EACH WITH THE DEVICE NUMBER IN THE ACCUMULATOR
;THEY WILL RETURN ONLY IF NO ERRORS WERRE ENCOUNTERED
;
INI       TAX		;USE AS OFFSET TO ADDR TABLE
          LDA INIAH,X	;GET HIGH ORDER ADDR OF THE ROUTINE TO HANDLE
          STA TEMP1+1	;SAVE IT
          LDA INIAL,X	;GET LOW ORDER ADDR
INIC      STA TEMP1	;SAVE IT
          CLC		;ASSUME SUCCESSS
          JSR JSRIND	;CALL THE PROPER ROUTINE FOR THIS DEVICE
          BCC IRTS	;RETURN IF NO ERRORS
          JMP IERRI	;ERROR, GO COMPLAIN
IRTS      RTS

INO       TAX		;USE AS OFFSET
          LDA INOAH,X	;GET HIGH ORDER OF THE ROUTINE TO HANDLE
          STA TEMP1+1	;SAVE IT
          LDA INOAL,X	;GET LOW ORDER OF THE ROUTINE TO HANDLE
INOC      STA TEMP1	;SAVE IT
          CLC		;ASSUME SUCCESS
          JSR JSRIND	;CALL PROPER ROUTINE FOR THIS DEVICE
          BCC IRTS	;RETURN IF NO ERRORS
JOERRO    JMP OERRO	;COMPLAIN IF ERRORS

CLI       TAX		;USE AS OFFSET TO TABLE
          LDA CLIAH,X	;GET HIGH ORDER ADDR OF THE DEVICE DEPENDENT CODE
          STA TEMP1+1
          LDA CLIHL,X	;GET LOW ORDER ADDR
          JMP INIC	;*PJMP* CALL DEVICE DEPENDENT CODE AND RETURN


CLO       TAX		;USE AS OFFSET TO TABLE
          LDA CLOAH,X	;GET HIGH ORDER ADDR OF THE DEVICE DEPENDENT CODE
          STA TEMP1+1
          LDA CLOAL,X	;GET LOW ODER
          JMP INOC	;*PJMP* CALL DEVICE DEPENDENT CODE AND RETURN
;
;           "FMEM"  MEMORY EXAMINE-DEPOSIT FUNCTION
;
FMEM      JSR FI2ARG	;PICK UP TWO INTEGER ARGS
          LDY CHAR	;GET THE TERMINATOR
          CPY #$2C	;ANOTHER ARG?
          BEQ FMEMD	;YES, THEN IT'S THE DEPCSIT FUNCTION
          STA ITMP1H	;SAVE HIGH ORDER ARRD TO EXAMINE
          STX ITMP1L	;SAVE THE LOW ORDER ADDR TO EXAMINE               
          LDY #$00	;FORM OFFSET OF ZERO
          LDA (ITMP1L),Y	;GET DATA STORED IN THE LOCATION
ST16PJ    STA M1+1	;SAVE IN INTEGER
          STY M1	;HIGH ORDER OF ZERO
FL16PJ    JSR FLT16	;FLOAT A 16 BIT INTEGER
          JMP FPOPJ	;*PJMP* AND RETURN

FMEMD     PHA		;SAVE HIGH ORDER
          TXA		;
          PHA		;AND LOW ORDER 
          JSR NXIARG	;PICK UP THE NEXT INTEGER ARG
          TAY		;SAVE IN Y REGISTER FOR A MOMENT
          PLA		;GET LOW ORDER ADDR BACK
          STA ITMP1L                         
          PLA		;GET HIGH ORDER ADDR BACK
          STA ITMP1H     
          TYA		;GET DATA TO DEPOSIT BACK
          LDY #$00	;SET OFFSET OF ZERO
          PHA		;SAVE DATA TO DEPOSIT
          LDA (ITMP1L),Y	;READ THE LOCATION
          STA M1+1	;SAVE AS INTEGER
          STY M1	;HIGH ORDER OF ZERO
          PLA		;GET DATA TO DEPOSIT BACK AGAIN
          STA (ITMP1L),Y	;STORE IN THE ADDR     
          LDA CHAR	;GET TERMINATOR
          CMP #$2C	; ',' MORE ARGS?
          BNE FL16PJ	;* PJMP * NO, FLOAT AND RETURN
          JSR PUSHJ	;MOVE PAST COMMA,
          .WORD EVALM1	;EVALUATE NEXT ARG
          JMP FMEM	;AND TRY AGAIN
;
;          "FOUT" OUTPUT ASCII EQUIVALENT
;
FOUT      JSR INTGER	;FORM INTEGER
          JSR PRINTC	;OUTPUT THE CHARACTER
          JMP FLPOPJ	;* PJMP * FLOAT AND RETURN
;
;           "FCHR" RETUNR DECIMAL EQUIVALIENT CF ASCII CHAR INPUT
;
FCHR      JSR GICHR	;GET A CHAR FROM INPUT DEVICE 
          JMP FL16PJ	;* PJMP * FLOAT AND RETURN
;
; ROUTINE TO INPUT ONE CHAR FROM INPUT DEVICE INTO FAC1
;
GICHR     LDA #$00	;ZERO HIGH ORDER
          STA M1	;               
          LDA CHAR	;SAVE CURRENT HAR
          PHA
          JSR READC	;NEXT CHAR FROM INPUT DEVICE
          STA M1+1	;STORE IN LOW ORDER
          PLA		;RESTORE SAVED CHAR
          STA CHAR          
          LDA M1+1	;GET CHAR INPUT INTO ACCUMULATOR
          RTS		;AND RETURN
;
;           "FECH" SET CHAR ECHO CONTROL
;
FECH      JSR INTGER	;FORM INTEGER
          STA ECHFLG	;SAVE IN FLAG FOR LATER REFERENCE
          JMP FLPOPJ	;* PJMP * FLOAT AND RETURN
    ;
;           "FIDV" SET INPUT DEVICE FUNCTION
;
FIDV      LDX #STIADR	;GET ADDR TO STORE INTO STRING INFORMATION
          JSR GTDEVN	;GET DEVICE NUMBER (POSSIBLY A STRING)
          JSR CHKIDV	;RANGE CHECK IT
          LDX IDEV	;SAVE PREVIOUS VALUE FOR POSSIBLE RESTORE
          STX IDVSAV	;
          STA IDEV	;MAKE IT THE CURRENT INPUT DEVICE
          JMP FIODRT	;* PJMP * SET FAC1 TO ZERO, THEN RETURN
;
;           "FODV" SET OUTPUT DEVICE FUNCTION
;
FODV      LDX #STOADR	;GET SDDR TO STORE STRING INFORMATION
          JSR GTDEVN	;GET DEVICE NUMBER (POSSIBLY A STRING)
          JSR CHKODV	;RANGE CHECK IT
          LDX ODEV	;SAVE PREVIOUS VALUE FOR POSSIBLE RESTORE
          STX ODVSAV
          STA ODEV	;SET AS OUTPUT DEVICE
FIODRT    JSR ZRFAC1	;RETURN A VALUE OF ZERO FOR THE FUNCTION 
          JMP FLPOPJ	;* PJMP * FLOAT AND RETURN
;
; ROUTINE TO GET A DEVICE NUMBER (POSSIBLY A STRING)
;
GTDEVN    LDA STRSWT	;WAS ARGUMENT A STRING VARIABLE?
          BNE STRDEV	;BRANCH IF YES
          JMP INTGER	;* PJMP * NO, JUST TO INTEGRIZE ARG AND RETURN
STRDEV    LDA VARADR	;STORE BASE ADDR OF STRING
          STA $00,X	;IN POINTER
          LDA VARADR+1
          STA $01,X
          LDA VSUB+1	;GET SUBSCRIPT OF PLACE TO START
          STA $02,X          
          LDA VSIZE	;AND GET MAX SIZE OF STRING
          STA $03,X
          LDA #$FF	;RETURN DEVICE NUMBER OF -1
          RTS		;AND RETURN

FI2ARG    LDA CHAR	;GET TERMINATOR
          CMP #$2C	;',' ANOTHER ARG?
          BNE FARGM	;BRANCH IF ARG IS MISSING
          JSR INTGER	;GET A SINGLE BYTE INTEGER
          PHA		;SAVE ACROSS 'EVAL' CALL
          JSR NXIARG	;GET ANOTHER ARG
          TAX		;SAVE THE SECOND ARGUMENT
          PLA		;GET THE FIRST ARGUMENT 
          RTS		;AND RETURN
;
NXIARG    JSR PUSHJ	;MOVE PAST COMMA, EVALUATE NEXT ARGUMENT
          .WORD EVALM1
          JMP INTGER	;*PJMP* FORM SINGLE BYTE INTEGER AND RETRUN

FARGM     BRK		;TRAP
          .BYTE ARGM	;?ARGUMENT MISSING IN FUNCTION
;
;     ROUTINE TO GENERATE A ROUNDED INTEGER
;
INTGER    LDX #FHALF	;MOVE CONSTANT .50
          LDY #X2	;INTO FAC2
          JSR MOVXY
          JSR SWAP	;PUT .5 IN FAC1
          LDA M2	;GET SIGN OF FAC2
          BPL INTG1	;OK IF POSITIVE
          JSR FCOMPL	;MAKE -.50
INTG1     JSR FADD	;ADD IT IN AS ROUNDING
INTFIX    JSR FIX	;AND FORM 23 BIT INTEGER
          LDA M1+2	;GET LOW ORDER IF CALLER NEEDS IT               
          RTS		;AND RETURN
;
;           "FPIC" SOFTWARE PRIORITY INTERRUPT CONTROL FUNCTION
;
FPICC     JSR PUSHJ	;CALL 'EVAL' TO PICK UP NEXT ARG
          .WORD EVALM1
FPIC      LDA CHAR	;GET CHAR WHICH TERMINATED ARGUMENT
          CMP #$2C	;IS THERE ANOTHER ARGUMENT TO FOLLOW
          BNE FARGM	;BRANCH IF NOT, GO COMPLAIN
          JSR INTGER	;YES, PICK UP VALUE OF FIRST
          BEQ PISET	;BRANCH IF LEVEL TO ENABLE IS 0
          PHA		;SAVE LEVEL TO ENABLE
          JSR GETC	;MOVE PAST COMMA
          JSR GETLNS	;AND PICK UP THE LINE NUMBER TO 'DO'
          PLA		;GET LEVEL BACK
          TAX		;INTO X REGISTER
          LDA GRPNO	;GET GROUP NUMBER OF LINE TO 'DO'
          STA INTGRP,X	;SAVE FOR LATER USE
          LDA LINENO	;GET STEP NUMBER OF LINE TO 'DO'
          STA INTLIN,X	;SAVE FOR LATER USE
          LDA ACTMSK	;GET MASK WHICH INDICATES WITH CHANNELS
          ORA BITTAB,X	;SET THE BIT FOR SPECIFIED CHANNELS
          STA ACTMSK	;MAKING IT ACTIVE NOW
ENDPIC    LDA CHAR	;GET CHAR WHICH TERMINATES SECOND ARG
          CMP #$2C	;',' ANY MORE ARGS?
          BEQ FPICC	;BRANCH IF YES, PICK THEM UP
          LDY #$00	;NO GET A ZERO
          LDA ACTMSK	;AND THE CURRENT ACTIVE MASK
          JMP ST16PJ	;* PJMP * STORE, FLOAT AND RETURN IT AS VALUE

PISET     JSR NXIARG	;GET NEXT ARG AS NUMBER
          LDA M1+1	;IS IT NEGATIVE
          BMI ENDPIC	;YES, THEN THIS CALL IS A NO-OP
          LDA M1+2	;NO, GET THE INTEGER VALUE (0-255)
          STA ACTMSK	;AND STORE THAT AS NEW ACTIVE MASK
          JMP ENDPIC	;AND CHECK FOR MORE ARGUMENTS BEFORE RETURNING
;
;                    'FOCAL STRING FUNCTIONS'
;
;           "FISL" INITIALIZE STRING LENGTH
;
FISLNX    JSR PUSHJ	;PICK UP NEXT ARGUMENT
         .WORD EVALM1     
FISL      LDA STRSIZ	;SAVE DEFAULT STRING SIZE
          PHA          
          JSR INTGER	;GET FIRST ARGUMENT WHICH IS SIZE TO SET
          STA STRSIZ
          JSR FGTSV	;GET NEXT ARGUMENT WHICH IS A STRING VARIABLE
            ;IF NOT PREVIOUSLY DEFINED IT WILL BE DEFINED
            ;WITH SUPPLIED LENGTH.
          PLA		;RESTORE WITH LENGTH
          STA STRSIZ
          LDA CHAR
          CMP #$2C	;',' ANY MORE ARGS?
          BEQ FISLNX	;BRANCH IF YES, PROCESS THEM
          JMP FPOPJ	;* PJMP * NO, THEN RETURN
;
; ROUTINE TO GET A STRING VARIABLE FROM PROGRAM TEXT
;
FGTSV     LDA CHAR	;ANY MORE ARGUMENTS IN FUNCTION CALL?
          CMP #$2C
          BNE FSTRBA	;BRANCH IF NOT, ERROR
          JSR GETC	;YES, MOVE PAST COMMA
FGTSV1    JSR PUSHJ	;CALL 'GETVAR' TO GET A VARIABLE
          .WORD GETVAR
          LDA STRSWT	;WAS IT A STRING VARIABLE?
          BNE SVOK	;BRANCH IF IT WAS 
          BRK		;TRAP
          .BYTE SVRO	;?STRING VARIABLE REQUIRED HERE
SVOK      LDY VSUB+1	;GET ELEMENT POSITION
          LDA VARADR	;AND LOW AND
          LDX VARADR+1	;HIGH ORDER BASE ADDR OF STRING
          RTS		;AND RETURN

FSTRBA    BRK		;TRAP
          .BYTE BASTRF	;?BAD OR MISSING ARGUMENT IN STRING FUNCTION
;
;           "FSTI" INPUT A STRING FROM INPUT DEVICE
;
FSTI      JSR SETSIO	;PICK UP ARGS
FSTINX    JSR GICHR	;GET A CHARACTER FROM INPUT DEVICE
          CMP VCHAR	;IS THIS THE TERMINATOR?
          BEQ SENDIO	;YES, THEN THAT'S ALL FOLKS
          LDY VSUB+1	;GET SUBSCRIPT TO PLACE CHAR
          CMP #RUBCHR	;IS THE CHARACTER A RUBOUT?
          BEQ RUBSTI	;BRANCH IF YES, SEE IF WE DO SOMETHING
FSTOC     STA (VARADR),Y	;STORE CHAR THERE
          INC VSUB+1	;POINT TO NEXT
          INC STRCNT	;COUNT THIS CHARACTER
          DEC STRMAX	;REACH MAX ALLOWED?
          BNE FSTINX	;BRANCH IF NOT, INPUT MORE
SENDIO    LDA #$00	;STORE A ZERO IN HIGH ORDER
          STA M1               
          LDA STRCNT	;GET NUMBER ACTUALLY MOVED
          STA M1+1          
          JMP FL16PJ	;* PJMP * FLOAT AND RETURN
;
;HERE IF RUBOUT SEEN DURING A STRING INPUT
;
RUBSTI    LDX IDEV	;IS THE INPUT DEVICE
          CPX CONDEV	;THE CONSOLE?
          BNE FSTOC	;BRANCH IF NOT, DON'T DO ANYTHING SPECIAL
          CPY STBSAV	;YES, ARE WE TRYING TO RUBOUT PAST STARTING SUBSCRIPT?
          BEQ FSTINX	;BRANCH IF SO, DON'T DO ANYTHING, IGNORE RUBOUT
          LDY ECHFLG	;DOES USER WANT CHARACTER ECHOING?
          BNE RUBSC	;BRANCH IF ECHOING DISABLED
          LDY DELSPL	;DO WE DO FANCY CRT STYLE RUBOUTS?
          BEQ RUBS1	;BRANCH IF NOT
          JSR EATTVC	;YES, THEN EAT THE CHAR OFF CRT SCREEN
          BPL RUBSC	;AND DO COMMON THINGS
RUBS1     LDA #RUBECH	;ECHO PLAIN CHAR TO INDICATE A RUBOUT
          JSR PRINTC
RUBSC     DEC VSUB+1	;PACK UP ONE BYTE IN THE STRING
          DEC STRCNT	;DON'T COUNT THE CHARACTER RUBBED OUT
          INC STRMAX
          JMP FSTINX	;AND GET NEXT CHARACTER
;
;           "FSTO" OUTPUT A STRING TO OUTPUT DEVICE
;
FSTO      JSR SETSIO	;GET ARGS
FSTONX    LDY VSUB+1	;GET SUBSCRIPT OF BYTE IN STRING
          LDA(VARADR),Y	;GET THE BYTE
          CMP VCHAR	;TERMINATOR?
          BEQ SENDIO	;BRANCH IF YES
          JSR PRINTC	;OUTPUT IT
          INC VSUB+1	;POINT TO NEXT BATE
          INC STRCNT	;COUNT THIS ONE OUTPUR
          DEC STRMAX	;OUTPUT MAX YET?
          BNE FSTONX	;BRANCH IF MORE TO OUTPUT
          BEQ SENDIO	;BRANCH IF WE HAVE HIT LIMIT
;
; ROUTINE TO GET ARGS FOR 'FSTI' AND 'FSTD'
;
SETSIO    LDA #$00	;GET A ZERO
          STA STRCNT	;INIT BYTE COUNT TO ZERO
          JSR INTGER	;GET MAX NUMBER OF CHARACTER TO MOVE
          STA STRMAX
          JSR FGTSV	;GET THE STRING VARIABLE
          PHA		;SAVE NEAT STUFF RETURNED
          TXA
          PHA
          TYA
          PHA
          LDA CHAR	;IS THE OPTIONAL TERMINATOR ARG SUPPLIED?
          CMP #$2C      
          BEQ SETS1	;YES, THEN PICK IT UP
          LDA #$FF	;NO, THEN SET IT TO $FF
          BNE SETS2	;AND ENTER COMMON CODE
SETS1     JSR PUSHJ	;MOVE PAST COMMA, PICK UP NEXT ARG
          .WORD EVALM1
          JSR INTGER	;FORM INTEGER
SETS2     STA VCHAR	;SAVE TERMINATION CHARACTER
          PLA		;RESTORE GOOD STUFF
          STA VSUB+1	;
          STA STBSAV	;REMEMBER SUBSCRIPT TO BEGIN I-O TO/FROM
          PLA                    
          STA VARADR+1
          PLA
          STA VARADR
          RTS		;AND RETURN
;
; ROUTINE TO WRITE A STRING
;
WSTRNG    LDY STOPNT	;new line - not in the 6502 Grp original

            ;original code  	(appears to be a patch
            ;WSTRNG CPY STOMAX    in ProgExch code)
            ;     BEQ WSRET
            ;     STA (STOADR),Y
            ;     INC STOPNT
            ;WSRET      PLA
            ;     RTS
;                    ; then go on with IOSRET
;
          CPY STOMAX	;BEYOND END OF STRING
          BEQ IOSRET	;BRANCH IF YES, IGNORE
          STA (STOADR),Y	;NO, STORE CHAR IN STRING
          INC STOPNT	;POINT TO NEXT BYTE

IOSRET    LDA #$0D	;RETURN A CR   
            ;additional line in original: 
                    ;STA CHAR ;also in char
          RTS		;AND RETURN 
;
; ROUTINE TO INPUT FROM A STRING
;
RSTRNG    LDY STIPNT	;GET POINTER TO NEXT BYTE
          CPY STIMAX	;BEYOND END OF STRING?
          BEQ IOSRET	;BRANCH IF YES, RETURN A CARRIAGE RETURN
          LDA (STIADR),Y	;NO, GET BYTE FROM STRING
          STA CHAR	;SAVE FOR THOSE WHO NEED IT
          INC STIPNT	;AND POINT TO NEXT
          RTS		;AND RETURN
;
;           FSLK - STRING "LOOK" FUNCTION
;
FSLK      LDA STRSWT	;WAS ARG A STRING VARIABLE
          BNE FSLK1	;YES, THEN PROCEED
          BRK		;TRAP
          .BYTE BASTRF	;?BAD OR MISSING ARGUMENT IN STRING
FSLK1     LDA VARADR	;COPY POINTERS INTO STRING1 POINTERS
          STA STRAD1
          LDA VARADR+1
          STA STRAD1+1
          LDA VSUB+1
          STA SBEG1	;STORE BEGINNING POSITION
          JSR FGTSV	;GET NEXT STRING PARAMETER
          STY SEND1	;STORE ENDING POSITION
          JSR FGTSV	;GET STRING 2 POINTERS
          STA STRAD2	;
          STX STRAD2+1
          STY SBEG2
          JSR FGTSV	;GET ENDING POSITION 
          STY SEND2	;STORE IT
          LDA #$FF	;ASSUME -1 (STRING NOT FOUND)
          STA M1
          STA M1+1
;
;SEARCH ROUTINE
;
LKFCHR    JSR CMPCHR	;FIRST CHAR MATCH?
          BEQ FCMAT	;BRANCH IF YES
CHKEOS    CPY SEND2	;NO, REACHES END OF STRING2?
          BEQ SNOTF	;BRANCH IF YES, STRING1 NOT FOUND IN STRING2
          INC SBEG2	;NO, POINT TO NEXT CHAR IN STRING2
          JMP LKFCHR	;AND TRY TO FIND CHAR MATCH
;
;  HERE IF FIRST CHAR IN STRING1 MATCHES A CHAR IN STRING2
;
FCMAT     JSR PUSHSP	;SAVE CURRENT POSITION IN BOTH STRINGS
NXCMAT    LDA SBEG1	;REACHED END OF  FIRST STRING?
          CMP SEND1                              
          BEQ SFOUND	;BRANCH IF YES, THEN STRING1 WAS FOUND IN STRING2
          CPY SEND2	;NO, REACHED END OF STRING2?     
          BEQ SNOTFP	;BRANCH IF YES, THEN STRING 1 CAN'T BE FOUND IN STRING2
          INC SBEG1	;POINT TO NEXT CHAR IN EACH STRING
          INC SBEG2
          JSR CMPCHR	;MATCH?
          BEQ NXCMAT	;BRANCH IF YES, KEEP CHECKING AS LONG AS THEY MATCH
          JSR POPSP	;NO, THEN RETURN TO THE POINT OF FIRST CHAR MATCH
          JMP CHKEOS	;AND TRY AGAIN FOR FIRST CHAR MATCH
SFOUND    JSR POPSP	;RESTORE POINTERS TO POSITION OF FIRST CHAR MATCH
          LDA #$00	;STORE 0 IN HIGH ORDER
          STA M1                    
          LDA SBEG2	;RETURN SUBSCRIPT WHERE FIRST CHAR MATCHED
          STA M1+1               
          JMP FL16PJ	;* PJMP * FLOAT AND RETURN
SNOTFP    JSR POPSP	;POP OFF SAVED POINTERS
SNOTF     JMP FL16PJ	;FLOAT -1 AND RETURN STRING1 WAS NOT FOUND IN STRING2
;
; ROUTINES USED BY 'FSLK'
;
CMPCHR    LDY SBEG1	;GET CHAR FROM STRING1
          LDA (STRAD1),Y
          LDY SBEG2	;GET CHAR FROM STRING2
          CMP (STRAD2),Y	;COMPARE THEM
          RTS		;RETURN WITH Z=1 IF THEY ARE THE SAME
;
PUSHSP    TYA		;PRESERVE Y REGISTER
          PHA          
          LDX STRAD1	;SAVE STRING POINTERS ON STACK
          LDY #$08
          JSR PUSHB0
          PLA		;RESTORE Y REGISTER
          TAY
          RTS		;AND RETURN
;
POPSP     TYA		;PRESERVE Y REGISTER
          PHA
          LDX STRAD1+7	;RESTORE STRING POINTERS
          LDY #$08
          JSR POPB0
          PLA		;RESTORE Y REGISTER
          TAY
          RTS		;AND RETURN
;
;            'FSBR' SINGLE VALUED SUBROUTINE CALL
;
FSBR      JSR GETLN1	;FINISH EVALUATING GROUP OR LINE TO "DO"
          PHP		;SAVE STATUS FLAGS ON STACK
          LDA #$30	;GET CODE NAME FOR VARIABLE '&0'
          STA VCHAR	;SAVE AS VARIABLE NAME TO LOOK FOR
          LDA #$00	;ALSO SET SUBSCRIÜPT TO ZERO
          STA VSUB
          STA VSUB+1
          STA STRSWT	;MAKE SURE STRING VARIABLE FLAG IS OFF
          JSR PUSHJ	;CALL 'FNDVAR' TO LOCATE '&0(0)'
          .WORD FNDVAR
          JSR SWAP	;PUT CURRENT VALUE OF '&0' INTO FAC2
          JSR PUSHIV	;SAVE IT'S VALUE AND ADDR ON STACK
          LDA CHAR	;GET TERMINATOR
          CMP #$2C	;',' IS THERE ANOTHER ARGUMENT
          BEQ FSBR1	;BRANCH IF YES, PRESS ON
          BRK		;NO, TRAP
          .BYTE ARGM	;?ARGUMENT MISSING IN FUNCTION
FSBR1     PLA		;GET FLAGS FROM 'GETLN' INTO ACCUMULATOR
          JSR PUSHA	;SAVE ON STACK
          LDX #GRPNO	;SAVE LINE OR GROUP TO 'DO'
          JSR PUSHB2
          JSR PUSHJ	;MOVE PAST COMMA, EVALUATE NEXT ARGUMENT
          .WORD EVALM1  
          LDX #LINENO	;GET LINE OR GROUP TO 'DO' BACK
          JSR POPB2               
          JSR POPA	;GET 'GETLN'FLAGS BACK
          PHA		;SAVE ON STACK FOR LATER 
          JSR POPIV	;GET VALUE OF '&0' AND POINTER TO IT
          JSR PUSHIV	;SAVE FOR LATER (VALUE IS IN FAC2)
          JSR PUTVAR	;NOW SET '&0' TO ARG VALUE (IN FAC1)
          LDA INSW	;SAVE WHERE INPUT IS COMING FROM
          JSR PUSHA	;(PROGRAM OR INPUT DEVICE)
          LDA #$00	;AND FORCE IT TO BE PROGRAM
          STA INSW          
          PLA		;GET STATUS FLAGS RETURNED BY 'GETLN'
          TAX		;SAVE IN X REGISTER
          JSR PUSHJ	;NOW PERFORM THE 'DO' OF THE LINE OR GROUP
          .WORD D01
          JSR POPIV	;RESTORE WHERE INPUT IS COMMING FROM
                 ;AND OLD VALUE IS IN FAC2
          JSR FETVAR	;GET CURRENT VALUE IN FAC1
          JSR SWAP	;OLD VALUE IN FAC1, CURRENT VALUE IN FAC2
          JSR PUTVAR	;REPLACE OLD VALUE OF '&0' BEFORE CALL
          JSR SWAP	;GET CURRENT VALUE OF '&0' INTO FAC1
          JMP FPOPJ	;RETURN IT AS THE VALUE OF THE 'FSBR'
;
;          "FRAN" RANDOM NUMBER GENERATOR, 
;          RETURNS A FRACTION BETWEEN 0.00 AND 1.00
;
FRAN      JSR INTGER	;INTEGRIZE ARGUMENT
          BEQ FRANC	;BRANCH IF =0, RETURN NEXT RANDOM NUMBER
          BPL FRSET	;BRANCH IF >0, SET TO REPEATABILITY
          LDA HASH	;GET THE RANDOM NUMBER HASH VALUE
          BNE FRNINI	;AND RANDOMITE
FRSET     LDA #$55	;SET TO ALTERNATING ZEROS AND ONES
FRNINI    LDX #$02	;SETUP LOOP COUNTER
FRNILP    STA SEED,X	;STORE IN SEED
          DEX	;POINT TO NEXT
          BPL FRNILP	;AND LOOP TILL DONE
FRANC     LDA #$7F	;SET EXPONENT OF FAC1
          STA X1
          CLC		;ADD K TO SEED
          LDA SEED
          ADC #$B1
          STA M1+2	;PUT RESULT IN LOW ORDER
          STA SEED	;ALSO THIS PART IN SEED
          LDA SEED+1
          ADC #$0C
          STA M1+1	;INTO MIDDLE ORDER
          LDA SEED+2
          ADC #$1B
          AND #$7F	;KILL SIGN BIT
          STA M1
          LDA M1+2
          ASL A	;2^17
          CLC
          ADC M1+2	;2^16
          CLC
          ADC M1	;PLUS HIGH ORDER
          STA SEED+2	;NEW SEED
          CLC
          LDA M1+2	;2^8 ADDED
          ADC M1+1
          STA SEED+1
          LDA M1+1
          ADC SEED+2
          STA SEED+2	;SEED NOW READY FOR NEXT TIME
          LDA #$00	;GET A ZERO
          JSR NORM0	;NORMALIZE THE FRACTION
          JMP FPOPJ	;* PJMP * and return


; *** BEGIN SamCoVT SECTION
   
;
;            CENTRAL ROUTINES
;
ADD       CLC
          LDX #$03	;*INDEX FOR 4 BYTE ADD
ADD1      LDA M1,X               
          ADC M2,X	;ADD NEXT BYTE
          STA M1,X
          DEX		;TO NEXT MORE SIG BYTE
          BPL ADD1	;DO ALL THREE
          RTS

MD1       ASL SIGN	;CLEAR LSB OF SIGN
          JSR ABSWAP	;ABS VAL M1, THEN SWAP
ABSWAP    BIT M1	;M1 NEG?
          BPL ABSWP1	;NO JUST SWAP
          JSR FCOMPL	;YES, NEGATE IT
          INC SIGN	;COMPLEMENT SIGN
ABSWP1    SEC		;FOR RETURN TO MUL/DIV
;
; SWAP FAC1 WITH FAC2
;
SWAP      LDX #$05	;*FIVE BYTES TOTAL
SWAP1     STY EM1,X               
          LDA X1M1,X	;SWAP A BYTE OF FAC1 WITH
          LDY SIGN,X	;FAC2 AND LEAVE COPY OF
			;$7A is X2M1 and SIGN. 
			;used SIGN, because it is defined!!!
          STY X1M1,X	;M1 IN E, E+3 USED
          STA SIGN,X
          DEX		;NEXT BYTE
          BNE SWAP1	;UNTIL DONE
          RTS
;
; ROUTINE TO FLOAT 23 BITS OF MANTISSA
;
FLOAT     LDA #FHALF	;SET EXPONENT TO 22 DECIMAL
          STA X1                    
          LDA #$00	;ZERO INTO LOW BYTES
          BEQ NORM0	;* PBE Q* NORMALIZE IT AND RETURN
;
; DO A FAST FLOAT OF A 1-BYTE QUANTITY 
;
FLT8      STA M1	;STORE THE BYTE
          LDA #$86	;ASSUME ALREADY SHIFTED 8 BLACES
          STA X1                    
          LDA #$00	;GET A ZERO
          STA M1+1	;ZERO OUT BYTE OF MANTISSA
          BEQ FLOATC	;*P BEQ * CLEAR THIRD BYTE, NORMALIZE AND RETURN
;
; FLOAT A 16-BUT INTEGER IN M1 & M1+1 TO FAC1
; FAC2 UNAFFECTED
;
FLT16     LDA #$8E
          STA X1	;SET EXP TO 14 DEC
          LDA #$00	;CLEAR LOW BYTES
FLOATC    STA M1+2
NORM0     STA M1+3	;*
			;* PFALL * NORMALIZE IT AND RETURN
NORM      JSR CHKZER	;* IS MANTISSA ZERO?
          BNE NORML	;BRANCH IF NOT, THEN DO THE NORMALIZE SHIFTING
          LDA #$80	;YES, THEN AVOID MUCH SHIFTING BY SETTING
          STA X1	;THE EXPONENT
          RTS		;AND RETURN
NORM1     DEC X1
          ASL M1+3	;* SHIFT 4 BYTES LEFT
          ROL M1+2
          ROL M1+1
          ROL M1
NORML     LDA M1	;NORMALISED CHECK
          ASL A		;UPPER TWO BYTES UNEQUAL?
          EOR M1
          BPL NORM1	;NO, LOOP TILL THEY ARE
RTSN      RTS
;
;FAC2-FAC1 INTO FAC1
;
FSUB      JSR FCOMPL	;WILL CLEAR CARRY UNLESS ZERO
SWPALG    JSR ALGNSW	;RIGHT SHIFT M1 OR SWAP ON CARRY
;
;FAC1 + FAC2 INTO FAC1
;
FADD      LDA X2                    
          CMP X1	;EXPONENTS EQUAL?
          BNE SWPALG	;IF NOT SWAP OR ALIGN
          JSR ADD	;ADD MANTISSAS
ADDEND    BVC NORM	;IF COOL, NORMALIZE
          BVS RTLOG	;DV: SHIFT RIGHT-CARRY IS COOL
			;SWAP IF CARRY CLEAR, ELSE SHIFT RIGHT ARITHMETICALLY
ALGNSW    BCC SWAP
RTAR      LDA M1	;SIGN INTO CARRY
          ASL A		;ARITH SHIFT
RTLOG     INC X1	;COMPENSATE FOR SHIFT
          BEQ OVFL	;EXP OUT OF RANGE
RTLOG1    LDX #$F8	;* INDEX FOR 8 BYTE RT SHIFT
ROR1      LDA #$80
          BCS ROR2
          ASL A
ROR2      LSR E+4,X	;*FAKE RORX E+4
          ORA E+4,X
          STA E+4,X
          INX		;NEXT BYTE
          BNE ROR1	;UNTIL DONE
          RTS
;
;  FAC1 * FAC2 INTO FAC1
;
FMUL      JSR MD1	;ABS VAL OF M1,M2
          ADC X1	;ADD EXPONENTS
          JSR MD2	;CHECK & PREP FOR NUL
          CLC
MUL1      JSR RTLOG1	;SHIFT PROD AND MFYR(?) RIGHT
          BCC MUL2	;SKIP PARTIAL PROD
          JSR ADD	;ADD IN MCAND
MUL2      DEY		;NEXT ITERATION
          BPL MUL1	;LOOP UNTIL DONE
MDEND     LSR SIGN	;SIGN EVEN OR ODD?
NORMX     BCC NORM	;IF EVEN NORMALIZE, ELSE COMPARE
FCOMPL    SEC                    
          LDX #$04	;*4 BYTE SUBTRACT
COMPL1    LDA #$00
          SBC X1,X
          STA X1,X
          DEX		;TO MORE SIG BYTE
          BNE COMPL1	;UNTIL DONE
          BEQ ADDEND	;FIX UP
;                              
OVCHK     BPL MD3	;IF POSITIVE EXPONENT NO CVF     
OVFL      BRK		;TRAP
          .BYTE FOVFL	;FLOATING POINT OVERFLOW
;
; DIVIDE FAC2 BY FAC1 INTO FAC1
;
FDIV      JSR MD1	;ABS VALUE OF M1, M2
          SBC X1	;SUBTRACT EXPONENTS
          JSR MD2	;SAVE AS RES EXP
DIV1      SEC
          LDX #$03	;* FOR 4 BYTES
DIV2      LDA M2,X               
          SBC E,X	;SUBTRACT BYTE OF E FROM M2
          PHA     
          DEX		;NEXT MORE SIG BYTE
          BPL DIV2	;UNTIL DONE
          LDX #$FC	;* FOR 4 BYTE COND MOVE
DIV3      PLA		;DIFF WAS ON STACK
          BCC DIV4	;IF M2<E DON'T RESTORE
          STA X1,X	;*
DIV4      INX		;NEXT LESS SIG BYTE
          BNE DIV3	;UNTIL DONE
          ROL M1+3	;*
          ROL M1+2               
          ROL M1+1	;ROLL QUOTIENT LEFT
          ROL M1	;CARRY INTO LSB
          ASL M2+3	;*
          ROL M2+2
          ROL M2+1	;DIVIDEND LEFT
          ROL M2
          BCS OVFL	;OVF IS DUE TO UNNORM DIVISOR
          DEY		;NEXT ITERATION
          BNE DIV1	;UNTIL DONE (23 ITERATIONS)
          BEQ MDEND	;NORM QUOTIENT AND FIX SIGN
MD2       STX M1+3	;*
          STX M1+2
          STX M1+1	;CLEAR M1
          STX M1                    
          BCS OVCHK	;CHECK FOR OVFL
          BMI MD3	;IF NEG NO UNDERFLOW
          PLA		;POP ONE RETURN
          PLA
          BCC NORMX	;CLEAR X1 AND RETURN
MD3       EOR #$80	;COMPL. SIGN OF EXPONENT
          STA X1                    
          LDY #$1F	;COUNT FOR 31 (/), 32 (*) ITERATIONS
          RTS
;
; FAC1 TO 23 BIT SIGNED INTEGER IN M1 (HIGH), M1+1 (MIDDLE), M1+2 (LOW) 
;
FIX1      JSR RTAR	;SHIFT MANTISSA, INC EXPONENT
FIX       LDA X1	;CHECK EXP
          CMP #FHALF	;IS EXP #22?
          BNE FIX1	;NO, SHIFT MORE
          RTS	;DONE
;
;            FLOATING POINT OUTPUT ROUTINE
;
FPRNT     LDA M1	;SAVE THE SIGN OF THE NUMBER
          STA SIGNP	;FOR LATER REFERENCE
          JSR ABSF1	;DEAL ONLY WITH ABSOLUTE VALUE
          JSR CHKZER	;IS NUMBER = 0?
          BNE FPR0	;BRANCH IF NOT, THEN TRY TO DIVIDE DOWN
          STA K		;YES, SOME FLAVOR OF ZERO. INDICATE THAT WE
          PHA		;DID NOT HAVE TO DIVIDE AS ALREADY <1
          BEQ FPR4A	;AND PUNT DIVIDE DOWN AND ROUNDING CODE
FPR0      LDA X1	;GET THE EXPONENT
          PHA		;SAVE FOR LATER REFERENCE
          LDA #$00	;ZERO COUNTER WHICH COUNTS HOW MANY TIMES
          STA K		;WE HAD TO DIVIDE TO GET NUMBER <1
FPR1      BIT X1	;IS NUMBER <1?
          BPL FPR2	;BRANCH IF YES
          JSR DIV10	;NO, THEN DIVIDE BY 10
          INC K		;COUNT THE FACT WE DID
          BPL FPR1	;AND CHECK AGAIN
FPR2      JSR PHFAC1	;SAVE NUMBER (NOW <1) ON STACK
          LDX #FHALF	;GET THE CONSTANT .5
          LDY #X1	;INTO FAC1
          JSR MOVXY
          CLC
          LDA K		;ROUNDING FACTOR IS .5*10^-(K+N)
          ADC N
          STA L
          BEQ FPR4	;BRANCH IF WE NEED .5*10^0
          LDA #$09	;* IS FACTOR BEYOND OUR PRECISSION?
          CMP L
          BPL FPR3	;BRANCH IF NOT, THEN ROUNDING FACTOR IS OK
          STA L		;YES, THEN APPLY ROUNDING TO LEAST SIG FIG
FPR3      JSR DIV10	;NOW SHIFT .5 INTO PROPER POSITION
          DEC L
          BNE FPR3
FPR4      JSR PLFAC2	;GET NUMBER INTO FAC2
          JSR FADD	;ADD THE ROUNDING FACTOR
          BIT X1	;IS IT STILL <1?
          BPL FPR4A	;BRANCH IF IT IS
;
;original ProgExch/6502Grp code has more lines here:
;          pla          ;no then get original exponent
;          bmi fpr4a    ;branch if original number >1 do nothing
;          lda x1       ;we gained a sig fig in rounding, get new exp
;fpr41     pha          ;save exponent for later
;
          JSR DIV10	;SCALE NUMBER BACK DOWN
          INC K		;AND INDICATE WE HAD TO
FPR4A     SEC
          LDA M		;NOW CONSULATE NUMBER OF LEADING BLANKS NEEDED
          SBC K
          STA L		;INTO L
          PLA		;GET EXPONENT OF ORIGINAL NUMBER BACK
          PHA		;SAVE AGAIN FOR LATER
          BMI FPR4B	;BRANCH IF ORIGINAL NUMBER IS <1?
          DEC L		;IT WAS <1. LEAVE ROOM FOR LEADINF 0
FPR4B     BIT SIGNP	;WAS NUMBER NEGATIVE
          BPL FPR5	;BRANCH IF NOT
          DEC L		;YES, THEN LEAVE ROOM FOR A MINUS SIGN
FPR5      LDA L		;ANY BLANKS TO OUTPUT?
          BMI FPR7	;BRANCH IF NOT
          BEQ FPR7	;BRANCH IF NOT
FPR6      JSR PSPACE	;OUTPUT A BLANK
          DEC L		;COUNT IT
          BNE FPR6	;AND LOOP TILL ALL HAVE BENN OUTPUT
FPR7      BIT SIGNP	;WAS NUMBER NEGATIVE?
          BPL FPR7A	;BRANCH IF NOT
          LDA #$2D	;YES, OUTPUT A LEADING "-"
          JSR L2902	;AND FALL INTO NEXT PAGE
FPR7A     PLA		;GET EXPONENT OF THE ORIGINAL NUM BACK AGAIN
          BMI FPR8	;BRANCH IF NOT <1
          JSR PZERO	;YES, THEN GIVE A LEADING ZERO
			;(PEOPLE LIKE IT!)
			;(IT'S ALSO A PAIN TO CHECK FOR!)
;                                        
; NOW FOR THE MEAT OF IT
;
FPR8      LDA #$09	;* GET MAX NUMBER OF SIG FIGS
          STA L		;INTO L
FPR9      LDA K		;ANY OUTPUT BEFORE DECIMAL?
          BEQ FPR11	;BRANCH IF NO MORE
FPR10     JSR MDO	;OUTPUT A DIGIT BEFORE DECIMAL
          DEC K
          BNE FPR10	;AND LOOK TILL ALL DONE
FPR11     LDA N		;GET NUMBER AFTER DECIMAL POINT
          STA K		;INTO K
          BEQ FPRET	;BRANCH IF NONE TO OUTPUT
          LDA #$2E	;THERE ARE SOME TO OUTPUT,
          JSR PRINTC	;PRINT THE DECIMAL POINT
FPR12     JSR MDO	;OUTPUT A DIGIT AFTER DECIMAL
          DEC K		;AND LOOP
          BNE FPR12	;TILL ALL OUTPUT
FPRET     RTS		;RETURN FROM 'FPRNT' FAC1 IS DESTROYED!
;
; MPY BY 10, PRINT INTEGER AND SUBTRACT IT
;
MDO       DEC L		;HAVE WE OUTPUT ALL DIGITS OF SIGNIFICANCE?
          BPL MDO1	;BRANCH IF NOT, OUTPUT THIS ONE
PZERO     LDA #$30	;YES, THEN OUTPUT A ZERO
          JMP PRINTC	;* PJMP * AND RETURN
MDO1      LDX FTEN               
          LDY X2
          JSR MOVXY
          JSR FMUL
FDONE     LDX X1	;SAVE FAC1
          LDY T
          JSR MOVXY
          JSR FIX
          LDA M1+2	;MAKE ASCII
          AND #$0F
          ORA #$30
          JSR PRINTC
          JSR FLOAT	;NOW SUBTRACT IT
          LDX T		;RESTORE TO FAC2
          LDY X2
          JSR MOVXY
          JMP FSUB	;PJUMP

;
;   UTILITIES FOR FPRNT
;
ABSF1     BIT M1
          BPL ABSFE
          JSR FCOMPL
ABSFE     RTS
MOVXY     DEX
          STX MOV1+1
          DEY
          STY MOV1+2
          LDX #$05	;*
MOV1      LDA $00,X
MOV2      STA $00,X
          DEX
          BNE MOV1
          RTS
;
DIV10     JSR SWAP
          LDX FTEN
          LDY X1
          JSR MOVXY
          JMP FDIV	;*PJMP*
;
CHKZER    LDA M1	;GET HIGH ORDER MANTISSA
          ORA M1+1	;'OR' ALL BYTES OF MANTISSA TOGETHER
          ORA M1+2
          ORA M1+3	;*
          RTS		;RETURN WITH Z=1 IF MANTISSA IS =0.
;
;   'FLOATING POINT INPUT ROUTINE'
;
FINP      LDA #$00
          STA SIGNP	;SET SIGN +
          STA DPFLG	;RESET DP FLAG
          STA GOTFLG	;NO INPUT YET
          STA K		;NO DIGITS AFTER DECIMAL POINT
          STA X2	;ZERO RESULT
          STA M2
          STA M2+1
          STA M2+2
          STA M2+3	;*
          LDA CHAR	;GET CHARACTER
          CMP #$2B	;IGNORE +'S
          BEQ FINP3               
          CMP #$2D	;'-' FLAG IF NEGATIVE
          BNE FINP2
          INC SIGNP
FINP3     JSR GETC	;ANOTHER CHAR
FINP2     CMP #$30	;'0' IS IT A DIGIT?
          BCC FINP4	;NO
          CMP #$3A	;':' MAYBE...
          BCS FINP4	;NO
          LDX FTEN
          LDY X1
          JSR MOVXY	;FAC2*10.0=FAC1
          JSR FMUL
          JSR SWAP	;INTO FAC2
          INC GOTFLG	;YES, WE HAVE INPUT
          LDA CHAR
          AND #$0F	;MAKE NUMERIC
          JSR FLT8	;AND FLOAT IT
          JSR FADD	;ADD TO PARTIAL RESULT
          JSR SWAP	;BACK INTO FAC2
          INC K		;COUNT DIGITS AFTER DECIMAL POINT
          BNE FINP3	;GET MORE
FINP4     CMP #$2E	;DECIMAL POINT?
          BNE FINP5	;NO, END OF #
          LDA DPFLG	;YES, ALREADY GOT ONE?
          BNE FINP5	;THEN END OF #
          INC DPFLG	;ELSE FLAG GOT ONE
          LDA #$00
          STA K		;RESET K
          BEQ FINP3	;AND GET FRACTION
;
; HERE ON END OF NUMBER
;
FINP5     JSR SWAP	;RESULT TO FAC1
          LDA DPFLG	;ANY DECIMAL POINTS?
          BEQ FINP6	;NO, ITS OK
FINP7     LDA K		;ELSE ADJUST
          BEQ FINP6	;ADJUST DONE
          JSR DIV10	;RESULT/10
          DEC K		;K TIMES
          BNE FINP7
FINP6     LDA SIGNP	;NOW ADD SIGN
          BEQ FINP8	;WAS POS
          JSR FCOMPL	;WAS NEG
FINP8     JMP NORM	;PJUMP TO NORMALIZE
;
; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
;
;     Here begins (again) code restoration by dhh
;
; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
;
; from here, the Aresco version of V3D code (TTY) completely differs from
; the ProgramExchange/6502 Group TIM-monitor code upon which it is based.
; PE code occupies $24A6 to $24D0 (here $349E to $34E7), and seems to be
; related to video terminal output.  What follows here are KIM-1-specific
; initialization and I/O routines from the Aresco version of V3D.  -dhh 
;
CONINI    LDA #$E0	; init BRK vector as $2CE0
          STA $17FE
          LDA #$2C
          STA $17FF
          CLC
          RTS
TVOUT     JSR $1EA0	; TTY OUTCH in KIM-1 ROM
          CLC
          RTS
KEYIN     INC $76	; label HASH
          BIT $1740     ; (R)RIOT I/O register A
          BMI L34AF
          LDA $1742     ; (R)RIOT I/O register B
          AND #$FE
          STA $1742
          JSR $1E5A     ; GETCH in KIM-1 ROM
          PHA
          LDA $1742     ; the echo defeat
          AND #$FE
          ORA #$01
          STA $1742
          PLA
          CLC
          RTS          ; 
;
;  The next bytes do not appear to be used for anything.
;  Perhaps leftover from Aresco conversion of Prog/Exch
;  version for KIM-1 (???).
;
		.BYTE $00,$43,$11,$51,$11,$11,$17,$01,$01,$11,$41
		.BYTE $53,$01,$51,$51,$11,$53,$EE,$CE,$FE,$EE,$EA
		.BYTE $EE,$06,$FE
;          BRK
;          ???                ;01000011 'C'
;          ORA ($51),Y
;          ORA ($11),Y
;          ???                ;00010111
;          ORA ($01,X)
;          ORA ($41),Y
;          ???                ;01010011 'S'
;          ORA ($51,X)
;          EOR ($11),Y
;          ???                ;01010011 'S'
;          INC $FECE
;          INC $EEEA
;          ASL $FE
;

;     SPECIAL TERMINATOR CHAR TABLE (see P/E code at $2401)
;
TRMTAB   .BYTE ' '     ; LEVEL 0 (SPACE)
         .BYTE '+'     ; LEVEL 1 '+'
         .BYTE '-'     ; LEVEL 2 '-'
         .BYTE '/'     ; LEVEL 3 '/'
         .BYTE '*'     ; LEVEL 4 '*'
         .BYTE '^'     ; LEVEL 5 '^'
         .BYTE '('     ; LEVEL 6 '('
         .BYTE ')'     ; LEVEL 7 ')'  (START OF DELIMITERS)
         .BYTE ','     ; LEVEL 8 ','
         .BYTE ';'     ; LEVEL 9 ';'
         .BYTE $0D     ; LEVEL 10 'CR'
         .BYTE '='     ; LEVEL 11 '=' (TERMINATOR FOR 'SET')
         .BYTE LINCHR  ; LEVEL 1 '_'  ('LINE-DELETE IS HERE SO
                       ;             'ASK' CAN ALLOW RE-TYPEIN)
;
; here TRMAX=12 is defined in the ProgExch code
;
;      THESE FUNCTION DISPATCH TABLES MAY BE PATCHED BY A USER
;      TO CALL HIS OWN FUNCTIONS.
;
;      TABLE OF 'HASH CODES' FOR FUNCTION NAMES
;
FUNTAB    .BYTE HFABS     ; ABSOLUTE VALUE FUNCTION
          .BYTE HFOUT     ; CHARACTER OUTPUT FUNCTION
          .BYTE HFRAN     ; RANDOM NUMBER FUNCTION
          .BYTE HFINT     ; INTEGERIZE FUNCTION
          .BYTE HFINR     ; INTEGERIZE WITH ROUNDING FUNCTION
          .BYTE HFIDV     ; INPUT DEVICE FUNCTION
          .BYTE HFODV     ; OUTPUT DEVICE FUNCTION
          .BYTE HFCHR     ; CHARACTER INPUT FUNCTION
          .BYTE HFCUR     ; CONSOLE CURSOR ADDRESSING FUNCTION
          .BYTE HFECH     ; ECHO CONTROL FUNCTION
          .BYTE HFPIC     ; SOFTWARE PRIORITY INTERRUPT FUNCTION
          .BYTE HFMEM     ; MEMORY EXAMINE-DEPOSIT FUNCTION
          .BYTE HFINI     ; INITIALIZE INPUT DEVICE FUNCTION
          .BYTE HFINO     ; INITIALIZE OUTPUT DEVICE FUNCTION
          .BYTE HFCLI     ; CLOSE INPUT DEVICE FUNCTION
          .BYTE HFCLO     ; CLOSE OUTPUT DEVICE FUNCTION
          .BYTE HFCON     ; SET CONSOLE DEVICE FUNCTION
          .BYTE HFSBR     ; 'SUBROUTINE' CALL FUNCTION
          .BYTE HFISL     ; INITIALIZE STRING LENGTH FUNCTION
          .BYTE HFSTI     ; STRING INPUT FUNCTION
          .BYTE HFSTO     ; STRING OUTPUT FUNCTION
          .BYTE HFSLK     ; STRING "LOOK" FUNCTION
          .BYTE 0	  ; SPARE LOCS FOR HACKERS
          .BYTE 0
          .BYTE 0
          .BYTE 0
          .BYTE 0
          .BYTE 0          ; MUST HAVE AT LEAST ONE ZERO TO END TABLE!
;
;     FUNCTION DISPATCH TABLES - HIGH BYTE
;
FUNADH     .BYTE >FABS     ; FABS
           .BYTE >FOUT     ; FOUT
           .BYTE >FRAN     ; FRAN
           .BYTE >FINT     ; FINT
           .BYTE >FINR     ; FINR
           .BYTE >FIDV     ; FIDV
           .BYTE >FODV     ; FODV
           .BYTE >FCHR     ; FCHR
           .BYTE >FCUR     ; FCUR
           .BYTE >FECH     ; FECH
           .BYTE >FPIC     ; FPIC
           .BYTE >FMEM     ; FMEM
           .BYTE >FINI     ; FINI
           .BYTE >FINO     ; FINO
           .BYTE >FCLI     ; FCLI
           .BYTE >FCLO     ; FCLO
           .BYTE >FCON     ; FCON
           .BYTE >FSBR     ; FSBR
           .BYTE >FISL     ; FISL
           .BYTE >FSTI     ; FSTI
           .BYTE >FSTO     ; FSTO
           .BYTE >FSLK     ; FSLK
           .BYTE $00       ; SPACE FOR HACKERS
L3528      .BYTE 0
           .BYTE 0
           .BYTE 0
           .BYTE 0
           .BYTE 0          ; MUST HAVE AT LEAST ONE ZERO TO END TABLE!
;
;     FUNCTION DISPATCH TABLES - LOW ORDER ADDR BYTE
;
FUNADL     .BYTE <FABS     ; FABS
           .BYTE <FOUT     ; FOUT
           .BYTE <FRAN     ; FRAN
           .BYTE <FINT     ; FINT
           .BYTE <FINR     ; FINR
           .BYTE <FIDV     ; FIDV
           .BYTE <FODV     ; FODV
           .BYTE <FCHR     ; FCHR
           .BYTE <FCUR     ; FCUR
           .BYTE <FECH     ; FECH
           .BYTE <FPIC     ; FPIC
           .BYTE <FMEM     ; FMEM
           .BYTE <FINI     ; FINI
           .BYTE <FINO     ; FINO
           .BYTE <FCLI     ; FCLI
           .BYTE <FCLO     ; FCLO
           .BYTE <FCON     ; FCON
           .BYTE <FSBR     ; FSBR
           .BYTE <FISL     ; FISL
           .BYTE <FSTI     ; FSTI
           .BYTE <FSTO     ; FSTO
           .BYTE <FSLK     ; FSLK
L3543      .BYTE 0             ; SPACE FOR HACKERS
           .BYTE 0
           .BYTE 0
           .BYTE 0
           .BYTE 0
           .BYTE 0               ; MUST HAVE AT LEAST ONE ZERO TO END TABLE!
;
;     COMMAND DISPATCH TABLES
;
;     THESE COMMAND DISPATCH TABLES MAY BE PATCHED BY USER
;     TO ADD HIS OWN SPECIAL COMMAND HANDLERS
;
;     COMMAND CHARACTER TABLE
;

COMTAB     .BYTE 'S'     ; 'S' SAVE COMMAND
           .BYTE 'I'     ; 'I' IF COMMAND
           .BYTE 'D'     ; 'D' DO COMMAND
           .BYTE 'O'     ; 'O' ON COMMAND
           .BYTE 'G'     ; 'G' GOTO COMMAND
           .BYTE 'F'     ; 'F' FOR COMMAND
           .BYTE 'R'     ; 'R' RETURN COMMAND
           .BYTE 'T'     ; 'T' TYPE COMMAND
           .BYTE 'A'     ; 'A' ASK COMMAND
           .BYTE 'C'     ; 'C' COMMENT COMMAND
           .BYTE 'E'     ; 'E' ERASE COMMAND
           .BYTE 'W'     ; 'W' WRITE COMMAND
           .BYTE 'M'     ; 'M' MODIFY COMMAND
           .BYTE 'Q'     ; 'Q' QUIT COMMAND
           .BYTE 0       ; SPACE FOR HACKERS
           .BYTE 0
           .BYTE 0
           .BYTE 0
           .BYTE 0
           .BYTE 0          ; MUST HAVE ONE ZERO TO END TABLE!
; 
;     HIGH ORDER ADDR OF COMMAND HANDLING ROUTINE
;
COMADH     .BYTE >SET         ; SET    
           .BYTE >IF          ; IF     
           .BYTE >DO          ; DO     
           .BYTE >ON          ; ON     
           .BYTE >GOTO        ; GOTO   
           .BYTE >FOR         ; FOR    
           .BYTE >RETURN      ; RETURN 
           .BYTE >TYPE        ; TYPE   
           .BYTE >ASK         ; ASK    
           .BYTE >COMMENT     ; COMMENT
           .BYTE >ERASE       ; ERASE  
           .BYTE >WRITE       ; WRITE  
           .BYTE >MODIFY      ; MODIFY 
           .BYTE >QUIT        ; QUIT   
           .BYTE 0            ; SPACE FOR HACKERS
           .BYTE 0
           .BYTE 0
           .BYTE 0          ; MUST HAVE ZERO TO END TABLE!
;
;     LOW ORDER ADDR OF COMMAND HANDLING ROUTINE
;
COMADL     .BYTE <SET         ; SET
           .BYTE <IF          ; IF
           .BYTE <DO          ; DO
           .BYTE <ON          ; ON
           .BYTE <GOTO        ; GOTO
           .BYTE <FOR         ; FOR
           .BYTE <RETURN      ; RETURN
           .BYTE <TYPE        ; TYPE
           .BYTE <ASK         ; ASK
           .BYTE <COMMENT     ; COMMENT
           .BYTE <ERASE       ; ERASE
           .BYTE <WRITE       ; WRITE
           .BYTE <MODIFY      ; MODIFY
           .BYTE <QUIT        ; QUIT
           .BYTE 0               ; SPACE FOR HACKERS
           .BYTE 0
           .BYTE 0
           .BYTE 0          ; MUST HAVE A ZERO TO END TABLE!
;
;     DISPATCH TABLE FOR 'EVBOP' ROUTINE
;
; two definitions here in the Prog/Exch code:
; at $2569 (3580 here) .DEF EVDSPH=.-1  and
; $256E (3585) .DEF EVDSPL=.-1
;
           .BYTE >FADD       ; FADD  
           .BYTE >FSUB       ; FSUB  
           .BYTE >FDIV       ; FDIV  
           .BYTE >FMUL       ; FMUL  
           .BYTE >EVPOWR     ; EVPOWR
;
           .BYTE <FADD       ; FADD
           .BYTE <FSUB       ; FSUB
           .BYTE <FDIV       ; FDIV
           .BYTE <FMUL       ; FMUL
           .BYTE <EVPOWR     ; EVPOWR
;
;          TABLES USED BY SOFTWARE INTERRUPT SYSTEM
;
; TABLE OF GROUP NUMBERS OF LINES TO 'DO' WHEN EVENT HAPPENS
; ONE ENTRY FOR EACH OF THE 8 PRIORITY CHANNELS
;
INTGRP     .BYTE 0
           .BYTE 0
           .BYTE 0
           .BYTE 0
           .BYTE 0
           .BYTE 0
           .BYTE 0
           .BYTE 0
           .BYTE 0
;
; TABLE OF STEP NUMBERS OF LINES TO 'DO' WHEN AN EVENT HAPPENS
;
INTLIN     .BYTE 0
           .BYTE 0
           .BYTE 0
           .BYTE 0
           .BYTE 0
           .BYTE 0
           .BYTE 0
           .BYTE 0
           .BYTE 0
;
; 'AND' MASKS USED TO DISABLE ALL BUT HIGHER PRIO CHANNELS.
; INDEXED BY CURRENT CHANNEL NUMBER
;
INTTAB    .BYTE $FF     ; CHANNEL 0 ENABLES THEM ALL
          .BYTE $FE
          .BYTE $FC
          .BYTE $F8
          .BYTE $F0
          .BYTE $E0
          .BYTE $C0
          .BYTE $80
          .BYTE $00     ; CHANNEL 8 ENABLES NONE
;
; BIT TABLE CONTAINING A SINGLE BIT FOR EACH CHANNEL POSITION
;
BITTAB    .BYTE $00
          .BYTE $01
          .BYTE $02
          .BYTE $04
          .BYTE $08
          .BYTE $10
          .BYTE $20
          .BYTE $40
          .BYTE $80
;
;     DISPATCH TABLE FOR I/O DEVICE NUMBERS
;
; handwritten note in P/E source: "READ/WRITE"
; Two definitions made here:
;     .DEF IDEWVM=3     .DEF ODEVM=3  ; MAX # OF I/O DEVICES
;
IDSPH     .BYTE >KEYIN     ; DEVICE 0 - KEYBOARD INPUT ROUTINE
          .BYTE 0          ; DEVICE 1 - CASSETTE #0 INPUT ROUTINE
          .BYTE 0          ; DEVICE 2 - CASSETTE #1 INPUT ROUTINE
          .BYTE 0          ; SPACE FOR HACKERS
          .BYTE 0
IDSPL     .BYTE <KEYIN
          .BYTE 0
          .BYTE 0
          .BYTE 0
          .BYTE 0
ODSPH     .BYTE >TVOUT     ; DEVICE 0 - TV OUTPUT ROUTINE
          .BYTE 0          ; DEVICE 1 - CASSETTE #0 OUTPUT ROUTINE
          .BYTE 0          ; DEVICE 2 - CASSETTE #1 OUTPUT ROUTINE
          .BYTE 0          ; SPACE FOR HACKERS
          .BYTE 0
ODSPL     .BYTE >TVOUT
          .BYTE 0
          .BYTE 0
          .BYTE 0
          .BYTE 0
;
; handwritten note in P/E source: "INITIALIZE IN/OUT"
;
INIAH      .BYTE >RTS1     ; DON'T NEED TO INTIALIZE KEYBOARD
           .BYTE >RTS1     ; USER MUST PROVIDE ROUTINE
           .BYTE >RTS1     ;
           .BYTE $00       ; SPACE FOR HACKERS
           .BYTE $00
;
INIAL      .BYTE <RTS1
           .BYTE <RTS1
           .BYTE <RTS1
           .BYTE 0
           .BYTE 0
;
INOAH      .BYTE >CONINI	; USE TO STUFF VECTORS WITH BREAK HANDLERS
           .BYTE $29		; USER PROVIDES ROUTINES
           .BYTE $29
           .BYTE 0
           .BYTE 0
;
INOAL      .BYTE <CONINI
           .BYTE $40
           .BYTE $40
           .BYTE 0
           .BYTE 0
;
; handwritten note in P/E source: "CLOSE IN/OUT"
;
CLIAH     .BYTE >RTS1   ; KEYBOARD DOESN'T NEED A CLOSE ROUTINE
          .BYTE >RTS1   ; USER PROVIDES ROUTINE
          .BYTE >RTS1   ;
          .BYTE $00     ; SPACE FOR HACKERS
          .BYTE $00     ; SPACE FOR HACKERS
;
CLIAL     .BYTE <RTS1
          .BYTE <RTS1
          .BYTE <RTS1
          .BYTE 0
          .BYTE 0
;
CLOAH     .BYTE >RTS1	; TV DOESN'T NEED A CLOSE ROUTINE
          .BYTE >RTS1	; USER PROVIDES ROUTINE
          .BYTE >RTS1	;
          .BYTE $00	; SPACE FOR HACKERS
          .BYTE $00  
;                    
INOAL     .BYTE <RTS1
          .BYTE <RTS1
          .BYTE <RTS1
          .BYTE 0
          .BYTE 0
;
;      FOCEND - TEXT AREAS AND THE LIKE
;
PRGBEG    .BYTE 0	; LINE NUMBER OF 00.00
          .BYTE 0     
          .ASCII  " C FOCAL-65 (V3D) 26-AUG-77"
          .BYTE $0D	; 'CR'


PBEG     .BYTE EOP     ; START OF PROGRAM TEXT AREA
VEND     .BYTE EOV     ; END OF VARIABLE LIST

         .END     
