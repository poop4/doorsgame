;
; Dungeon room system.
;
.debuginfo +
.smart
.include "dungeon_room.inc"
.include "system.inc"
.include "main.inc"
.include "nmi.inc"
.include "rng.inc"
.include "monsters.inc"

.segment "ZEROPAGE"
; local RNG for current room
RoomSeed: 				.res 1

.segment "BSS"
; list of indices, used as offsets and to signify object IDs. init as FF
RoomObjects: 	.res 16
; 4 bytes each, holds collision info for room objects
RoomObjBoxes_Left:		.res 16
RoomObjBoxes_Top:		.res 16
RoomObjBoxes_Right:		.res 16
RoomObjBoxes_Bottom:	.res 16
; default 0, modified on interaction
RoomObjStates:	.res 16
; index for queued behaviors. init as FF
RoomObjBehaviorQueue: .res 4

; _______________________________________________________________
; |																|
; |					A new world	borne of chance					|
; |_____________________________________________________________|
; |																|
.segment "CODE"
.proc GenerateRoom
;																|
;																[0} Destruction of the old world
;																|
ScreenX := Scratch+0
ScreenY := Scratch+1
NtHi := Scratch+2
NtLo := Scratch+3
RandomBits := Scratch+4
ToggleFloor := Scratch+5

; Initialize room obj 
	ldx #0
@ClearRoomLoop:
	lda #$FF 
	sta RoomObjects, X
	cpx #$04
	bcs :+
	sta RoomObjBehaviorQueue, X
:
	lda #$00
	sta RoomObjStates, X
	sta RoomObjBoxes_Left, X
	sta RoomObjBoxes_Top, X
	sta RoomObjBoxes_Right, X
	sta RoomObjBoxes_Bottom, X
	inx
	cpx #$10
	bne @ClearRoomLoop
; The old world is destroyed
;																|
;																[1} Now, paint the new world with fate's fingerprints
;																|
; Draw decorative tiles
; Transfer global seed to this room
	lda Seed
	sta RoomSeed
; Initialize nt pointers (and toggle), start outer loop
	lda #$20
	sta NtHi
	lda #$42
	sta NtLo
	lda #0
	sta ToggleFloor
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
	inc ToggleFloor
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
	adc ToggleFloor
	jmp @DrawByte
:
	lda #$4E
	clc
	adc ToggleFloor
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
;																[2} Toys of fate, 3 apiece
;																|
; Create door objects
	lda #OBJ_DOOR
	ldx #6
	ldy #4
	jsr CreateRoomObject
	lda #OBJ_DOOR
	ldx #14
	ldy #4
	jsr CreateRoomObject
	lda #OBJ_DOOR
	ldx #22
	ldy #4
	jsr CreateRoomObject
;																|
;																[3} What else has fate for us to see?
;																|
; Clock rng and store room seed for random selection processes
	lda Seed
	sta RoomSeed
	jsr ClockRNG
	sta Seed
	
; TODO more room generation procedures

	rts
.endproc
;                                                           END |
; ______________________________________________________________|

; _______________________________________________________________
;																|
;							Furnishing							|
;_______________________________________________________________|
;																|
; Room object initialization routine
; DO NOT USE WITH RENDERING ON
; Parameters: A = object ID, |  X, Y = tile coordinate offsets
.proc CreateRoomObject
;																|
;																[0} Reserve space
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
	lda RoomObjects, X
	cmp #$FF ; signifies unused slot
	beq @WriteObjID
	inx
	jmp @SearchObjList
@WriteObjID:
	lda ObjectID
	sta RoomObjects, X
;																|
;																[1} Create a body to touch
;																|
; Write object box
	; left 
	lda table_RoomObjBoxes + LEFT
	clc
	adc ScreenX ; tile coordinate offset
	sta RoomObjBoxes_Left, X
	; top
	lda table_RoomObjBoxes + TOP
	clc
	adc ScreenY
	sta RoomObjBoxes_Top, X
	; right
	lda table_RoomObjBoxes + RIGHT
	clc
	adc ScreenX
	sta RoomObjBoxes_Right, X
	; bottom
	lda table_RoomObjBoxes + BOTTOM
	clc
	adc ScreenY
	sta RoomObjBoxes_Bottom, X
;																|
;																[2} Create a body to see
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
	jsr ppu_address_tile
	; now ready for PPUDATA writes
; Set TileTblPtr based on ID
	lda ObjectID
	asl
	tax
	lda table_RoomObjTiles, X
	sta TileTblPtr
	lda table_RoomObjTiles+1, X
	sta TileTblPtr+1
; Compute row width by grabbing from boundsbox
	lda ObjectID
	asl
	asl
	clc
	adc #$02
	tax
	lda table_RoomObjBoxes, X
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
	jsr ppu_address_tile
	pla
	tay ; pop Y off stack
	ldx #0
	jmp @TilesLoop
@TilesDone:
; TODO handle attributes.................. later
	rts


.segment "RODATA"
table_RoomObjBoxes:
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

; ID 4, DeadThing


table_RoomObjTiles:
.word table_DoorTiles
.word table_DuererTiles
.word table_SubtitleTiles
; ID 0, doors 
table_DoorTiles:
.byte $24,$25,$25,$26
.byte $27,$28,$29,$2A
.byte $2B,$2C,$2D,$2A
.byte $2E,$2F,$30,$31
.byte $32,$33,$34,$2A
.byte $35,$36,$37,$2A, $FF
; ID 1, Title
table_DuererTiles:
.byte $53,$FD, $53,$FD, $53,$FD, $53,$54, $53,$FD, $53,$54
.byte $55,$FD, $56,$FD, $55,$FD, $55,$57, $55,$FD, $55,$57, $FF
; ID 2, Subtitle
table_SubtitleTiles:
.byte _P,_R,_I,_S,_O,_N,__,_O,_F,__,_E,_T,_E,_R,_N,_A,_L,__,_D,_I,_C,_E,__,_R,_O,_L,_L, $FF

.endproc
;                                                           END |
; ______________________________________________________________|

; _______________________________________________________________
;                                                           	|
; 					Furnishing's function						|
; ______________________________________________________________|
;                                                           	|
; Intended to be used during dungeon frame routine
; Checks for 'queued' roomobj events and executes one per frame
.proc UpdateRoomObjBehavior



	rts

; Object behavior
table_RoomObjBehavior:
.word RoomObjBehavior_Door
.word RoomObjBehavior_Duerer
.word RoomObjBehavior_Duerer

;ID 0, doors
RoomObjBehavior_Door:
ObjectIndex := Scratch+0
RowStartX := Scratch+1
RowEndX := Scratch+2
RowEndY := Scratch+3
RowCurrX := Scratch+4
TmpX := Scratch+5
; Grab and initialize XY tile values
	ldx ObjectIndex
	lda RoomObjBoxes_Left, X
	ror
	ror
	ror
	sta RowStartX
	sta RowCurrX
	clc
	adc #$04
	sta RowEndX
	lda RoomObjBoxes_Top, X
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
; Loop initialization
	ldx #00
@OpenDoorTilesLoop:
	lda table_OpenDoorTiles, X
	stx TmpX
	ldx RowCurrX
	jsr ppu_update_tile
	
	inc RowCurrX
	ldx RowCurrX
	cpx RowEndX
	bne :+
	lda RowStartX
	sta RowCurrX
	iny
	cpy RowEndY
	beq @TilesLoopEnd
:
	ldx TmpX
	inx
	jmp @OpenDoorTilesLoop
@TilesLoopEnd:
; Set doors timer
	lda #120
	sta DoorsTimer
	
	rts

table_OpenDoorTiles:
.byte $38,$39,$3A,$3B
.byte $3C,$3D,$3E,$3F
.byte $40,$41,$42,$3F
.byte $43,$44,$45,$3F
.byte $46,$47,$48,$3F
.byte $49,$4A,$45,$3F
.byte $4B,$4C,$4D,$FF
.byte $FF,$FF,$FF,$FF

RoomObjBehavior_Duerer:

	rts

.endproc
; 															END |
; ______________________________________________________________|

; pALEETE data.
.byte $2D,$00,$10,$32 ; Doors alts 
.byte $2D,$06,$05,$16
.byte $2D,$07,$00,$17

dungeon_palette: 
; bg
.byte $2D,$00,$0F,$0F ; Floor ceiling 
.byte $2D,$07,$00,$17 ; Doors
.byte $2D,$00,$00,$00
.byte $2D,$00,$00,$00
; sp
.byte $2D,$18,$28,$38 ; Fairy
.byte $2D,$0F,$06,$38 ; Doggies
.byte $2D,$00,$00,$00
.byte $2D,$00,$00,$00

