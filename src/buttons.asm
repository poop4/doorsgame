;
; buttons handling. just one sub for now
;

.include "system.inc"
.include "buttons.inc"

.segment "ZEROPAGE"
Buttons: .res 1

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
