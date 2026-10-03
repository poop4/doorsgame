;
; nmi routine
;

.debuginfo+
.smart
.include "system.inc"
.include "nmi.inc"
.include "prgm.inc" ;scratch

.segment "ZEROPAGE"
NMI_Status:		.res 1 ; 0 = skip, 1 = push nmi, 2 = disable rendering
NMI_Lock:		.res 1 
OAM_Index:		.res 1
Nmt_Diaper:		.res 1
ScrollY:		.res 1
ScrollNt:		.res 1
SpritesOn:		.res 1 ; whether to enable sprite rendering this frame
poop:			.res 1 ; temporary variable

.segment "BSS"
NmtUpdateRAM: .res 256 ; nametable buffer
paletteRAM:	.res 32  ; palette buffaire

.segment "OAM"
oam: .res 256		 ; dma me baby

.segment "CODE"
nmi:
	; back up registers
	pha ; a
	txa ; x
	pha
	tya ; y
	pha
	; prevent reentry. 
	lda NMI_Lock
	beq :+ ;if lock > 1
	jmp @NMIend
	:
	; ok we good
	lda #1
	sta NMI_Lock
	; adjust next behavior based on status
	lda NMI_Status 
	bne :+ ;if status == 0
	jmp @NMIend
	:
	cmp #2
	bne :+ ; status == 2 turns off rendering 
	lda #%00000110
	sta PPUMASK
	ldx #0
	stx NMI_Status
	jmp @NMIend
	:
	; oam dma
	lda #$00
	sta OAMADDR
	lda #>oam
	sta OAMDMA
	; initialize oam list
	lda #$00
	sta OAM_Index
	; palettes
	lda #%10010000
	sta PPUCTRL
	lda PPUSTATUS ; latch
	lda #$3F
	sta PPUADDR
	lda #$00
	sta PPUADDR
	ldx #0
:
	lda paletteRAM, x
	sta PPUDATA
	inx
	cpx #32
	bne :-
	
; Update nametable
	lda Nmt_Diaper
	beq @Scroll
	ldx #0
@WriteNextAddr:
; Lo
	lda NmtUpdateRAM, X
	sta $2006
	inx
; Hi
	lda NmtUpdateRAM, X
	sta $2006
	inx
; Amt
	lda NmtUpdateRAM, X
	sta Scratch+0
	inx
; Str
	ldy #0
@WriteTileString:
	lda NmtUpdateRAM, X
	sta $2007
	inx
	iny
	cpy Scratch+0
	bne @WriteTileString
; Loop term
	cpx Nmt_Diaper
	bne @WriteNextAddr
; Reinit	
	lda #$00
	sta Nmt_Diaper
	
@Scroll:
	lda #%10010000
	ora ScrollNt
	sta PPUCTRL ; nametable
	lda PPUSTATUS
	; fix scroll position
	lda #00
	sta PPUSCROLL
	lda ScrollY	
	sta PPUSCROLL
	; enable rendering (with sprites potentially off)
	lda #%00001110
	ora SpritesOn
	sta PPUMASK
	; flag ppu update complete
	lda #0
	sta NMI_Status
	; nmi over
@NMIend:
	; unlock reentryflag
	lda #0
	sta NMI_Lock
	; restore registers
	pla
	tay ; y
	pla
	tax ; x
	pla ; a
	rti

;
; draw utils
;
; these are effectively code terminating functions--
; use these whenever you need to wait for nmi for some purpose

.segment "CODE"
; use when you want to update ppu. 
; enables rendering, uploads oam, updates nametables
; runs until next nmi is complete
ppu_update:
	lda #1
	sta NMI_Status
	: 
		lda NMI_Status
		bne :-
	rts

; kills ppu 
; good time to write to raw ppu memory
; (PPU_AddressTile followed by shenanigans)
ppu_off:
	lda #2
	sta NMI_Status
	:
		lda NMI_Status
		bne :-
	rts

; sets memory address to tile at x/y
; use with rendering off
; ready for a PPUDATA write after calling this 
; y =  0- 31 nmt $2000, 32- 63 nmt $2400, 64- 95 nmt $2800, 96-127 nmt $2C00
; not for single tilewrites, more for full screens
PPU_OFF_AddressTile:
	lda PPUSTATUS ; latch
	tya ; memcpy
	lsr
	lsr
	lsr ; y div 4
	;; damn. bbbs you are fucking yoked dog
	ora #$20 ; hi bits + $20
	sta PPUADDR
	tya ; memcpy again, this time for ypos
	asl
	asl
	asl
	asl
	asl ; y mul 32, aka row num
	sta poop
	; xcoord:
	txa ; memcpy
	ora poop
	sta $2006 ; y + x
	rts

; stores xy pair in next nmt diaper positions
; Parameters: X/Y as tile pair
; Returns: Y as nmt diaper
PPU_ON_AddressTile:
	txa 
	pha ; temp x stack 
	ldx Nmt_Diaper
	tya ; memcpy
	lsr
	lsr
	lsr ; div4
	ora #$20
	sta NmtUpdateRAM, x ; buffer hi 
	inx
	tya
	asl
	asl
	asl
	asl
	asl ; mul32
	sta poop
	; xcoord:
	pla ; recover x from earlier
	ora poop
	sta NmtUpdateRAM, x ; buffer lo

	inx
	stx Nmt_Diaper ; update buffersize 
	txa
	tay
	
	rts
