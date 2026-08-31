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
.include "ppu_utility.inc"

.segment "ZEROPAGE"
CursorX_v:			.res 1 ; velocity in px/f
CursorY_v: 			.res 1
CursorX:			.res 1 ; actual position
CursorY:			.res 1
CursorState:		.res 1
CursorAnimToggle:	.res 1
CursorBoundsBox:	.res 4 ; Left, top, right, bottom

.segment "BSS"
CursorCells:		.res 17


.segment "CODE"

.proc FairyCreate
; Fairy initialize
	lda #200
	sta CursorY
	lda #FAIRY_NORMAL
	sta CursorState
	
; Create cells	
	ldx #0
:
	lda CellsList, X
	beq :+
	inx
	inx
	jmp :-
:	
	lda ptr_FairyCells
	sta CellsList, X
	lda ptr_FairyCells+1
	sta CellsList+1, X

; Fill cells!
	ldx #0
@CellularDistribution:
	lda table_FairySp, X
	sta CursorCells, X
	inx
	cpx #$10
	bne @CellularDistribution
	; Place terminator
	lda #$FF
	sta CursorCells, X
	
;  Initialize CursorBoundsBox
	lda #$10
	sta CursorBoundsBox + LEFT
	lda #$30
	sta CursorBoundsBox + TOP
	lda #$EF
	sta CursorBoundsBox + RIGHT 
	lda #$DF
	sta CursorBoundsBox + BOTTOM	

	
	rts


table_FairySp:
.byte $00,$00,%00000000,$00
.byte $00,$00,%01000000,$08
.byte $08,$02,%00000000,$00
.byte $08,$02,%01000000,$08

ptr_FairyCells:
.word CursorCells

.endproc

;
;
;

HandleFairyEvents:

	; TODO here
	; everything

	rts


;
;
;

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
	lda #$00
	sta CursorY_v
	lda CursorBoundsBox + BOTTOM
	sec
	sbc #$10
	sta CursorY
@End:
	rts

;
;
;

; We can call these placeholders for now. They'll work.

FairyMove_Left:
	lda #$FE
	sta CursorX_v
	
	rts

FairyMove_Up:
	lda #$FE
	sta CursorY_v
	
	rts

FairyMove_Right:
	lda #$02
	sta CursorX_v
	
	rts

FairyMove_Down:
	lda #$02
	sta CursorY_v
	
	rts

FairyMove:
; Add velocity to XY
	lda CursorX
	clc
	adc CursorX_v
	sta CursorX
	
	lda CursorY
	clc
	adc CursorY_v
	sta CursorY

	lda #0
	sta CursorX_v
	sta CursorY_v
	
; Store XY in cells
	ldx #0
	ldy #0
@UpdateXY:
	lda table_FairyXYoffsets, Y
	clc
	adc CursorY
	sta CursorCells, X
	
	iny
	inx
	inx
	inx
	
	lda table_FairyXYoffsets, Y
	clc
	adc CursorX
	sta CursorCells, X
	
	iny
	inx
	
	cpy #8
	bne @UpdateXY
	
	
	rts
	
table_FairyXYoffsets:
.byte $00, $00
.byte $00, $08
.byte $08, $00
.byte $08, $08
	
;
;
;

; (TODO) play nono sound and rts
; NOTE: this only adjusts state for the earliest box triggered in the list

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