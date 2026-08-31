;
; buttons handling. just one sub for now
;

.include "system.inc"
.include "buttons.inc"
.include "main.inc"

.segment "ZEROPAGE"
Buttons:		.res 1

.segment "CODE"
ReadJoypad1:
	lda #1
	sta JOYPAD1 ; set strobe bit
	lda #0
	sta JOYPAD1 ; buttons is reloaded
	ldx #8
	:
	pha
	lda JOYPAD1
	and #%00000011
	cmp #%00000001
	pla
	ror
	dex
	bne :-
	
	sta Buttons
	rts

; 
; 
; 

; parameter A: Pad ID to check
; return A: Pad status
.proc CheckButtons
PadID := Scratch+0
	ldx ButtonsTimer
	beq @NoTimeout
; Timeout, wait until timer 0
	dec ButtonsTimer
	lda #0
	jmp @End
	
@NoTimeout:
	sta PadID
	lda Buttons
	and PadID
; Return 1 if pressed and reset timer, else 0
	beq :+
; NOTE: ROUTINES MUST SET BUTTONSTIMER THEMSELVES!!
	lda #1	
	jmp @End
:
	lda #0 

@End:
	rts

.endproc
