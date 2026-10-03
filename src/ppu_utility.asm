;
; Generic background and sprite draw utilities
;

.smart
.debuginfo+
.include "ppu_utility.inc"
.include "system.inc"
.include "prgm.inc"
.include "nmi.inc"

; Sprite object constructor
.segment "ZEROPAGE"
cells_Index:		.res 1

.segment "BSS"
cells_Ptrs:		.res 16


.segment "CODE"
; stores objects in cell list to oam and updates index
.proc handler_Cells
CellsPtr := TmpPtr

	lda #0
	sta cells_Index
	sta CellsPtr
	sta CellsPtr+1
	
@LoadNextCells:
; Initialize CellsPtr to next slot
; End the subroutine when we hit an empty slot
	lda cells_Index
	asl
	tax
	lda cells_Ptrs, X
	sta CellsPtr
	lda cells_Ptrs+1, X
	beq @CellsNoMore
	sta CellsPtr+1

	ldx OAM_Index
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
	adc OAM_Index
	sta OAM_Index
	inc cells_Index
	jmp @LoadNextCells
	
@CellsNoMore:
	rts
.endproc
;																|
; __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __|
;																|
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