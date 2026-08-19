;
; main loop, pretty simple. initializes, then maintains control flow and loops forever
;
.debuginfo +
.smart
.include "header.inc"
.include "system.inc"
.include "nmi.inc"
.include "reset.inc"
.include "main.inc"
.include "buttons.inc"
.include "title.inc"
.include "dungeon.inc"
.include "rng.inc"


.segment "ZEROPAGE"
Scratch:			.res 16
PrgmMode:		.res 1 
PrgmFramePtr:	.res 2 ; Address to current frame routine
PrgmMode_update:	.res 1
TmpPtr:			.res 2
TmpPtr2:		.res 2
PrgmTimer:		.res 1 ; simple frame tracker
ButtonsTimer:	.res 1 ; number of frames until input is accepted (may need mroe of these)
DoorsTimer:		.res 1 ; number of frames until we transition rooms or die
NeedScroll:		.res 1


.segment "CODE"
main:
	; 'Initialize' seed
	lda #1
	sta Seed
	; set up to initialize title 
	lda #MODE_DUNGEON
	sta PrgmMode
	lda #1
	sta PrgmMode_update ; set update flag

mainloop:
	inc PrgmTimer
	jsr ReadJoypad1
	; change mode if flagged and run initialization code
	lda PrgmMode_update
	beq :+
		jsr ChangePrgmMode
	:
	; after initialization frame routine should be set, runs until mode change
	jmp (PrgmFramePtr)


; table jumper for game mode, always starts with initialization duh
ChangePrgmMode:
	lda #0
	sta PrgmMode_update
	lda PrgmMode
	asl ; shift cus table entries 16b
	tax
	lda PrgmMode_InitTbl, x
	sta TmpPtr
	lda PrgmMode_InitTbl+1, x
	sta TmpPtr+1
	jmp (TmpPtr)
	; rts handled by subroutines


; jump table for game mode
PrgmMode_InitTbl:
.word Title_Load
.word Dungeon_Load
;.word Exit_Load
;.word Death_Load

; lets shove this under the rug
irq:
	rti


.segment "VECTORS"
.addr nmi, reset, irq


.segment "TILES"
.incbin "sp_.chr"
.incbin "bg_.chr"