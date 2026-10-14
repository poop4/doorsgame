;
; main, pretty simple. initializes, then maintains control flow and loops forever
;
.debuginfo +
.smart
.include "header.inc"
.include "system.inc"
.include "nmi.inc"
.include "reset.inc"
.include "prgm.inc"
.include "buttons.inc"
.include "prgm_title.inc"
.include "prgm_dungeon.inc"
.include "prgm_death.inc"
.include "rng.inc"
.include "ppu_utility.inc"


.segment "ZEROPAGE"
Scratch:			.res 8
PrgmMode:			.res 1 
PrgmMode_Diaper:	.res 1
PrgmModeState:		.res 1
PrgmFramePtr:		.res 2 
TmpPtr:				.res 2
TmpPtr2:			.res 2
PrgmTimer:			.res 3
PrgmTimer_4f:		.res 1
ButtonsTimer:		.res 1
NextRoomTimer:		.res 1
NeedScroll:			.res 1


; _______________________________________________________________
; 																|
; 						Space and time							|
;																|
.segment "CODE"
main:
PrgmLoadPtr := TmpPtr

	lda #1
	sta Seed
	
	lda #MODE_DUNGEON
	sta PrgmMode
	lda #1
	sta PrgmMode_Diaper ; set update flag

mainloop:
; Time moves forward
	inc PrgmTimer
	
	inc PrgmTimer_4f
	lda PrgmTimer_4f
	cmp #$04
	bne :+
	
	lda #$00
	sta PrgmTimer_4f
:

; Reach out to the divine
	jsr ReadJoypad1
	
; Destroy and create matter
	ldx #0
	lda #$FF
:
	sta oam, X
	inx
	bne :-
	
	jsr handler_Cells

	; Mode switch? 
	lda PrgmMode_Diaper
	beq :+
	lda #0
	sta PrgmMode_Diaper
; Load next program mode
	ldx PrgmMode
	lda loptr_table_PrgmMode_Load, x
	sta PrgmLoadPtr
	lda hiptr_table_PrgmMode_Load, x
	sta PrgmLoadPtr+1
	
	jmp (PrgmLoadPtr)
	:

; Frame routine per-mode
	jmp (PrgmFramePtr)
; __ __

loptr_table_PrgmMode_Load:
.lobytes Title_Load
.lobytes Dungeon_Load
.lobytes Death_Load

hiptr_table_PrgmMode_Load:
.hibytes Title_Load
.hibytes Dungeon_Load
.hibytes Death_Load
;															END |
; ______________________________________________________________|

irq:
	rti

.segment "VECTORS"
.addr nmi, reset, irq

.segment "TILES"
.incbin "sp_.chr"
.incbin "bg_.chr"