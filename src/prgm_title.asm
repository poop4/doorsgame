;
;  Title initialization and per-frame routine.
;

.debuginfo+
.smart
.include "prgm_title.inc"
.include "nmi.inc"
.include "prgm.inc"
.include "buttons.inc"
.include "ppu_utility.inc"
.include "prgm_dungeon.inc"
.include "dungeon_room.inc" ; for titlescreen grafix
.include "fairy.inc"
.include "rng.inc"
.include "score.inc"

.segment "ZEROPAGE"
TitleMenuIndex:		.res 1

.segment "BSS"
cells_TitleGraphix:		.res 49

; _______________________________________________________________
; 																|
; 					Introduction initialization					|
;																|
.segment "CODE"
Title_Load:
; Clear game progress
	lda #0
	sta points
	sta score
	sta score+1
	sta stage
	; reset roomtimer so we don't transition accidentally
	lda #0
	sta NextRoomTimer
; Disable early buttonpress
	lda #$40
	sta ButtonsTimer

; Disable rendering 
	jsr ppu_off
	
; Upload palette
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
	sta objects, X
	inx
	cpx #$10
	bne @ClearRoomLoop
	
; Title & Subtitle BG
	lda #OBJ_DUERER
	ldx #2
	ldy #4
	jsr create_object
	
	lda #OBJ_SUBTITLE
	ldx #2
	ldy #7
	jsr create_object
		
; Title Sprites
; Store cells
	ldx #0
	ldy #0
:
	lda table_DuererSp, X
	sta cells_TitleGraphix, Y
	inx
	iny
	cpx #48
	bne :-
	lda #$FF
	sta cells_TitleGraphix, Y
	
; Clear list, then add cells to list
	ldx #0
:
	lda #0
	sta cells_Ptrs, X
	inx
	cpx #$10
	bne :-
	
	lda #<cells_TitleGraphix
	sta cells_Ptrs
	lda #>cells_TitleGraphix
	sta cells_Ptrs+1
	
	; 'copyright'
	; menu options	
	;
	
	; TODO here clear nt1 and write roomid to it
	
;																|
; __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __|
;																|
	lda #<Title_Frame
	sta PrgmFramePtr
	lda #>Title_Frame
	sta PrgmFramePtr+1
	
	jmp (PrgmFramePtr)
; 															END |
; ______________________________________________________________|


; _______________________________________________________________
; 																|
;				blablabslbskjdsh titleframe	poop				|
; 																|
Title_Frame:
; Scroll first
	lda NeedScroll
	beq @Buttons
	
	jsr Title_Scroll

@Buttons:
; check buttons
	lda #PAD_START
	jsr CheckButtons
	beq @HandleSelect

; Check pressed index
	lda TitleMenuIndex
	cmp #TITLE_START
	bne @NotDungeon

; We dungeon, queue scroll for next frames 
	lda #1
	sta NeedScroll
	jmp @StdFrame

@NotDungeon:
	; TODO: handle other sub title states, eventually
	
@HandleSelect:
	lda #PAD_SELECT
	jsr CheckButtons
	beq @StdFrame
	
	; cycle menu options 
	lda TitleMenuIndex
	cmp #TITLE_HINTS 
	beq @Wraparound
	
	inc TitleMenuIndex
	jmp @StdFrame

@Wraparound:
	lda #TITLE_START
	sta TitleMenuIndex
	
@StdFrame:
	; bueines as usual.	
	; cycle seed
	inc Seed
	
	; draw any sprites
	jsr handler_Cells
	
; Wait out frame and report to program
	jsr ppu_update
	
	jmp mainloop


Title_Scroll:	
	lda ScrollY
	clc
	adc #$10
	sta ScrollY
; Have we rolled down to NT2?
	cmp #$EF
	bcc @Done
; Set scroll to 0 and take me to the DUNGEON!!!!!!!!!!!!!!!!!!!
	lda #0
	sta ScrollY
	lda #2
	sta ScrollNt
	lda #0
	sta NeedScroll
	lda #MODE_DUNGEON
	sta PrgmMode
	lda #1
	sta PrgmMode_Diaper
	lda #120
	sta fairy_X
	
@Done:
	rts

	
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
