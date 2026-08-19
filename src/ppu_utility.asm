;
; Generic background and sprite draw utilities
;

.smart
.debuginfo+
.include "ppu_utility.inc"
.include "system.inc"
.include "main.inc"
.include "nmi.inc"

; Sprite object constructor
.segment "ZEROPAGE"
CellsIndex:		.res 1

.segment "BSS"
CellsList:		.res 16

.segment "CODE"
; stores objects in cell list to oam and updates index
.proc UpdateCells
CellsPtr := TmpPtr

	lda #0
	sta CellsIndex
	sta CellsPtr
	sta CellsPtr+1
	
@LoadNextCells:
; Initialize CellsPtr to next slot
; End the subroutine when we hit an empty slot
	lda CellsIndex
	asl
	tax
	lda CellsList, X
	sta CellsPtr
	lda CellsList+1, X
	beq @CellsNoMore
	sta CellsPtr+1

	ldx oam_index
	ldy #0
@UpdateOAM:
	lda (CellsPtr), Y
	cmp #$FF
	beq @CellsComplete
	sta oam, X
	iny
	inx
	jmp @UpdateOAM
	
@CellsComplete:
	txa
	clc
	adc oam_index
	sta oam_index
	inc CellsIndex
	jmp @LoadNextCells
	
@CellsNoMore:
	rts
.endproc

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