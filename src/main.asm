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
.include "ppu_utility.inc"


.segment "ZEROPAGE"
Scratch:			.res 16
PrgmMode:			.res 1 
PrgmMode_Diaper:	.res 1
PrgmModeState:		.res 1
PrgmFramePtr:		.res 2 ; 
TmpPtr:				.res 2
TmpPtr2:			.res 2
PrgmTimer:			.res 3 ; Universe age. Ends in ~3.23 days 
ButtonsTimer:		.res 1
DoorsTimer:			.res 1 ; number of frames until we transition rooms or die
NeedScroll:			.res 1

; _______________________________________________________________
; |																|
; |						Space and time							|
; |_____________________________________________________________|
;																|
.segment "CODE"
main:
	; 'Initialize' seed
	lda #1
	sta Seed
	; set up to initialize title 
	lda #MODE_DUNGEON
	sta PrgmMode
	lda #1
	sta PrgmMode_Diaper ; set update flag

mainloop:
; Time moves forward
	inc PrgmTimer
	bcc :+
	inc PrgmTimer+1
	bcc :+
	inc PrgmTimer+2
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
	
	jsr UpdateCells
	
; Adorn the stage anew?
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
;.word Exit_Load
;.word Death_Load

; 
;
; 

irq:
	rti

.segment "VECTORS"
.addr nmi, reset, irq

.segment "TILES"
.incbin "sp_.chr"
.incbin "bg_.chr"