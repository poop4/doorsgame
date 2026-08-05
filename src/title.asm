;
;  Title initialization and per-frame routine.
;

.include "system.inc"
.include "nmi.inc"
.include "main.inc"
.include "buttons.inc"
.include "bg_utility.inc"
.include "title.inc"
.include "dungeon.inc"
.include "fairy.inc"

.segment "ZEROPAGE"
TitleMenuIndex:		.res 1

.segment "CODE"
Title_Load:
	jsr ppu_off
	
	; load title palette
	ldx #0
	:
		lda title_palette, x
		sta paletteRAM, x
		inx 
		cpx #32
		bne :-
	
	; clear nt0
	lda #$20
	jsr bgSetup
	
; Turn ON sprites 
	lda #%00010000
	sta SpritesOn

	;
	; TODO
	; draw title tiles
	; subtitle
	; 'copyright'
	; menu options	
	;

	lda #<Title_Frame
	sta PrgmFramePtr
	lda #>Title_Frame
	sta PrgmFramePtr+1
	
	jmp (PrgmFramePtr)
	

Title_Frame:
; Scroll if necessitated (and delay dungeon start)
	lda NeedScroll
	beq @DoFrame
	lda ScrollY
	clc
	adc #$02
	sta ScrollY
; Have we rolled down to NT2?
	cmp #$EF
	bcc @StillScrolling
; Set scroll to 0 and take me to the DUNGEON
	lda #0
	sta ScrollY
	lda #2
	sta ScrollNt
	lda #0
	sta NeedScroll
	lda #MODE_DUNGEON
	sta PrgmMode
	lda #1
	sta PrgmMode_update
	lda #120
	sta CursorX
@StillScrolling:
	jmp @NoTimer
@DoFrame:
	; check buttons
	lda Buttons
	and #PAD_START
	beq @HandleSelect
	lda TitleMenuIndex
	cmp #TITLE_START
	bne @NotDungeon
; We dungeon, queue scroll for next frames 
	lda #1
	sta NeedScroll
	jmp @NoTimer ; we done, jump 
@NotDungeon:
	; TODO: handle other sub title states, eventually
@HandleSelect:
	lda ButtonsTimer
	; if timer is nonzero we wait
	bne @HandleSelectTimer
	; no timer we ball
	lda Buttons
	and #PAD_SELECT
	beq @HandleSelectTimer
	; cycle menu options 
	lda TitleMenuIndex
	cmp #TITLE_HINTS 
	beq @Wraparound
	inc TitleMenuIndex
	jmp @SetTimer
@Wraparound:
	lda #TITLE_START
	sta TitleMenuIndex
@SetTimer:
	lda #30
	sta ButtonsTimer
@HandleSelectTimer:
	lda ButtonsTimer
	beq @NoTimer
	dec ButtonsTimer
@NoTimer:
	; bueines as usual.	
	jsr ppu_update
	jmp mainloop

	
; Tables

; TODO this is a placeholder.
title_palette:
; bg
.byte $0F,$15,$26,$37 ; bg0 purple/pink
.byte $0F,$09,$19,$29 ; bg1 green
.byte $0F,$01,$11,$21 ; bg2 blue
.byte $0F,$00,$10,$32 ; bg3 greyscale
; sp
.byte $0F,$18,$28,$38 ; sp0 yellow
.byte $0F,$14,$24,$34 ; sp1 purple
.byte $0F,$1B,$2B,$3B ; sp2 teal
.byte $0F,$12,$22,$32 ; sp3 marine
