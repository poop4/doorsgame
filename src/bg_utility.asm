;
; Generic background draw utilities.
; Currently: bgSetup
;

.include "system.inc"
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
