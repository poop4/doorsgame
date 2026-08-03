;
; Top level dungeon management
; Calls dungeon room setup subroutines in accordance to RNG
; Manages per-frame behavior, namely dungeon events (pass, death, entities, interactions)
;

.debuginfo +
.smart
.include "dungeon.inc"
.include "system.inc"
.include "main.inc"
.include "buttons.inc"
.include "nmi.inc"
.include "fairy.inc"
.include "bg_utility.inc"
.include "dungeon_room.inc"


; jumped to every time a new level needs initialized
.segment "CODE"
Dungeon_Load:
	; first things first
	jsr ppu_off
	; TODO: parameterized palette selection (based on doors passed maybe?)
	ldx #0
:
	lda dungeon_palette, x
	sta paletteRAM, x
	inx
	cpx #32
	bne :-
	; clear nt (0 for now, 3 later since we want to eventually scroll to the next room)
	lda #$20
	jsr bgSetup
	; draw walls
	lda #$20
	sta PPUADDR
	lda #$00
	sta PPUADDR
	ldy #0
	ldx #0
	lda #TILE_WALLS
:
	sta PPUDATA
	inx
	cpx #32
	bne :-
	ldx #0
	iny
	cpy #10
	bne :-
	; Set attr
	lda PPUSTATUS
	lda #$23
	sta PPUADDR
	lda #$C9
	sta PPUADDR
	ldx #00
	ldy #00
:
	lda #%01000100
	sta PPUDATA
	lda #%00010001
	sta PPUDATA 
	inx 
	cpx #3
	bne :-
	lda PPUSTATUS
	lda #$23
	sta PPUADDR
	lda #$D1
	sta PPUADDR
	ldx #00
	iny
	cpy #2
	bne :-
; Fairy initialize
	lda #192
	sta CursorY
	lda #FAIRY_NORMAL
	sta CursorState
	;
	; TODO 
	; clock dungeon rng 

;  Initialize CursorBoundsBox
	lda #$10
	sta CursorBoundsBox + LEFT
	lda #$30
	sta CursorBoundsBox + TOP
	lda #$EF
	sta CursorBoundsBox + RIGHT 
	lda #$DF
	sta CursorBoundsBox + BOTTOM	
; Generate room
	jsr GenerateRoom
; Send to frame
	lda #<Dungeon_Frame
	sta PrgmFramePtr
	lda #>Dungeon_Frame
	sta PrgmFramePtr+1	
	jmp (PrgmFramePtr)


Dungeon_Frame:
; TODO RIGHT NOW!!!
; scroll shit

; Fairy stuff
	jsr FairyBoundsCheck
	jsr FairyMove_Player
; Button press?
	lda ButtonsTimer
	bne @NoButtonPress
	lda Buttons
	and #PAD_A
	beq @NoButtonPress
	lda #$10
	sta ButtonsTimer
	jsr FairyCheckInteract
@NoButtonPress:
	lda ButtonsTimer
	beq @NoButtonsTimeout
	dec ButtonsTimer
@NoButtonsTimeout:
; Room transition?
	lda DoorsTimer
	beq @NoNextRoom
	lda #FAIRY_STOPPED
	sta CursorState
	dec DoorsTimer
	bne @NoNextRoom
; Room transition.
	jmp Dungeon_Load
@NoNextRoom:
; Spr graphix 
	jsr FairyDraw
	jsr ppu_update
	jmp mainloop
	

