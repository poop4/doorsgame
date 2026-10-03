;
; routines related to calculating, storing and displaying score-esque entities
;

.include "score.inc"
.include "system.inc"
.include "nmi.inc"
.include "prgm.inc"
.include "ppu_utility.inc"
.debuginfo+
.smart

.segment "ZEROPAGE"
points:			.res 1 ; # of 10-increments to score, this frame
score:			.res 2 ; same deal, this game
stage:			.res 1
tileRAM_score:		.res 5
tileRAM_stage:		.res 3

points_PerDoor:		.res 1 ; number of points awarded for open door


.segment "CODE"
; _______________________________________________________________
;																|
;				score processing/rendenering					|
;																|
; Recomputes score digits and writes to screen (call after roomgen)
; rendering agnostic
handler_ScoreDisplay:

; Reinitialize digits
	lda #$00
	ldx #0
:
	sta tileRAM_score, X
	inx
	cpx #5
	bne :-
	
; Write tiles to each place digit	
	ldy score
	beq @WriteToNametable
@SetupTilesLoop:
	ldx #0
	inc tileRAM_score, X
:
	lda tileRAM_score, X
	cmp #$0A
	bne :+
	lda #$00
	sta tileRAM_score, X
	inx
	inc tileRAM_score, X
	jmp :-
:
	dey
	bne @SetupTilesLoop

	
; Write place digits to nametable buffer
@WriteToNametable:
	lda #$20
	ldy ScrollNt
	bne :+
	clc
	adc #$08
:
	ldx Nmt_Diaper
	sta NmtUpdateRAM, X; Hi
	inx
	lda #$02
	sta NmtUpdateRAM, X; Lo
	inx
	
; This will always be 12 characters
	lda #12
	sta NmtUpdateRAM, X ; Amt
	inx
	
; "score"
	ldy #0
:
	lda table_tileROM_score, Y
	sta NmtUpdateRAM, X ; Tile
	inx
	iny
	cpy #6
	bne :-
	
; write tiles in reverse order stored
	ldy #5
:
	dey
	lda tileRAM_score, Y
	sta NmtUpdateRAM, X
	inx
	cpy #0
	bne :-

; Cheeky zero.
	lda #$00
	sta NmtUpdateRAM, X
	inx
	; stinky
	stx Nmt_Diaper
	
	rts
	

table_tileROM_score:
.byte _S,_C,_O,_R,_E,$FE
;																|
; __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __|
;																|

handler_StageDisplay:
; Same basic idea, just simpler. Increments value on call
; Reinitialize digits
	lda #$00
	ldx #0
:
	sta tileRAM_stage, X
	inx
	cpx #3
	bne :-
	
	ldy stage
	beq @WriteToNametable
@SetupTilesLoop:
	ldx #0
	inc tileRAM_stage, X
:
	lda tileRAM_stage, X
	cmp #$0A
	; Rollover
	bne :+
	lda #$00
	sta tileRAM_stage, X
	inx
	inc tileRAM_stage, X
	jmp :-
:
	dey
	bne @SetupTilesLoop
	
; Write place digits to nametable buffer
@WriteToNametable:
	lda #$20
	ldy ScrollNt
	bne :+
	clc
	adc #$08
:
	ldx Nmt_Diaper
	sta NmtUpdateRAM, X; Hi
	inx
	lda #$15
	sta NmtUpdateRAM, X; Lo
	inx
	
; Amt always 9
	lda #$09
	sta NmtUpdateRAM, X; Amt
	inx

; "stage "
ldy #0
:
	lda table_tileROM_stage, Y
	sta NmtUpdateRAM, X
	inx
	iny
	cpy #6
	bne :-
	
; Tiles in reverse order
ldy #3
:
	dey
	lda tileRAM_stage, Y
	sta NmtUpdateRAM, X
	inx
	cpy #0
	bne :-
	
	stx Nmt_Diaper
	
	rts

table_tileROM_stage:
.byte _S,_T,_A,_G,_E,$FE

;															END |
; ______________________________________________________________|


.segment "ZEROPAGE"
scorePip_Timers:		.res 4
scorePip_Momentum:		.res 4 ; used for movement

; note to self
; category order depends on who is "HOME" and "AWAY". "AWAY" have higher priority
.segment "BSS"
cells_scorePip0:		.res 13
cells_scorePip1:		.res 13
cells_scorePip2:		.res 13
cells_scorePip3:		.res 13


.segment "CODE"
; _______________________________________________________________
;																|
;						score corporeal							|
;																|
;
; __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __| ; Creation ritual
;																|
; Arguments:
; X,Y	sprite position reference
; A		point value
.proc create_scorePip

PipX := Scratch+0
PipY := Scratch+1
PipVal := Scratch+2
PipIndex := Scratch+3
PipTiles := Scratch+4; & 5
PipCellsPtr := TmpPtr

; Store parameters
	sta PipVal
	cmp #$0A
	bcc :+
	txa
	clc
	adc #$03
	jmp :++
:
	txa
:
	clc
	adc #$10
	sta PipX
	sty PipY 

; Clear scratch
	lda #$00
	sta PipTiles
	sta PipTiles+1
	
	ldx #0
@AllocPip:
; Find an open spot, store initial timer value
; then proceed to the rest of initialization
	lda scorePip_Timers, X
	beq @InitPipCells
	inx
	jmp @AllocPip
	
@InitPipCells:
; Set index +
; Initialize timer
	stx PipIndex
	lda #$30
	sta scorePip_Timers, X
	lda #$06
	sta scorePip_Momentum, X
	
; Determine tiles to use
; Same basic rollover technique
	ldy PipVal
@SetupTilesLoop:
	ldx #0
	inc PipTiles, X
:
	lda PipTiles, X
	cmp #$0A
	bne :+
	lda #$00
	sta PipTiles, X
	inx
	inc PipTiles, X
	jmp :-
:
	dey
	bne @SetupTilesLoop
		
; Finally allocate cells

; Insert cells memptr into active cells list
	lda PipIndex
	asl
	tax
	lda ptr_table_cells_scorePip, X
	sta PipCellsPtr
	lda ptr_table_cells_scorePip+1, X
	sta PipCellsPtr+1

	ldx #0
:
	lda cells_Ptrs+1, X
	beq :+
	inx
	inx
	jmp :-
:
	lda PipCellsPtr
	sta cells_Ptrs, X
	lda PipCellsPtr+1
	sta cells_Ptrs+1, X
	
; Write sprite data into cells memory

	ldx #0 ; Sprite idx
	ldy #0 ; Byte idx
@WriteCellsLoop:
; ypos, use sent value
	lda PipY
	sta (PipCellsPtr), Y
	iny
	
; tile ID
	cpx #0
	bne :+
	; First loop, always 0
	lda #$00
	jmp @WriteTile
:
	cpx #1
	bne :+
	; Loop 2. Nothing special
	lda PipTiles-1, X
	jmp @WriteTile
:
	; Loop 3, clear trailing zeros
	lda PipTiles-1, X
	bne @WriteTile
	lda #($FF-$30) ; 'empty' tile
	
@WriteTile:
	clc
	adc #$30 ; loc @ numerics in tilemem
	sta (PipCellsPtr), Y
	iny
	
; attr
	lda #%00000011
	sta (PipCellsPtr), Y
	iny
	
; xpos, sent value minus something
	lda PipX
	sta (PipCellsPtr), Y
	sec
	sbc #$06
	sta PipX
	iny
	
	inx
	cpx #3
	bne @WriteCellsLoop
	
; terminator
	lda #$FF
	sta (PipCellsPtr), Y
	
; Ok set timer, calc'd tiles, filled cells... i think that's it!
	
	rts

.endproc
;																|
; __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __| ; Life cycle
;																|
.proc handler_scorePips

PipsIndex := Scratch+0
PipCellsPtr := TmpPtr
	
	ldx #0
	stx PipsIndex
; Sift thru timers for active pips
@SearchPips:
	ldx PipsIndex
	lda scorePip_Timers, X
	bne @PipBehavior

	jmp @Done ; no pips we ball
	
@PipBehavior:
	stx PipsIndex
	
	; Grab cells 4l8r
	txa
	asl
	tax
	lda ptr_table_cells_scorePip, X
	sta PipCellsPtr
	lda ptr_table_cells_scorePip+1, X
	sta PipCellsPtr+1

; Act on timer value;
; travel upward for first few ticks,
; then twiddle thumbs and finally dealloc on 0
	ldx PipsIndex
	lda scorePip_Timers, X
	cmp #$22
	bcc @Timer
	
	and #%00000001
	bne @Timer
	
	dec scorePip_Momentum, X

	; Dec ypos of each sprite
	ldy #0
:
	lda (PipCellsPtr), Y
	sec
	sbc scorePip_Momentum, X
	sta (PipCellsPtr), Y
	iny
	iny
	iny
	iny
	cpy #12
	bne :-
	
@Timer:
	dec scorePip_Timers, X
	lda scorePip_Timers, X
	bne @Done
	
; Timer == 0, find & deallocate cells
	ldx #0
@SearchCells:
	lda cells_Ptrs, X
	cmp PipCellsPtr
	bne :+
	
	lda cells_Ptrs+1, X
	cmp PipCellsPtr+1
	bne :+
	
	lda #$00
	sta cells_Ptrs, X
	sta cells_Ptrs+1, X
	jmp @Done
:
	inx
	inx
	jmp @SearchCells
	
@Done:
	ldx PipsIndex
	inx
	stx PipsIndex
	cpx #4
	bne @SearchPips

	rts

.endproc

ptr_table_cells_scorePip:
.addr cells_scorePip0
.addr cells_scorePip1
.addr cells_scorePip2
.addr cells_scorePip3
;															END |
; ______________________________________________________________|

