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
; clear next nt
	lda ScrollNt
	asl
	asl
	clc
	adc #$20
	jsr bgSetup
	
; Side walls
	lda #$FE
	ldy #$00
	jsr bgDrawStripeY
	lda #$51
	iny
	jsr bgDrawStripeY
	lda #$52
	ldy #$1E
	jsr bgDrawStripeY
	lda #$FE
	iny
	jsr bgDrawStripeY
; Top wall
	lda #$FE
	ldy #$00
	jsr bgDrawStripeX
	lda #$50
	ldy #$01
	jsr bgDrawStripeX
; cleanup! (note to self: never read this code again please)
	jmp :++++
	ldx #$20
:
	lda ScrollNt
	asl
	asl
	clc
	adc #$20
	sta PPUADDR
	stx PPUADDR
	cpx #$3E
	beq :+
	lda #$FE
	sta PPUDATA
	lda #$53
	sta PPUDATA
	jmp :++
:
	lda #$54
	sta PPUDATA
	lda #$FE
	sta PPUDATA
:
	cpx #$3E
	beq :+
	txa
	clc
	adc #$1E
	tax
	jmp :---
:
	

	; Set attr
	lda PPUSTATUS
	lda ScrollNt
	asl
	asl
	clc
	adc #$23
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
	lda ScrollNt
	asl
	asl
	clc
	adc #$23
	sta PPUADDR
	lda #$D1
	sta PPUADDR
	ldx #00
	iny
	cpy #2
	bne :-
; Fairy initialize
	lda #200
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
	lda NeedScroll
	beq @DoFrame
		; We scroll
; Increment scroll pos
	lda ScrollY
	sec
	sbc #$02
	sta ScrollY
		; If rollover, finish up scroll
	bcc @DoneScrolling
		; No rollover, keep going
	jmp @End
@DoneScrolling:
; Turn on sprites
	lda #%00010000
	sta SpritesOn
; Reset scroll stuff
	lda #0
	sta ScrollY
	sta NeedScroll
@DoFrame:
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
; Queue scroll
	lda #$EF
	sta ScrollY
	lda ScrollNt
	eor #2
	sta ScrollNt
	lda #1
	sta NeedScroll
	; Turn OFF sprites
	lda #%00000000
	sta SpritesOn
	jmp Dungeon_Load
@NoNextRoom:
; Spr graphix 
	jsr FairyDraw
@End:
	jsr ppu_update
	jmp mainloop
	

