;
; nmi routine
;

.debuginfo+
.smart
.include "system.inc"
.include "nmi.inc"

.segment "ZEROPAGE"
nmi_lock:		.res 1 ; prevents nmi re-entry
nmi_count:		.res 1 ; simple counter
nmi_status:		.res 1 ; 1 to push nmi, 2 to disable rendering on next
nmt_update_len:	.res 1 ; bytes in nmt_update
ScrollY:		.res 1
ScrollNt:		.res 1
SpritesOn:		.res 1 ; whether to enable sprite rendering this frame
oam_index:	.res 1	 ; oam curr index
poop:			.res 1 ; temporary variable

.segment "BSS"
nmt_updateRAM: .res 256 ; nametable buffer
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
	lda nmi_lock
	beq :+ ;if lock > 1
	jmp @nmi_end
	:
	; ok we good
	lda #1
	sta nmi_lock
	inc nmi_count
	; adjust next behavior based on status
	lda nmi_status 
	bne :+ ;if status == 0
	jmp @nmi_end
	:
	cmp #2
	bne :+ ; status == 2 turns off rendering 
	lda #%00000110
	sta PPUMASK
	ldx #0
	stx nmi_status
	jmp @nmi_end
	:
	; oam dma
	lda #$00
	sta OAMADDR
	lda #>oam
	sta OAMDMA
	; initialize oam list
	lda #$00
	sta oam_index
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
	; upd nmt
	ldx #0
	cpx nmt_update_len
	bcs @scroll ;if no new tiles, skip to next
@nmt_update_loop:
	lda nmt_updateRAM, x
	sta PPUADDR
	inx 
	lda nmt_updateRAM, x
	sta PPUADDR 
	inx
	lda nmt_updateRAM, x
	sta PPUDATA
	inx
	cpx nmt_update_len
	bcc @nmt_update_loop
	lda #0
	sta nmt_update_len ; done updating reset buffer
@scroll:
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
	sta nmi_status
	; nmi over
@nmi_end:
	; unlock reentryflag
	lda #0
	sta nmi_lock
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
	sta nmi_status
	: 
		lda nmi_status
		bne :-
	rts
	
; use when you DONT want to update ppu! 
; runs for one frame, then returns
ppu_skip:
	lda nmi_count
	:
		cmp nmi_count 
		beq :-
	rts
	
; kills ppu 
; good time to write to raw ppu memory
; (ppu_address_tile followed by shenanigans)
ppu_off:
	lda #2
	sta nmi_status
	:
		lda nmi_status
		bne :-
	rts

; sets memory address to tile at x/y
; use with rendering off
; ready for a PPUDATA write after calling this 
; y =  0- 31 nmt $2000, 32- 63 nmt $2400, 64- 95 nmt $2800, 96-127 nmt $2C00
; not for single tilewrites, more for full screens
ppu_address_tile:
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

; updates a single tile on some nmt 
; can be used with rendering on 
; x/y: namesake | a: tileid
ppu_update_tile:
	pha ; temp a stack 
	txa 
	pha ; temp x stack 
	ldx nmt_update_len
	tya ; memcpy
	lsr
	lsr
	lsr ; div4
	ora #$20
	sta nmt_updateRAM, x ; buffer hi 
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
	sta nmt_updateRAM, x ; buffer lo
	inx
	; write tile
	pla ; recover a (tile)
	sta nmt_updateRAM, x
	inx
	stx nmt_update_len ; update buffersize 
	rts
