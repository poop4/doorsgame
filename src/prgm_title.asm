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
	lda #$10
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
;																|
; __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __| ; Titlescreen graphix
;																|
	lda #$00
	sta ScrollNt

; Title BG
	lda #OBJ_DUERER
	ldx #3
	ldy #4
	jsr create_object ;cheeky room object

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
	
; Subtitle BG
	ldx #3
	ldy #7
	lda #<table_tileROM_string_Subtitle
	sta TmpPtr
	lda #>table_tileROM_string_Subtitle
	sta TmpPtr+1
	jsr create_TextString
; GAME A
	ldx #5
	ldy #11
	lda #<table_tileROM_string_GAMEA
	sta TmpPtr
	lda #>table_tileROM_string_GAMEA
	sta TmpPtr+1
	jsr create_TextString
; GAME B 
	ldx #5
	ldy #13
	lda #<table_tileROM_string_GAMEB
	sta TmpPtr
	lda #>table_tileROM_string_GAMEB
	sta TmpPtr+1
	jsr create_TextString
; TM AND COPYRIGHT 1995 POOP CORP
	ldx #4
	ldy #23
	lda #<table_tileROM_string_Copyright
	sta TmpPtr
	lda #>table_tileROM_string_Copyright
	sta TmpPtr+1
	jsr create_TextString
; ALL RIGHTS RESERVED 
	ldx #4
	ldy #25
	lda #<table_tileROM_string_AllRightsReserved
	sta TmpPtr
	lda #>table_tileROM_string_AllRightsReserved
	sta TmpPtr+1
	jsr create_TextString
; POOCO
	ldx #4
	ldy #20
	lda #<table_tileROM_POOCO_Top
	sta TmpPtr
	lda #>table_tileROM_POOCO_Top
	sta TmpPtr+1
	jsr create_TextString
	ldx #4
	ldy #21
	lda #<table_tileROM_POOCO_Bottom
	sta TmpPtr
	lda #>table_tileROM_POOCO_Bottom
	sta TmpPtr+1
	jsr create_TextString
	
; attribute for padlock
	lda $2002
	lda #$23
	sta $2006
	lda #$DB
	sta $2006
	lda #%01010101
	sta $2007
; attribute for pooco
	lda #$23
	sta $2006
	lda #$E8
	sta $2006
	lda #%00001000
	sta $2007
	lda #%00001010
	sta $2007
	sta $2007
	sta $2007
	sta $2007
	sta $2007
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
	cmp #TITLE_START_A
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
	
	; set timer
	lda #$20
	sta ButtonsTimer 
	
	; cycle menu options
	lda TitleMenuIndex
	cmp #TITLE_START_B
	beq @Wraparound
	
	inc TitleMenuIndex
	jmp @StdFrame

@Wraparound:
	lda #TITLE_START_A
	sta TitleMenuIndex
	
@StdFrame:
	; bueines as usual.	
	
; Draw title index pointer!

; (First clear spots it could be)
	ldx #3
	ldy #11
	
	jsr PPU_ON_AddressTile
	
	lda #$01
	sta NmtUpdateRAM, Y
	iny
	lda #$FF
	sta NmtUpdateRAM, Y
	iny
	sty Nmt_Diaper
	
	ldx #3
	ldy #13
	
	jsr PPU_ON_AddressTile
	
	lda #$01
	sta NmtUpdateRAM, Y
	iny
	lda #$FF
	sta NmtUpdateRAM, Y
	iny
	sty Nmt_Diaper

; Write pointer!
	ldx #3
	lda TitleMenuIndex
	asl
	clc
	adc #11
	tay
	
	jsr PPU_ON_AddressTile
	
	lda #$01
	sta NmtUpdateRAM, Y
	iny
	lda #$58
	sta NmtUpdateRAM, Y
	iny
	sty Nmt_Diaper
	
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
.byte $1F,$0D,$00,$20,  $1F,$0E,$00,$30,  $1F,$10,$00,$40,  				  $1F,$10,$00,$60
.byte 									  $20,$11,$00,$3D,  $20,$11,$20,$4B,  $20,$11,$00,$5D,  $20,$11,$20,$6B
.byte $26,$0D,$80,$20,  $27,$0F,$00,$30,  $26,$10,$80,$40,					  $26,$10,$80,$60

table_tileROM_string_Subtitle:
.byte _P,_R,_I,_S,_O,_N,__,_O,_F,__,_E,_T,_E,_R,_N,_A,_L,__,_D,_I,_C,_E,__,_R,_O,_L,_L, $FF

table_tileROM_string_GAMEA:
.byte _G,_A,_M,_E,__,_A, $FF

table_tileROM_string_GAMEB:
.byte _G,_A,_M,_E,__,_B,__,__,_LOCK,$FF

table_tileROM_string_Copyright:
.byte _T,_M,__,_A,_N,_D,__,_COPYRIGHT,__,$01,$09,$09,$05,__,_P,_O,_O,_P,__,_C,_O,_R,_P, $FF

table_tileROM_string_AllRightsReserved:
.byte _A,_L,_L,__,_R,_I,_G,_H,_T,_S,__,_R,_E,_S,_E,_R,_V,_E,_D,_PERIOD, $FF

table_tileROM_POOCO_Top:
.byte $66,$69,$66,$69,$66,$69,$66,$69,$66,$69, $FF

table_tileROM_POOCO_Bottom:
.byte $67,$68,$6A,$68,$6A,$68,$6A,$6B,$6A,$68, $FF

title_palette:
; bg
.byte $0F,$2D,$10,$10
.byte $0F,$0F,$28,$00
.byte $0F,$00,$17,$00
.byte $0F,$00,$00,$00
; sp
.byte $0F,$2D,$10,$10
.byte $0F,$00,$00,$00
.byte $0F,$00,$00,$00
.byte $0F,$00,$00,$00