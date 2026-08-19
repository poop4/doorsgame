;
; Code concerning the fairy (cursor) system
; Currently implemented: movement
; Needs implemented: playfield bounds, object inspection
;
.debuginfo+
.smart
.include "fairy.inc"
.include "system.inc"
.include "nmi.inc"
.include "main.inc"
.include "buttons.inc"
.include "dungeon_room.inc"

.segment "ZEROPAGE"
CursorX_v:			.res 1 ; velocity in px/f
CursorY_v: 			.res 1
CursorX:			.res 1 ; actual position
CursorY:			.res 1
CursorState:		.res 1
CursorAnimToggle:	.res 1
CursorBoundsBox:	.res 4 ; Left, top, right, bottom

.segment "BSS"
CursorCells:		.res 16


.segment "CODE"

CreateFairy:
; Fairy initialize
	lda #200
	sta CursorY
	lda #FAIRY_NORMAL
	sta CursorState
	
	rts



; Animate the fairy via a toggle every X frames
; TODO Add a table for left + right movement and include cases
; TODO Update this later to include Interaction state sprite
; or maybe kirby star thing 
DrawFairy:
	lda PrgmTimer
	and #%00000100
	beq @Frame0
	lda #1
	sta CursorAnimToggle
	jmp @Frame1
@Frame0:	
	lda #0
	sta CursorAnimToggle
@Frame1:
	ldx #0
	ldy oam_index
@Draw:
; Store Ypos
	lda CursorY
	clc
	adc table_FairySp, X
	sta oam, Y
	inx
	iny
; Store TileID
	lda table_FairySp, X	
	clc
	adc CursorAnimToggle
	sta oam, Y	
	inx
	iny
; Store Attr
	lda table_FairySp, X
	sta oam, Y
	inx
	iny
; Store Xpos
	lda CursorX
	clc
	adc table_FairySp, X
	sta oam, Y
	inx
	iny
	cpx #$10
	bne @Draw
; Update oam counter
	lda oam_index
	clc
	adc #$10
	sta oam_index
	rts

table_FairySp:
.byte $00,$00,%00000000,$00
.byte $00,$00,%01000000,$08
.byte $08,$02,%00000000,$00
.byte $08,$02,%01000000,$08


FairyBoundsCheck:
	; This subroutine checks against the current CursorBoundsBox and pushes back against it if necessary
	lda CursorX
	cmp CursorBoundsBox + LEFT
	bcs @CheckTop
	lda #00
	sta CursorX_v
	lda CursorBoundsBox + LEFT
	sta CursorX
@CheckTop:
	lda CursorY
	cmp CursorBoundsBox + TOP
	bcs @CheckRight
	lda #00
	sta CursorY_v
	lda CursorBoundsBox + TOP
	sta CursorY
@CheckRight:
	lda CursorX 
	clc
	adc #$10
	cmp CursorBoundsBox + RIGHT
	bcc @CheckBottom
	lda #00
	sta CursorX_v
	lda CursorBoundsBox + RIGHT
	sec
	sbc #$10
	sta CursorX
@CheckBottom:
	lda CursorY
	clc
	adc #$10
	cmp CursorBoundsBox + BOTTOM
	bcc @End
	lda #00
	sta CursorY_v
	lda CursorBoundsBox + BOTTOM
	sec
	sbc #$10
	sta CursorY
@End:
	rts


FairyMove_Player:
	lda CursorState
	cmp #FAIRY_STOPPED 
	bne @ImbuePlayerWill
	; Cursor shouldn't be movable by player, return
	rts
@ImbuePlayerWill:
; Load buttonstate and act accordingly
	lda Buttons
	and #PAD_UP
	beq :+
	lda CursorY_v
	cmp #$FE
	beq :+ ; capped, skip
	clc
	adc #$FE
	sta CursorY_v
:
	lda Buttons
	and #PAD_DOWN
	beq :+
	lda CursorY_v
	cmp #$02
	beq :+
	clc
	adc #$02
	sta CursorY_v
:
	lda Buttons
	and #PAD_LEFT
	beq :+
	lda CursorX_v 
	cmp #$FE
	beq :+
	clc
	adc #$FE
	sta CursorX_v
:
	lda Buttons
	and #PAD_RIGHT
	beq :+
	lda CursorX_v
	cmp #$02
	beq :+
	clc
	adc #$02
	sta CursorX_v
:
	; upd x
	lda CursorX
	clc
	adc CursorX_v
	sta CursorX
	; upd y
	lda CursorY
	clc
	adc CursorY_v
	sta CursorY
; Friction, will slow to a stop if no buttons r pressed
	; y-dir
	lda CursorY_v
	bpl :+
	; is negative
	clc
	adc #$01
	bmi :++
:
	; is positive
	beq :+
	; is nonzero
	sec
	sbc #$01
:
	sta CursorY_v
	
	; x-dir
	lda CursorX_v
	bpl :+
	; is negative
	clc
	adc #$01
	bmi :++
:
	; is positive
	beq :+
	; is nonzero
	sec
	sbc #$01
:
	sta CursorX_v
	rts
	

; figure out which box you're in
; Increment ObjectState if you're in a box
; otherwise (TODO) play nono sound and rts
; NOTE: this only adjusts state for the earliest box triggered in the list
; right now that shouldn't be a problem. just keep that in mind though
.proc FairyCheckInteract
CursorHitPtX:= Scratch+0
CursorHitPtY:= Scratch+1
	lda CursorX
	clc
	adc #$08
	sta CursorHitPtX
	lda CursorY
	clc
	adc #$08
	sta CursorHitPtY
	ldx #0
@CompareLoop:
; Go thru each object and trivially reject
	lda CursorHitPtX
	cmp RoomObjBoxes_Left, X
	bcc @NextObject 
	cmp RoomObjBoxes_Right, X
	bcs @NextObject
	lda CursorHitPtY
	cmp RoomObjBoxes_Top, X
	bcc @NextObject
	cmp RoomObjBoxes_Bottom, X
	bcs @NextObject
; We have entered a fucking box, fuck yes
	inc RoomObjStates, X
	jmp @DoRoomObjBehavior
@NextObject:
	inx
	cpx #ROOMOBJ_MAX
	bne @CompareLoop
	jmp @RtsWithoutDoinNothin
; All objects checked, run interact code for highest order collision
@DoRoomObjBehavior:
	stx Scratch+0 ; Object index for behavior call
	lda RoomObjects, X
	asl
	tax
	lda table_RoomObjBehavior, X
	sta TmpPtr
	lda table_RoomObjBehavior+1, X
	sta TmpPtr+1
	jmp (TmpPtr)
	; rts handled by Object behavior
@RtsWithoutDoinNothin:
	rts
.endproc