;
; Code concerning the fairy (cursor) system
; Currently implemented: movement
; Needs implemented: playfield bounds, object inspection
;
.debuginfo+
.smart
.include "fairy.inc"
.include "prgm.inc"
.include "dungeon_room.inc"
.include "ppu_utility.inc"

.segment "ZEROPAGE"
fairy_X_v:			.res 1 ; velocity in px/f
fairy_Y_v: 			.res 1
fairy_X:			.res 1 ; actual position
fairy_Y:			.res 1
fairy_State:		.res 1
fairy_AnimToggle:	.res 1
fairy_BoundsBox:	.res 4 ; Left, top, right, bottom

.segment "BSS"
cells_fairy:		.res 17


.segment "CODE"

.proc create_fairy
; Fairy initialize
	lda #200
	sta fairy_Y
	lda #FAIRY_NORMAL
	sta fairy_State
	
; Create cells	
	ldx #0
:
	lda cells_Ptrs, X
	beq :+
	inx
	inx
	jmp :-
:	
	lda ptr_cells_fairy
	sta cells_Ptrs, X
	lda ptr_cells_fairy+1
	sta cells_Ptrs+1, X

; Fill cells!
	ldx #0
@CellularDistribution:
	lda table_FairySp, X
	sta cells_fairy, X
	inx
	cpx #$10
	bne @CellularDistribution
	; Place terminator
	lda #$FF
	sta cells_fairy, X
	
;  Initialize fairy_BoundsBox
	lda #$10
	sta fairy_BoundsBox + LEFT
	lda #$30
	sta fairy_BoundsBox + TOP
	lda #$EF
	sta fairy_BoundsBox + RIGHT 
	lda #$DF
	sta fairy_BoundsBox + BOTTOM	

	
	rts


table_FairySp:
.byte $00,$18,%00000000,$00
.byte $00,$19,%00000000,$08
.byte $08,$1A,%00000000,$00
.byte $08,$1B,%00000000,$08

ptr_cells_fairy:
.word cells_fairy

.endproc

;
;
;

handler_fairy_Behavior:

	; TODO here
	; everything

	rts


;
;
;

fairy_BoundsCheck:
	; This subroutine checks against the current fairy_BoundsBox and pushes back against it if necessary
	lda fairy_X
	cmp fairy_BoundsBox + LEFT
	bcs @CheckTop
	lda #00
	sta fairy_X_v
	lda fairy_BoundsBox + LEFT
	sta fairy_X
@CheckTop:
	lda fairy_Y
	cmp fairy_BoundsBox + TOP
	bcs @CheckRight
	lda #00
	sta fairy_Y_v
	lda fairy_BoundsBox + TOP
	sta fairy_Y
@CheckRight:
	lda fairy_X 
	clc
	adc #$10
	cmp fairy_BoundsBox + RIGHT
	bcc @CheckBottom
	lda #00
	sta fairy_X_v
	lda fairy_BoundsBox + RIGHT
	sec
	sbc #$10
	sta fairy_X
@CheckBottom:
	lda fairy_Y
	clc
	adc #$10
	cmp fairy_BoundsBox + BOTTOM
	bcc @Done
	lda #$00
	sta fairy_Y_v
	lda fairy_BoundsBox + BOTTOM
	sec
	sbc #$10
	sta fairy_Y
@Done:
	rts

;
;
;

; We can call these placeholders for now. They'll work.

fairy_MoveLeft:
	lda #$FE
	sta fairy_X_v
	
	rts

fairy_MoveUp:
	lda #$FE
	sta fairy_Y_v
	
	rts

fairy_MoveRight:
	lda #$02
	sta fairy_X_v
	
	rts

fairy_MoveDown:
	lda #$02
	sta fairy_Y_v
	
	rts

fairy_Move:
; Add velocity to XY
	lda fairy_X
	clc
	adc fairy_X_v
	sta fairy_X
	
	lda fairy_Y
	clc
	adc fairy_Y_v
	sta fairy_Y

	lda #0
	sta fairy_X_v
	sta fairy_Y_v
	
; Store XY in cells
	ldx #0
	ldy #0
@UpdateXY:
	lda table_OAMattr_fairy, Y
	clc
	adc fairy_Y
	sta cells_fairy, X
	
	iny
	inx
	inx
	inx
	
	lda table_OAMattr_fairy, Y
	clc
	adc fairy_X
	sta cells_fairy, X
	
	iny
	inx
	
	cpy #8
	bne @UpdateXY
	
	
	rts
	
table_OAMattr_fairy:
.byte $00, $00
.byte $00, $08
.byte $08, $00
.byte $08, $08
	
;
;
;

; (TODO) play nono sound and rts
; NOTE: this only adjusts state for the earliest box triggered in the list

.proc fairy_CheckInteract
fairy_HitPtX:= Scratch+0
fairy_HitPtY:= Scratch+1
	lda fairy_X
	clc
	adc #$08
	sta fairy_HitPtX
	lda fairy_Y
	clc
	adc #$08
	sta fairy_HitPtY

	ldx #0	
@CompareLoop:
; Go thru each object and trivially reject
	lda fairy_HitPtX
	cmp object_Boxes_Left, X
	bcc @NextObject 
	cmp object_Boxes_Right, X
	bcs @NextObject
	lda fairy_HitPtY
	cmp object_Boxes_Top, X
	bcc @NextObject
	cmp object_Boxes_Bottom, X
	bcs @NextObject
	
; We have entered a fucking box, fuck yes
	txa
	jsr object_QueueBehavior
	jmp @Done
	
@NextObject:
	inx
	cpx #OBJ_MAXAMT
	bne @CompareLoop
	
@Done:
	rts
	
.endproc