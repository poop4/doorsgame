;
;

.smart
.debuginfo+
.include "monsters.inc"
.include "system.inc"
.include "main.inc"
.include "nmi.inc"
.include "dungeon_room.inc"
.include "rng.inc"
.include "ppu_utility.inc"

.segment "ZEROPAGE"
DogsState:		.res 2 ; indicates which event is happening right now (b6,7 used for animation state)
DogsTimer:		.res 2 ; used to control events/animations over time
DogsAnimState:	.res 2
DogsMomentum:	.res 2 ; controls sprite move direction

.segment "BSS"
Dog0Cells:	.res 65
Dog1Cells:	.res 65

.segment "CODE"
.proc CreateDogs
DogSeed := Scratch+0
DogIndex := Scratch+1
DogPosXList := Scratch+2
; +3 
DogPosX := Scratch+4
DogCellsPtr := TmpPtr

; initialize all doggies
	lda #0
	sta DogsTimer
	sta DogsTimer+1
	sta DogsAnimState
	sta DogsAnimState+1
	lda #1
	sta DogsMomentum
	sta DogsMomentum+1

	ldx #0
:
	sta Dog0Cells, X
	inx
	cpx #(65+65)
	bne :-

; begin RNG selection 
	lda RoomSeed
	sta DogSeed
	
;
; CONSTRUCTION ZONE 
;
	
	lda #1
	sta DogsState
	
	lda #56
	sta DogPosXList
	lda #(56+64)
	sta DogPosXList+1

;
; CONSTRUCTION ZONE
;	
	lda #0
	sta DogIndex
@DogsLoop:	
	ldy DogIndex
	lda DogsState, Y
	; if no dog
	beq @NextDog
	
; Set Xpos for this dog and set its cell pointer
	lda DogPosXList, Y
	sta DogPosX

	tya
	asl
	tay
	lda table_DogCellsPtrs, Y
	sta DogCellsPtr
	lda table_DogCellsPtrs+1, Y
	sta DogCellsPtr+1
	
; Go through cells list and add ptr to first open space
	ldx #0
:
	lda CellsList, X
	beq :+
	inx
	inx
	jmp :-
:
	lda DogCellsPtr
	sta CellsList, X
	lda DogCellsPtr+1
	sta CellsList+1, X
	
	ldx #0
	ldy #0	
@CreateCells:
; Load all dog sprites into shadow-shadow-oam
	lda table_DogSp, X
	sta (DogCellsPtr), Y
	inx
	iny
	
	lda table_DogSp, X
	sta (DogCellsPtr), Y
	inx
	iny
	
	lda #%00100001
	sta (DogCellsPtr), Y
	iny
	
	lda table_DogSp, X
	clc
	adc DogPosX
	sta (DogCellsPtr), Y
	inx
	iny
	
	cpx #$30
	bne @CreateCells
	
; Insert terminator
	lda #$FF
	sta (DogCellsPtr), Y
	
@NextDog:
	ldy DogIndex
	iny
	sty DogIndex
	cpy #3
	bne @DogsLoop
	
	rts
.endproc

table_DogCellsPtrs:
.word Dog0Cells
.word Dog1Cells

table_DogSp:
.byte $24, $02, $02,    $24, $02, $08
.byte $2C, $03, $00,    $2C, $15, $04,    $2C, $04, $08,    $2C, $05, $0C
.byte $34, $03, $00,    $34, $06, $04,    $34, $07, $08,    $34, $08, $0C
.byte $38, $03, $00,    $3C, $09, $04,    $3C, $0A, $08,    $3C, $0B, $0C
.byte $43, $0C, $00,    $43, $0D, $FD



; Handles events for active doggies
.proc HandleDogsEvents
DogsIndex := Scratch+0
EventPtr := TmpPtr

	lda #00
	sta DogsIndex

@DogsLoop:
	ldx DogsIndex
	lda DogsState, X
	asl	
	tax
	lda table_DogsEvents, X
	sta EventPtr
	lda table_DogsEvents+1, X
	sta EventPtr+1
	jsr trampoline

	ldx DogsIndex
	inx
	stx DogsIndex
	cpx #2
	bne @DogsLoop
	
	rts

trampoline:
	; whee!
	jmp (EventPtr)

table_DogsEvents:
.word event_NoDoggy
.word event_DogWait
.word event_DogHunt
.word event_DogRetreat
.word event_DogBullshitkillyou

event_NoDoggy:
	rts

; listen for door open, then hunt
event_DogWait:
	lda DoorsTimer
	beq @ThatDogDontHunt
	
	ldx DogsIndex
	lda #2
	sta DogsState, X
	
@ThatDogDontHunt:
	rts


; peek in positive direction, then check own x against player
event_DogHunt:
	
	; setup sprite ptr for animations
	ldx DogsIndex
	txa
	asl
	tax
	lda table_DogCellsPtrs, X
	sta TmpPtr2
	lda table_DogCellsPtrs+1, X
	sta TmpPtr2+1

	ldx DogsIndex
	lda DogsAnimState, X
	bne @PeekPt2
@PeekPt1:
	jsr anim_DogPeek_Paw
	jmp @FrameEnd
	
@PeekPt2:
	lda #1
	sta DogsMomentum, X
	jsr anim_DogPeek_Body
	lda DogsAnimState, X
	cmp #2
	bne @FrameEnd
	
	ldx DogsIndex
	lda #4
	sta DogsState, X

@FrameEnd:
	
	rts

; peek in negative direction
event_DogRetreat:

	rts

anim_DogPeek_Paw:

	ldy #(14*4+3) ; initial paw cell 
@PeekLoop:
; Move the dog's paw forward 18 steps, stop for 6, then backward for another 6. Then stop.
	lda (TmpPtr2), Y
	clc
	adc DogsMomentum, X
	sta (TmpPtr2), Y
	iny
	iny
	iny
	iny
	cpy #((14*4+3)+(2*4)) ; final paw cell
	bne @PeekLoop
	
	ldx DogsIndex
	inc DogsTimer, X
	lda DogsTimer, X
	cmp #18
	bne :+
	
	; Move paw sprite to front
	ldy #(14*4+2)
	lda (TmpPtr2), Y
	eor #%00100000
	sta (TmpPtr2), Y
	
	; Stop motion
	lda #$00
	sta DogsMomentum, X
	jmp @FrameEnd
	
:
	cmp #23
	bne :+
	
	lda #$FF
	sta DogsMomentum, X
:
	cmp #28
	bne :+

	lda #$00
	sta DogsMomentum,X
:	
	cmp #33
	bne @FrameEnd
	
	ldx DogsIndex
	lda #0
	sta DogsTimer, X
	inc DogsAnimState, X

@FrameEnd:

	rts



anim_DogPeek_Body:

	ldy #3
@PeekLoop:
; Move the dog forward 13 steps total
	lda (TmpPtr2), Y
	clc
	adc DogsMomentum, X
	sta (TmpPtr2), Y
	iny
	iny
	iny
	iny
	cpy #59
	bne @PeekLoop
	
	ldx DogsIndex
	inc DogsTimer, X
	lda DogsTimer, X
; Conditional chain, flip sprite priority
	cmp #4
	bne :+	
	ldy #(5*4+2)
	ldx #3
	jmp @SpriteColumnOverBG
:
	cmp #8
	bne :+
	ldy #(1*4+2)
	lda (TmpPtr2), Y
	eor #%00100000
	sta (TmpPtr2), Y
	ldy #(4*4+2)
	ldx #3
	jmp @SpriteColumnOverBG
:
	cmp #12
	bne :+
	ldy #(3*4+2)
	ldx #3
	jmp @SpriteColumnOverBG

:
	cmp #13
	bne @FrameEnd
	
	lda #0
	sta DogsTimer, X
	inc DogsAnimState, X
	jmp @FrameEnd

@SpriteColumnOverBG:
	lda (TmpPtr2), Y
	eor #%00100000
	sta (TmpPtr2), Y
	
	tya
	clc
	adc #(4*4)
	tay
	
	dex
	bne @SpriteColumnOverBG
	
@FrameEnd:

	rts



event_DogBullshitkillyou:

	;TODO
	rts
	
.endproc
