;
; Dungeon room system.
;
.debuginfo +
.smart
.include "dungeon_room.inc"
.include "system.inc"
.include "prgm.inc"
.include "nmi.inc"
.include "rng.inc"
.include "ppu_utility.inc"
.include "score.inc"

.segment "ZEROPAGE"
; local RNG for current room
RoomSeed: 				.res 1
; flags for entire dungeon 
DungeonInfo:			.res 1
; b0: dog seed?
; b1: bird seed?
; ...
; more later?

.segment "BSS"
; list of indices, used as offsets and to signify object IDs. init as FF
objects: 	.res 16
; 4 bytes each, holds collision info for room objects
object_Boxes_Left:		.res 16
object_Boxes_Top:		.res 16
object_Boxes_Right:		.res 16
object_Boxes_Bottom:	.res 16
; default 0, modified on interaction
object_States:	.res 16
; index for queued behaviors. init as FF
object_BehaviorQueue: .res 8

; _______________________________________________________________
; 																|
; 		A new world in place of where the old one had been		|
; 																|
.segment "CODE"
.proc create_Room
;																|
; __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __| ; Clear room objects
;																|
ScreenX := Scratch+0
ScreenY := Scratch+1
NtHi := Scratch+2
NtLo := Scratch+3
RandomBits := Scratch+4
toggle_Floor := Scratch+5

; Initialize room obj 
	lda #%0
	sta DungeonInfo
	
	ldx #0
@ClearRoomLoop:
	lda #$FF 
	sta objects, X
	cpx #$08
	bcs :+
	sta object_BehaviorQueue, X
:
	lda #$00
	sta object_States, X
	sta object_Boxes_Left, X
	sta object_Boxes_Top, X
	sta object_Boxes_Right, X
	sta object_Boxes_Bottom, X
	inx
	cpx #$10
	bne @ClearRoomLoop
; The old world is destroyed
;																|
; __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __| ; Bricks and rocks 
;																|
; Transfer global seed to this room
	lda Seed
	sta RoomSeed
; Initialize nt pointers (and toggle), start outer loop
	lda #$20
	sta NtHi
	lda #$42
	sta NtLo
	lda #0
	sta toggle_Floor
@RowLoop:
; Loop termination?
	lda NtHi
	cmp #$23
	bne @InitializeRow
	lda NtLo
	cmp #$A2 ; $20 more'n last row
	bne @InitializeRow
	jmp @DoneDrawingDungeon
@InitializeRow:
	ldx #0
	lda PPUSTATUS
	lda ScrollNt
	asl
	asl
	clc
	adc NtHi
	sta PPUADDR
	lda NtLo
	sta PPUADDR
; Increment address(es)
	lda NtLo
	clc
	adc #$20
	sta NtLo
	bcc :+
	inc NtHi
:
; Real quick, check if we should be drawing floor
	lda NtHi
	cmp #$21
	bne @DrawRow
	lda NtLo
	cmp #$62
	bne @DrawRow
	inc toggle_Floor
@DrawRow:
; Copy seed over for reading
	lda RoomSeed
	sta RandomBits
; (Clock for next iteration)
	lda RoomSeed
	jsr ClockRNG ; re: check your clobbers
	sta RoomSeed
	ldy #0
@ReadBits:
	lda RandomBits
	and #%11000000
	cmp #%11000000
	beq :+
	lda #$FE
	clc
	adc toggle_Floor
	jmp @DrawByte
:
	lda #$4E
	clc
	adc toggle_Floor
@DrawByte:
	sta PPUDATA
	lda RandomBits
	asl
	asl
	sta RandomBits
	iny
	cpy #4
	bne @ReadBits
	inx
	cpx #7
	bne @DrawRow
	jmp @RowLoop
@DoneDrawingDungeon:
;																|
; __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __| ; Doors
;																|
; Create door objects
	lda #OBJ_DOOR
	ldx #6
	ldy #4
	jsr create_object
	lda #OBJ_DOOR
	ldx #14
	ldy #4
	jsr create_object
	lda #OBJ_DOOR
	ldx #22
	ldy #4
	jsr create_object
;																|
; __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __| ; Seed gen
;																|
; Clock rng and store room seed for random selection processes
	lda Seed
	sta RoomSeed
	jsr ClockRNG
	sta Seed
	
; TODO more room generation procedures




;																|
; __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __| ; Finally, walls 
;																|	
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


	rts
.endproc
;                                                           END |
; ______________________________________________________________|


; _______________________________________________________________
;																|
;							Furnishing							|
;																|
; Room object initialization routine
; DO NOT USE WITH RENDERING ON
; Parameters: A = object ID, |  X, Y = tile coordinate offsets
.proc create_object
;																|
; __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __| ; Create basic object
;																|
ScreenX := Scratch+0
ScreenY := Scratch+1
ObjectID := Scratch+2
TileTblPtr := TmpPtr
TilesRow := Scratch+3

; Store ID to earliest available object in list 
	sta ObjectID
	; Translate XY tile coordinates to screen space
	txa
	asl
	asl
	asl 
	sta ScreenX
	tya
	asl
	asl
	asl 
	sta ScreenY
	ldx #0
@SearchObjList:
	lda objects, X
	cmp #$FF ; signifies unused slot
	beq @WriteObjID
	inx
	jmp @SearchObjList
@WriteObjID:
	lda ObjectID
	sta objects, X
;																|
; __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __| ; Object box
;																|
; Write object box
	; left 
	lda table_object_Boxes + LEFT
	clc
	adc ScreenX ; tile coordinate offset
	sta object_Boxes_Left, X
	; top
	lda table_object_Boxes + TOP
	clc
	adc ScreenY
	sta object_Boxes_Top, X
	; right
	lda table_object_Boxes + RIGHT
	clc
	adc ScreenX
	sta object_Boxes_Right, X
	; bottom
	lda table_object_Boxes + BOTTOM
	clc
	adc ScreenY
	sta object_Boxes_Bottom, X
;																|
; __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __| ; Tiledraw loop
;																|
; First redivide tile coordinates
	lda ScreenX
	ror
	ror
	ror
	sta ScreenX
	lda ScreenY
	ror
	ror
	ror
	sta ScreenY
	ldx ScreenX
	ldy ScrollNt ; adjust for NT
	beq :+
	clc
	adc #64
	sta ScreenY
:
	ldy ScreenY
	jsr PPU_OFF_AddressTile
	; now ready for PPUDATA writes
; Set TileTblPtr based on ID
	lda ObjectID
	asl
	tax
	lda table_object_tileROM, X
	sta TileTblPtr
	lda table_object_tileROM+1, X
	sta TileTblPtr+1
; Compute row width by grabbing from boundsbox
	lda ObjectID
	asl
	asl
	clc
	adc #$02
	tax
	lda table_object_Boxes, X
	ror
	ror
	ror
	sta TilesRow
	ldy #0
	ldx #0
; Loop thru table
@TilesLoop:
	lda (TileTblPtr), Y
	cmp #$FF ; terminator
	beq @TilesDone
	sta PPUDATA
	iny
	inx
	cpx TilesRow
	bne @TilesLoop
; New row
	tya
	pha ; push Y on stack
	ldx ScreenX
	inc ScreenY
	ldy ScreenY
	jsr PPU_OFF_AddressTile
	pla
	tay ; pop Y off stack
	ldx #0
	jmp @TilesLoop
@TilesDone:
; TODO handle attributes.................. later

	rts


.segment "RODATA"
table_object_Boxes:
; ID 0, doors
.byte 00 ; LEFT
.byte 00 ; TOP
.byte 32 ; RIGHT
.byte 48 ; BOTTOM
; ID 1, Duerer title
.byte 00
.byte 00
.byte 96
.byte 16
; ID 2, P.o.E.D.R.
.byte 00
.byte 00
.byte 224
.byte 8
; ID 3, Puddle
.byte 00
.byte 00
.byte 80
.byte 24
; ID 4, DeadThing


table_object_tileROM:
.word table_tileROM_Door
.word table_tileROM_Duerer
.word table_tileROM_Subtitle
.word table_tileROM_Puddle
; ID 0, doors 
table_tileROM_Door:
.byte $24,$25,$25,$26
.byte $27,$28,$29,$2A
.byte $2B,$2C,$2D,$2A
.byte $2E,$2F,$30,$31
.byte $32,$33,$34,$2A
.byte $35,$36,$37,$2A, $FF
; ID 1, Title
table_tileROM_Duerer:
.byte $53,$FD, $53,$FD, $53,$FD, $53,$54, $53,$FD, $53,$54
.byte $55,$FD, $56,$FD, $55,$FD, $55,$57, $55,$FD, $55,$57, $FF
; ID 2, Subtitle
table_tileROM_Subtitle:
.byte _P,_R,_I,_S,_O,_N,__,_O,_F,__,_E,_T,_E,_R,_N,_A,_L,__,_D,_I,_C,_E,__,_R,_O,_L,_L, $FF
; ID 3, Puddle
table_tileROM_Puddle:
.byte $FD,$FD,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FD
.byte $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
.byte $FD,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FD,$FD,$FF

.endproc
;                                                           END |
; ______________________________________________________________|


; _______________________________________________________________
;                                                           	|
; 					Furnishing's function						|
;                                                           	|
; A: Room obj index
object_QueueBehavior:
	
	ldx #0
:
	ldy object_BehaviorQueue, X
	inx
	cpy #$FF
	bne :-
	
	dex
	sta object_BehaviorQueue, X

	rts


; Intended to be used during dungeon frame routine
; Checks for 'queued' object_ events and executes one per frame
.proc handler_object_Behavior

; 'Queued' room object is an index to room object list
	ldx #0
@CheckQueue:
	lda object_BehaviorQueue, X
	inx
	cpx #8 ; gone thru full queue?
	beq @Done
	cmp #$FF
	beq @CheckQueue
	; Clear queued item
	dex
	tay
	lda #$FF
	sta object_BehaviorQueue, X

; A = Room object index
	tya
	tax
	inc object_States, X

; Do object's behavior
	stx Scratch+0 ; Object index for behavior call
	lda objects, X
	asl
	tax
	lda table_object_Behavior, X
	sta TmpPtr
	lda table_object_Behavior+1, X
	sta TmpPtr+1
	jmp (TmpPtr)
	; rts handled by Object behavior

@Done:

	rts

.endproc

; Object behavior
table_object_Behavior:
.word object_Behavior_Door
.word object_Behavior_Duerer
.word object_Behavior_Duerer
.word object_Behavior_Puddle

;																|
; __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __|
;																|
;ID 0, doors
object_Behavior_Door:

ObjectIndex := Scratch+0
RowStartX := Scratch+1
RowEndX := Scratch+2
RowEndY := Scratch+3
RowCurrX := Scratch+4
TmpX := Scratch+5
TmpY := Scratch+6

; Initialize XY tilevals
	ldx ObjectIndex
	lda object_Boxes_Left, X
	ror
	ror
	ror
	sta RowStartX
	sta RowCurrX
	clc
	adc #$04
	sta RowEndX
	lda object_Boxes_Top, X
	ror
	ror
	ror
	ldx ScrollNt
	beq :+
	clc
	adc #64
:
	tay
	clc
	adc #$08
	sta RowEndY
	
; Write door tiles
	ldx #00
	stx TmpX
	sty TmpY
@OpenDoorTilesLoop:
	ldx RowStartX
	jsr PPU_ON_AddressTile
	
; Y = nmt diaper
; now write row width and tile string
	lda #$04
	sta NmtUpdateRAM, Y
	iny
	
	ldx TmpX
	
	lda table_tileROM_OpenDoor, X
	sta NmtUpdateRAM, Y
	inx
	iny
	
	lda table_tileROM_OpenDoor, X
	sta NmtUpdateRAM, Y
	inx
	iny
	
	lda table_tileROM_OpenDoor, X
	sta NmtUpdateRAM, Y
	inx
	iny
	
	lda table_tileROM_OpenDoor, X
	sta NmtUpdateRAM, Y
	inx
	iny
	
	stx TmpX
	sty Nmt_Diaper
	
	ldy TmpY
	iny
	sty TmpY
	cpy RowEndY
	bne @OpenDoorTilesLoop
;																|
; __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __|
;																|
; Set doors timer
	lda #64+64
	sta NextRoomTimer	
	
; Award points
	lda points
	clc
	adc points_PerDoor
	sta points
	
; Create scorpip
	; Setup parameters
	ldx ObjectIndex
	lda object_Boxes_Top, X
	tay
	lda object_Boxes_Left, X
	tax
	lda points_PerDoor
	
	jsr create_scorePip
	
	
	rts

table_tileROM_OpenDoor:
.byte $38,$39,$3A,$3B
.byte $3C,$3D,$3E,$3F
.byte $40,$41,$42,$3F
.byte $43,$44,$45,$3F
.byte $46,$47,$48,$3F
.byte $49,$4A,$45,$3F
.byte $4B,$4C,$4D,$FF
.byte $FF,$FF,$FF,$FF

object_Behavior_Duerer:

	rts
	
object_Behavior_Puddle:

	rts

; 															END |
; ______________________________________________________________|

; pALEETE data.
.byte $2D,$00,$10,$32 ; Doors alts 
.byte $2D,$06,$05,$16
.byte $2D,$07,$00,$17

dungeon_palette: 
; bg
.byte $2D,$00,$0F,$32 ; Floor ceiling score
.byte $2D,$07,$00,$17 ; Doors
.byte $2D,$00,$00,$00
.byte $2D,$00,$00,$00
; sp
.byte $2D,$18,$28,$38 ; Fairy
.byte $2D,$0F,$06,$38 ; Doggies
.byte $2D,$00,$00,$00
.byte $2D,$00,$00,$32

