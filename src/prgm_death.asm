;
; It's your funeral. (spite)
;

.debuginfo+
.smart
.include "prgm_death.inc"
.include "prgm.inc"
.include "nmi.inc"
.include "ppu_utility.inc"
.include "buttons.inc"
.include "dungeon_room.inc"


.segment "ZEROPAGE"
DeathCount: .res 1

; _______________________________________________________________
; 																|
;						Funeral planning						|
;																|
.segment "CODE"
Death_Load:
; Enable writes
	jsr ppu_off
	
; Clear this screen
	lda ScrollNt
	asl
	asl
	clc
	adc #$20
	jsr bgSetup
	
; Upload palette
	ldx #0
:
	lda table_palette_Death, X
	sta paletteRAM, X
	inx
	cpx #32
	bne :-
	
; Clear cells mem
	ldx #0
	lda #$00
:
	sta cells_Ptrs, X
	inx
	cpx #$10
	bne :-
	
; Draw bg tiles
	
;																|
; __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __| ; Setup over!
;																|
	lda #<Death_Frame
	sta PrgmFramePtr
	lda #>Death_Frame
	sta PrgmFramePtr+1
	
	jmp (PrgmFramePtr)
; 															END |
; ______________________________________________________________|


; _______________________________________________________________
; 																|
; 						Funeral march							|
;																|
Death_Frame:
	
; Buttoncheck
	lda #PAD_START
	jsr CheckButtons
	beq @Done
	
	; Start = pressed; let's destroy the world again!!
	lda #MODE_TITLE
	sta PrgmMode
	lda #1
	sta PrgmMode_Diaper

@Done:
	jsr ppu_update
	
	jmp mainloop
; 															END |
; ______________________________________________________________|

table_palette_Death:
.byte $0F,$10,$10,$10
.byte $0F,$10,$10,$10
.byte $0F,$10,$10,$10
.byte $0F,$10,$10,$10

.byte $0F,$10,$10,$10
.byte $0F,$10,$10,$10
.byte $0F,$10,$10,$10
.byte $0F,$10,$10,$10