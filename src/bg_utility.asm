;
; Generic background draw utilities.
; Currently: bgSetup
;

.smart
.debuginfo+
.include "system.inc"
.include "main.inc"
.include "bg_utility.inc"

; generic utility for zeroing nametable rams
; a: namtable id ($20 or $28)
bgSetup:
	; empty nt0
	bit $2002 ; reset latch
	; sta from function call
	sta $2006
	lda #$00 ; nt0
	sta $2006
	lda #$FF
	ldy #30 ; y
	:
		ldx #32 ; x
		:
			sta $2007
			dex
			bne :-
		dey
		bne :--
	; zero attr table
	ldx #64
	lda #%00000000
	:
		sta $2007
		dex
		bne :-
	rts


; a: tileID
; y: xpos
bgDrawStripeY:
	pha
	lda #%10010100
	sta PPUCTRL
	lda PPUSTATUS
	lda ScrollNt
	asl
	asl
	clc
	adc #$20
	sta PPUADDR
	sty PPUADDR
	pla 
	ldx #0
@Draw:
	sta PPUDATA
	inx
	cpx #30
	bne @Draw
	lda #%10010000
	sta PPUCTRL
	rts

; a: tileID
; y: ypos	
	bgDrawStripeX:
	pha
	lda PPUSTATUS
	lda ScrollNt
	asl
	asl
	clc
	adc #$20
	sta PPUADDR
	tya
	asl
	asl
	asl
	asl
	asl
	sta PPUADDR
	pla 
	ldx #0
@Draw:
	sta PPUDATA
	inx
	cpx #32
	bne @Draw
	rts