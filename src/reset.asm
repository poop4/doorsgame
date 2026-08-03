;
; reset routine
;

.include "system.inc"
.include "reset.inc"
.include "main.inc"
.include "nmi.inc"

.segment "CODE"
reset:
	sei 		; mask interrupts
	cld 		; disable bcd
	lda #0
	sta PPUCTRL	; disable NMI
	sta PPUMASK ; disable rendering
	sta $4015	; disable APU sound
	sta $4010	; disable DMC IRQ
	lda #$40	
	sta $4017	; disable APU IRQ
	ldx #$FF
	txs			; initialize stack
	; wait for vblank
	bit $2002
	:
		bit $2002
		bpl :-
	lda #0
	ldx #0
	:
		sta $0000, x
		sta $0100, x
		sta $0200, x
		sta $0300, x
		sta $0400, x
		sta $0500, x
		sta $0600, x
		sta $0700, x
		inx
		bne :-
	; shove sprites
	lda #255
	ldx #0
	:
		sta oam, x
		inx
		inx
		inx
		inx
		bne :-
	; twiddle our damn thumbs
	:
		bit $2002
		bpl :-
	; ok we ball
	lda #%10010000
	sta PPUCTRL ; enable nmi, select chr nmt
	jmp main

