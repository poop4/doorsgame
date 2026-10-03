;
; main loop, pretty simple. initializes, then maintains control flow and loops forever
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
DarkScratch:		.res 8
PrgmMode:			.res 1 
PrgmMode_Diaper:	.res 1
PrgmModeState:		.res 1
PrgmFramePtr:		.res 2 ; 
TmpPtr:				.res 2
TmpPtr2:			.res 2
PrgmTimer:			.res 3
PrgmTimer_4f:		.res 1
GenericTimer:		.res 1
ButtonsTimer:		.res 1
NextRoomTimer:		.res 1 ; number of frames until we transition 
NeedScroll:			.res 1

; _______________________________________________________________
; |																|
; |						Space and time							|
;																|
.segment "CODE"
main:
	; 'Initialize' seed
	lda #1
	sta Seed
	; set up to initialize title 
	lda #MODE_TITLE
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
	
; Adorn the score anew?
	lda PrgmMode_Diaper
	beq :+
	lda #0
	sta PrgmMode_Diaper
	; Grab mode from table
	lda PrgmMode
	asl
	tax
	lda ptr_table_PrgmMode_Load, x
	sta TmpPtr
	lda ptr_table_PrgmMode_Load+1, x
	sta TmpPtr+1
	; Initialize mode
	jmp (TmpPtr)
	:
	jmp (PrgmFramePtr)


; jump table for game mode
ptr_table_PrgmMode_Load:
.addr Title_Load
.addr Dungeon_Load
.word Death_Load
;.word Exit_Load

;															END |
; ______________________________________________________________|

irq:
	rti

.segment "VECTORS"
.addr nmi, reset, irq

.segment "TILES"
.incbin "sp_.chr"
.incbin "bg_.chr"