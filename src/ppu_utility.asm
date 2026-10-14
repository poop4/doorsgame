;
; Generic graphics utilities
;

.smart
.debuginfo+
.include "ppu_utility.inc"
.include "system.inc"
.include "prgm.inc"
.include "nmi.inc"

; _______________________________________________________________
;																|
;						Text parser								|
;																|
.segment "CODE"
; Parameters:
; x/y: tile coordinates
; TmpPtr: address of text string
.proc create_TextString
StringPtr := TmpPtr
DiaperVal := Scratch+0 ;nmtbuffer

; Store requested xy in nmtbuffer
	jsr PPU_ON_AddressTile
	; y = Nmt_Diaper
	sty DiaperVal
	
	ldy #0
; Count num tiles in string until terminator
@CountTiles:
	lda (StringPtr), Y
	cmp #$FF
	beq :+
	iny
	jmp @CountTiles
	
:
; Store strlen in buffer
	ldx DiaperVal
	tya
	sta NmtUpdateRAM, X
	inx
	
	ldy #0
; Store string tiles in buffer
@WriteStringLoop:
	lda (StringPtr), Y
	cmp #$FF
	beq :+
	sta NmtUpdateRAM, X
	iny
	inx
	jmp @WriteStringLoop
:
	; Fill diaper
	stx Nmt_Diaper
; All done!
	
	rts

.endproc
;															END |
; ______________________________________________________________|


; _______________________________________________________________
; 																|
; 					Sprite object handling						|
;																|
.segment "ZEROPAGE"
cells_Index:		.res 1

.segment "BSS"
cells_Ptrs:		.res 32
;																|
; __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __|
;																|

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
	bne :+
	
; Keep loading potential cells until we hit list end
	inc cells_Index
	lda cells_Index
	cmp #$20
	beq @CellsNoMore
	
	jmp @LoadNextCells
:
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
; 															END |
; ______________________________________________________________|


; _______________________________________________________________
; 																|
; 							bg clear							|
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
;															END |
; ______________________________________________________________|


; _______________________________________________________________
;																|
;						Write hor/ver stripes					|
;																|
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
;																|
; __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __|
;																|
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
; 															END |
; ______________________________________________________________|