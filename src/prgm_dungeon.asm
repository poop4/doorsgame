;
; Top level dungeon management
;

.debuginfo +
.smart
.include "prgm_dungeon.inc"
.include "system.inc"
.include "prgm.inc"
.include "buttons.inc"
.include "nmi.inc"
.include "fairy.inc"
.include "ppu_utility.inc"
.include "dungeon_room.inc"
.include "monsters.inc"
.include "score.inc"
.include "rng.inc"

; _______________________________________________________________
; 																|
;					World initialization						|
; 																|
.segment "CODE"
Dungeon_Load:
; TEST seeds
	;lda VALUE
	;sta Seed

; Disable rendering
	jsr ppu_off
	
; Upload palette
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

; Set attr
; TODO replace this with dynamic attribute mod in create_object
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
	lda #$00
:
	sta cells_Ptrs, X
	inx
	cpx #$10
	bne :-

; Generate room
	jsr create_Room
	
; Initialize score & stage
	jsr handler_ScoreDisplay

	jsr handler_StageDisplay		
	
	lda #$0A
	sta points_PerDoor
	
; Initialize fairy
	jsr create_fairy

; Initialize doggies
	jsr create_dogs

; Send to frame
	lda #<Dungeon_Frame
	sta PrgmFramePtr
	lda #>Dungeon_Frame
	sta PrgmFramePtr+1	
	jmp (PrgmFramePtr)

;															END |
; ______________________________________________________________|


; _______________________________________________________________
; 																|
; 							World								|
;																|

; __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __| ; Main routine
;																|
Dungeon_Frame:
; Scroll?
	lda NeedScroll
	beq :+
	jsr Dungeon_Scroll
	jmp @Done
:

; Button presses?	
	lda fairy_State
	cmp #FAIRY_STOPPED
	beq @FairyDone
; A
	lda #PAD_A
	jsr CheckButtons
	beq :+
	; Check for interactable objects, set cooldown
	jsr fairy_CheckInteract
	lda #$10
	sta ButtonsTimer
; Dpad	
:
	lda #PAD_LEFT
	jsr CheckButtons
	beq :+
	jsr fairy_MoveLeft
:
	lda #PAD_UP
	jsr CheckButtons
	beq :+
	jsr fairy_MoveUp
:
	lda #PAD_RIGHT
	jsr CheckButtons
	beq :+
	jsr fairy_MoveRight
:
	lda #PAD_DOWN
	jsr CheckButtons
	beq :+
	jsr fairy_MoveDown
:	
; Apply velocity and check bounds
	jsr fairy_Move
	
	jsr fairy_BoundsCheck

@FairyDone:	
	
; Handle all entity events for this frame
	jsr handler_fairy_Behavior

	jsr handler_dogs_Behavior
	
	jsr handler_object_Behavior
	
	jsr handler_scorePips

; Room transition?
	lda NextRoomTimer
	beq @Done ; nope
	
	; Door event has begun, stop cursor
	lda #FAIRY_STOPPED
	sta fairy_State
	
	dec NextRoomTimer
	bne @Done
	
; Timer done, next dungeon room
	jsr Dungeon_Transition

@Done:
	jsr ppu_update
	
	jmp mainloop
	
;																|
; __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __| ; Stage scroll
;																|

Dungeon_Scroll:
; Wait half a second? (for score & room)
	lda ScrollY
	cmp #$D4
	bcs :+
; Tick score points
	lda PrgmTimer_4f
	bne :+

	lda points
	beq :+
	; Bucket
	dec points
	inc score
	
	jsr handler_ScoreDisplay
:
; Increment scroll pos
	lda ScrollY
	sec
	sbc #$01
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

;																|
; __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __| ; Stage transition
;																|

Dungeon_Transition:
; stage count	
	inc stage

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
;															END |
; ______________________________________________________________|
