;
;  Title initialization and per-frame routine.
;

.debuginfo+
.smart
.include "system.inc"
.include "nmi.inc"
.include "main.inc"
.include "buttons.inc"
.include "ppu_utility.inc"
.include "title.inc"
.include "dungeon.inc"
.include "dungeon_room.inc"
.include "fairy.inc"
.include "rng.inc"

.segment "ZEROPAGE"
TitleMenuIndex:		.res 1

.segment "BSS"
TitleCells:		.res 49


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
	
	ldx #0
@ClearRoomLoop:
	lda #$FF 
	sta RoomObjects, X
	inx
	cpx #$10
	bne @ClearRoomLoop
	
; Title & Subtitle BG
	lda #OBJ_DUERER
	ldx #2
	ldy #4
	jsr CreateRoomObject
	
	lda #OBJ_SUBTITLE
	ldx #2
	ldy #7
	jsr CreateRoomObject
		
; Title Sprites
; Store cells
	ldx #0
	ldy #0
:
	lda table_DuererSp, X
	sta TitleCells, Y
	inx
	iny
	cpx #48
	bne :-
	lda #$FF
	sta TitleCells, Y
	
; Clear list, then add cells to list
	ldx #0
:
	lda #0
	sta CellsList, X
	inx
	cpx #$10
	bne :-
	
	lda #<TitleCells
	sta CellsList
	lda #>TitleCells
	sta CellsList+1
	
	
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
	; cycle seed
	inc Seed
	
	; draw any sprites
	jsr UpdateCells
	
	jsr ppu_update
	jmp mainloop

	
; Tables

table_DuererSp:
.byte $1F,$10,$00,$18,  $1F,$11,$00,$28,  $1F,$13,$00,$38,  				  $1F,$13,$00,$58
.byte 									  $20,$14,$00,$35,  $20,$14,$20,$43,  $20,$14,$00,$55,  $20,$14,$20,$63
.byte $26,$10,$80,$18,  $27,$12,$00,$28,  $26,$13,$80,$38,					  $26,$13,$80,$58

; TODO this is a placeholder.
title_palette:
; bg
.byte $0F,$26,$10,$10
.byte $0F,$09,$19,$29 ; bg1 green
.byte $0F,$01,$11,$21 ; bg2 blue
.byte $0F,$00,$10,$32 ; bg3 greyscale
; sp
.byte $0F,$26,$10,$10
.byte $0F,$18,$28,$38 ; sp1 purple
.byte $0F,$00,$00,$00 ; sp2 teal
.byte $0F,$00,$00,$00; sp3 marine
