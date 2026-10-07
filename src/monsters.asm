;
; Beasts. (evil)
;
.include "monsters.inc"			; [\__/]
.include "prgm.inc"				;|      \
.include "dungeon_room.inc"		;   '  ' |
.include "ppu_utility.inc"		;  		  \
.debuginfo+						;  /w  'T' |
.smart							;  v ^VvvV^
								;   ^WwwwW\
								;  \______/
								; /

.segment "ZEROPAGE"
dogs_States:		.res 2 ; Beast info
dogs_Timers:		.res 2 ; In-animation counter
dogs_AnimStates:	.res 2 ; Meta-animation counter
dogs_Momentum:	.res 2 ; Animation x-direction
MarkedForDeath:	.res 1 ; Kill flag

.segment "BSS"
cells_dog0:	.res 65
cells_dog1:	.res 65

; _______________________________________________________________
;																|
; 						Summoning routine						| 
; 																|
.segment "CODE"
.proc create_dogs
;																|
; __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __| Preparation
;																|
DogSeed := Scratch+0
DogIndex := Scratch+1
DogPosXList := Scratch+2 ; +3
DogPosX := Scratch+4
DogCellsPtr := TmpPtr
ArrangeBits := Scratch+5

; initialize all doggies
	lda #0
	sta dogs_States
	sta dogs_States+1

	sta ArrangeBits
	
	sta dogs_Timers
	sta dogs_Timers+1

	sta dogs_AnimStates
	sta dogs_AnimStates+1
	
	sta MarkedForDeath

	lda #1
	sta dogs_Momentum
	sta dogs_Momentum+1	
	
	ldx #0
:
	sta cells_dog0, X
	inx
	cpx #(65+65)
	bne :-
;																|
; __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __| At fate's hand, beast's spirit awakens
;																|
; Dogs amount?
	ldx #0
	ldy #0
	lda RoomSeed
@b7and6:
	asl
	bcc :+
	inc dogs_States, X
	inx
:
	iny
	cpy #2
	bne @b7and6
	
; Dogs arrange?
	ldy dogs_States+0
	beq @Cells
	
	; flag dungeon
	lda DungeonInfo
	ora #%1
	sta DungeonInfo 

	lda RoomSeed
	asl
	asl
	asl
	bcc :+ ; Next bit
	lda ArrangeBits
	ora #%00000010
	sta ArrangeBits
	
	lda RoomSeed
	asl
	asl
	asl
:
	asl
	bcc @Arrange
	lda ArrangeBits
	ora #%00000001
	sta ArrangeBits
	
@Arrange:
	lda ArrangeBits
	cmp #%10
	bne :+
	lda #56
	jmp :++
:
	cmp #%01
	bne :++
	lda #(56+128)
:
	sta DogPosXList+0
	lda dogs_States+1
	beq @Cells
	lda #(56+64)
	sta DogPosXList+1
	jmp @Cells
:
	lda dogs_States+1
	bne :+
	lda #56+64
	sta DogPosXList+0
	jmp @Cells
:
	lda #56
	sta DogPosXList+0
	lda #(56+128)
	sta DogPosXList+1
;																|
; __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __| Cells filled with life, spirit given being
;																|
@Cells:
	lda #0
	sta DogIndex
@DogsLoop:
	ldy DogIndex
	lda dogs_States, Y
	; if no dog
	beq @NextDog
	
; Set Xpos for this dog and set its cell pointer
	lda DogPosXList, Y
	sta DogPosX

	tya
	asl
	tay
	lda ptr_table_cells_dogs, Y
	sta DogCellsPtr
	lda ptr_table_cells_dogs+1, Y
	sta DogCellsPtr+1
	
; Go through cells list and add ptr to first open space
	ldx #0
:
	lda cells_Ptrs, X
	beq :+
	inx
	inx
	jmp :-
:
	lda DogCellsPtr
	sta cells_Ptrs, X
	lda DogCellsPtr+1
	sta cells_Ptrs+1, X
	
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
	
	; DEBUG NOTE: b5 this to toggle visibilty
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
	cpy #2
	bne @DogsLoop

	rts

table_DogSp:
.byte $24, $00, $02,    $24, $00, $08
.byte $2C, $01, $00,    $2C, $02, $04,    $2C, $03, $08,    $2C, $04, $0C
.byte $34, $01, $00,    $34, $05, $04,    $34, $06, $08,    $34, $07, $0C
.byte $38, $01, $00,    $3C, $08, $04,    $3C, $09, $08,    $3C, $0A, $0C
.byte $43, $0B, $00,    $43, $0C, $FD

.endproc

ptr_table_cells_dogs:
.word cells_dog0
.word cells_dog1

;															END |
; ______________________________________________________________|



; _______________________________________________________________
; |                                                             |
; |                      	The beast							|
;																|
; Updates every frame, plays continuous 'events' for lifespan
.proc handler_dogs_Behavior
DogsIndex := Scratch+0
EventPtr := TmpPtr

	lda #00
	sta DogsIndex
;																|
; __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __| ; Cycle
;																|
@DogsLoop:
	ldx DogsIndex
	lda dogs_States, X
	asl	
	tax
	lda table_dogs_Behaviors, X
	sta EventPtr
	lda table_dogs_Behaviors+1, X
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

table_dogs_Behaviors:
.word dogs_Behavior_NA
.word dogs_Behavior_Wait
.word dogs_Behavior_Hunt
.word dogs_Behavior_Retreat
.word dogs_Behavior_KillYou

dogs_Behavior_NA:
	rts
;																|
; __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __| The beast, well humored, lies in wait
;																|
dogs_Behavior_Wait:
	lda NextRoomTimer
	beq @ThatDogDontHunt
	
	ldx DogsIndex
	lda #2
	sta dogs_States, X
	
@ThatDogDontHunt:
	rts
;																|
; __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __| Seeing no other course, its prey tempts fate
;																|
dogs_Behavior_Hunt:
; Setup cells ptr 
	ldx DogsIndex
	txa
	asl
	tax
	lda ptr_table_cells_dogs, X
	sta TmpPtr2
	lda ptr_table_cells_dogs+1, X
	sta TmpPtr2+1

; Take a peek, doggy	

	ldx DogsIndex
	lda dogs_AnimStates, X
	cmp #1
	beq @PeekPt1
	cmp #2
	beq @PeekPt2

@PeekPt0:	
; Open your door, doggy!!
	inc dogs_Timers, X
	lda dogs_Timers, X
	cmp #$40
	bne @Done
	lda #$00
	sta dogs_Timers, X
	
	ldx #0
	ldy #3
@DoorsLoop:
	lda object_Boxes_Right, X
	cmp (TmpPtr2), Y
	bcc :+
	lda object_Boxes_Left, X
	cmp (TmpPtr2), Y	
	bcc @Door
:
	inx
	jmp @DoorsLoop
@Door:
; Found the door.
; A successful hunt..?
	lda object_States, X
	beq :+
	; Door has already been opened. Lunchtime soon!
	lda #1
	sta MarkedForDeath
	; Next animation
	ldx DogsIndex
	inc dogs_AnimStates, X
	; Add to timer
	lda NextRoomTimer
	clc
	adc #$80
	sta NextRoomTimer
	
	jmp @Done
:
	
; Queue object
	txa
	jsr object_QueueBehavior
	; next anim state
	ldx DogsIndex
	inc dogs_AnimStates, X
	jmp @Done

@PeekPt1:
	jsr dogs_Anim_PeekPaw
	jmp @Done
	
@PeekPt2:
	lda #1
	sta dogs_Momentum, X
	jsr dogs_Anim_PeekHead
	
	lda dogs_AnimStates, X
	cmp #3
	bne @Done

; Peek is over. Lunchtime?	
	ldx DogsIndex
	lda #$03
	clc
	adc MarkedForDeath
	sta dogs_States, X
	; Reset animation flags
	lda #$00
	sta dogs_AnimStates
	sta dogs_AnimStates+1
	; Set a timer in case we're death
	lda MarkedForDeath
	beq @Done
	lda #$80
	sta dogs_Timers

@Done:
	rts
;																|
; __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __| The beast finds nothing to kill, and retreats
;																|
dogs_Behavior_Retreat:
	; Setup sprite ptr 
	ldx DogsIndex
	txa
	asl
	tax
	lda ptr_table_cells_dogs, X
	sta TmpPtr2
	lda ptr_table_cells_dogs+1, X
	sta TmpPtr2+1

; Take five, doggy	

	ldx DogsIndex
	lda dogs_AnimStates, X
	bne @HidePt1

@HidePt0:
; Wait a sec
	inc dogs_Timers, X
	lda dogs_Timers, X
	cmp #32
	bne @Done

; Initialize retreat animation
	inc dogs_AnimStates, X
	lda #13
	sta dogs_Timers, X
	lda #$FF
	sta dogs_Momentum, X
	jmp @Done
	
@HidePt1:
	dec dogs_Timers, X
	dec dogs_Timers, X
	jsr dogs_Anim_PeekHead
	
	lda dogs_AnimStates, X
	cmp #2
	bne @Done
	
; Done hiding
	
; Hide paw
	ldy #(14*4)
	lda #$FF
	sta (TmpPtr2), Y
	ldy #(15*4)
	sta (TmpPtr2), Y
; Kill doggy
	lda #0
	sta dogs_States, X
	
@Done:
	rts	
;																|
; __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __| The beast takes its trophy, and trial completes
;																|
dogs_Behavior_KillYou:
; wait a tick
	dec dogs_Timers
	bne @Done
	
; change mode and fill diaper
	lda #MODE_DEATH
	sta PrgmMode
	
	lda #1
	sta PrgmMode_Diaper
	
@Done:
	rts
;																|
; __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __| ; Animations
;																|
dogs_Anim_PeekPaw:
	ldy #(14*4+3) ; initial paw cell 
@PeekLoop:
; Move the dog's paw forward 18 steps, stop for 6, then backward for another 6. Then stop.
	lda (TmpPtr2), Y
	clc
	adc dogs_Momentum, X
	sta (TmpPtr2), Y
	iny
	iny
	iny
	iny
	cpy #((14*4+3)+(2*4)) ; final paw cell
	bne @PeekLoop
	
	ldx DogsIndex
	inc dogs_Timers, X
	lda dogs_Timers, X
	cmp #18
	bne :+
	
	; Move paw sprite to front
	ldy #(14*4+2)
	lda (TmpPtr2), Y
	eor #%00100000
	sta (TmpPtr2), Y
	
	; Stop motion
	lda #$00
	sta dogs_Momentum, X
	jmp @Done
	
:
	cmp #23
	bne :+
	
	lda #$FF
	sta dogs_Momentum, X
:
	cmp #28
	bne :+

	lda #$00
	sta dogs_Momentum,X
:	
	cmp #33
	bne @Done
	
	ldx DogsIndex
	lda #0
	sta dogs_Timers, X
	inc dogs_AnimStates, X

@Done:

	rts



dogs_Anim_PeekHead:

	ldy #3
@PeekLoop:
; Move the dog forward 13 steps total
	lda (TmpPtr2), Y
	clc
	adc dogs_Momentum, X
	sta (TmpPtr2), Y
	iny
	iny
	iny
	iny
	cpy #59
	bne @PeekLoop
	
	ldx DogsIndex
; Inc timer
	inc dogs_Timers, X
	lda dogs_Timers, X
	bne :+
	inc dogs_AnimStates, X
	jmp @Done 
:
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
	bne @Done
	
	lda #0
	sta dogs_Timers, X
	inc dogs_AnimStates, X
	jmp @Done

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
	
@Done:

	rts

.endproc
;															END |
; ______________________________________________________________|