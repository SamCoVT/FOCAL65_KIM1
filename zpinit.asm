

; SamCoVT - Zero page initialization routine from focal 6502 user notes
; patched in here.
ZPAGE = 0
LENGTH = $BF            ; NUMBER OF BYTES
STARTF = $2000
        .ORG $3F00
; CSTART (address $3F00) will now be the new cold start address.
CSTART
        LDX #0          ; INIT THE LOOP COUNTER
ZLOOP
        LDA ZSTORE,X    ; START MOVING DATA
        STA ZPAGE,X
        INX
        CPX #LENGTH+1
        BNE ZLOOP
        JMP STARTF      ; PAGE IS SET UP
                        ; GO TO FOCAL

        .ORG $3F10
ZSTORE
        .BYTE $53, $53, $4C, $E0, $2C, $4C, $DF, $2C, $00, $00, $00, $00, $00, $00, $00, $00        
        .BYTE $00, $62, $7B, $66, $EB, $6B, $3A, $7B, $6A, $6B, $6B, $7B, $FB, $7B, $6B, $6B
        .BYTE $00, $00, $00, $00, $00, $00, $FF, $00, $00, $01, $00, $00, $00, $00, $00, $E0
        .BYTE $3F, $FE, $3F, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $FF, $3F
        .BYTE $FF, $3F, $FF, $3F, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        .BYTE $00, $00, $00, $00, $5F, $00, $00, $00, $00, $00, $00, $00, $00, $00, $4C, $00
        .BYTE $00, $6C, $00, $00, $48, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $C0
        .BYTE $10, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        .BYTE $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $05
        .BYTE $05, $83, $50, $00, $00, $00, $7F, $40, $00, $00, $00, $80, $40, $00, $00, $00
        .BYTE $00, $00, $00, $00, $00, $FF, $1C, $3C, $7C, $5F, $7F, $7C, $3E, $7F, $3E, $FF
        .BYTE $94, $DD, $84, $D4, $85, $D4, $95, $04, $DD, $94, $95, $DF, $8C, $15, $1D, $94

;
;      FOCEND - TEXT AREAS AND THE LIKE
;
; SamCoVT - Zero page variables have been modified to make room
; for zero page loading routine (extending FOCAL to take up a full
; 8KB).  As a result, line 0.0 (below) needs to be moved up to
; $3FE0.
          .ORG $3FE0
MVDPRGBEG .BYTE 0	; LINE NUMBER OF 00.00
          .BYTE 0     
          .ASCII  " C FOCAL-65 (V3D) 26-AUG-77"
          .BYTE $0D	; 'CR'


MVDPBEG   .BYTE EOP     ; START OF PROGRAM TEXT AREA
MVDVEND   .BYTE EOV     ; END OF VARIABLE LIST

