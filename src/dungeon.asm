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
.include "ppu_utility.inc"
.include "dungeon_room.inc"
.include "monsters.inc"

.include "rng.inc"


; jumped to every time a new level needs initialized
.segment "CODE"
Dungeon_Load:

	; DEBUG TOOL DELETELATER
	lda Seed
	cmp #1
	bne :+
	lda #1
	sta NeedScroll
	lda #60
	sta CursorX

:

	; first things first
	jsr ppu_off
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
	
; Clear sprite object cells list
	ldx #0
	lda #0
:
	sta CellsList, X
	inx
	cpx #$10
	bne :-

; Generate room
	jsr GenerateRoom

; Initialize fairy
	jsr FairyCreate

; Initialize doggies
	jsr DogsCreate

; Send to frame
	lda #<Dungeon_Frame
	sta PrgmFramePtr
	lda #>Dungeon_Frame
	sta PrgmFramePtr+1	
	jmp (PrgmFramePtr)

;
;
;

Dungeon_Frame:
; Scroll?
	lda NeedScroll
	beq :+
	jsr Dungeon_Scroll
	jmp @End
:
; Button presses?	
	lda CursorState
	cmp #FAIRY_STOPPED
	beq @FairyDone
; A
	lda #PAD_A
	jsr CheckButtons
	beq :+
	; Check for interactable objects, set cooldown
	jsr FairyCheckInteract
	lda #$10
	sta ButtonsTimer
; Dpad	
:
	lda #PAD_LEFT
	jsr CheckButtons
	beq :+
	jsr FairyMove_Left
:
	lda #PAD_UP
	jsr CheckButtons
	beq :+
	jsr FairyMove_Up
:
	lda #PAD_RIGHT
	jsr CheckButtons
	beq :+
	jsr FairyMove_Right
:
	lda #PAD_DOWN
	jsr CheckButtons
	beq :+
	jsr FairyMove_Down
:	
; Apply velocity and check bounds
	jsr FairyMove
	
	jsr FairyBoundsCheck

@FairyDone:	
	
	jsr HandleFairyEvents

	jsr HandleDogsEvents

; Room transition?
	lda DoorsTimer
	beq @End ; nope
	
	; Door event has begun, stop cursor
	lda #FAIRY_STOPPED
	sta CursorState
	
	dec DoorsTimer
	bne @End
	
; Load next dungeon room
	jsr Dungeon_Transition

@End:
	jsr ppu_update
	
	jmp mainloop
	
;
;
;

Dungeon_Scroll:	
; Increment scroll pos
	lda ScrollY
	sec
	sbc #$05
	sta ScrollY
	bcc @DoneScrolling
	
	rts
	
@DoneScrolling:
; Turn on sprites
	lda #%00010000
	sta SpritesOn
; Reset scroll indicators
	lda #0
	sta ScrollY
	sta NeedScroll
	
	rts

;
;
;

Dungeon_Transition:
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
	
	; Signal state change
	lda #MODE_DUNGEON
	sta PrgmMode
	lda #1
	sta PrgmMode_Diaper
	
	rts
