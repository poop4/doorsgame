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

.segment "ZEROPAGE"
; Room data

.segment "BSS"
; list of indexes, used as offsets and to signify object IDs
RoomObjects: 	.res 16
; 4 bytes each, holds collision info for room objects
RoomObjBoxes_Left:		.res 16
RoomObjBoxes_Top:		.res 16
RoomObjBoxes_Right:		.res 16
RoomObjBoxes_Bottom:	.res 16
; default 0, modified on interaction
RoomObjStates:	.res 16

.segment "CODE"
.proc GenerateRoom
ScreenX := Scratch+0
ScreenY := Scratch+1
	; TODO
	; this later
; at least initialize room objects 
	ldx #0
@ClearRoomLoop:
	lda #$FF 
	sta RoomObjects, X
	inx
	cpx #$10
	bne @ClearRoomLoop
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

	
	rts
.endproc



; Room object initialization routine
; DO NOT USE WITH RENDERING ON
; Parameters: A = object ID, |  X, Y = tile coordinate offsets
; Functionality:
; Add room object to obj list
; Create bounds box at specified location
; Draw object at specified location
.proc CreateRoomObject
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
; Draw object graphics
; Initial size should be identical to the object's Box, so...
; use RIGHT value div 8 as a row indicator for draws
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
.endproc

.segment "RODATA"
table_RoomObjBoxes:
; ID 0, doors
.byte 00 ; LEFT
.byte 00 ; TOP
.byte 32 ; RIGHT
.byte 48 ; BOTTOM
; ID 1, etc...
.byte 00
.byte 00
.byte 16
.byte 16

table_RoomObjTiles:
.word table_DoorTiles
.word table_StoneTiles
; ID 0, doors 
table_DoorTiles:
.byte $24,$25,$25,$26
.byte $27,$28,$29,$2A
.byte $2B,$2C,$2D,$2A
.byte $2E,$2F,$30,$31
.byte $32,$33,$34,$2A
.byte $35,$36,$37,$2A,$FF
; ID 1, etc...
table_StoneTiles:
.byte $00,$01
.byte $02,$03,$FF


; Object behavior
table_RoomObjBehavior:
.word RoomObjBehavior_Door
.word RoomObjBehavior_Stone

; (TODO do some wolf shit trigger)
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
	tay
	clc
	adc #$07
	sta RowEndY
; Loop initialization
; We need to dual-use X this loop so shit gets messy
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
	lda #40
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

RoomObjBehavior_Stone:

	rts


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
.byte $2D,$00,$00,$00
.byte $2D,$00,$00,$00
.byte $2D,$00,$00,$00

