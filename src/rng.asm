; functions needed here:
; clock rng
; initialize seed (reset vector)

.include "rng.inc"

.segment "ZEROPAGE"
Seed:	.res 1
Range:	.res 1

; thank you bradsmith for showing how to implement galois

; clocks seed (A) 8 times to generate a new 8bit value
.segment "CODE"
ClockRNG:
	ldy #8
:
	asl
	bcc :+
	eor #$1D
:
	dey
	bne :--
	rts
	
; range check, returns an effectively random number out of X range
; parameters: A -- range (chance out of X)
SelectRNG:
	sta Range
	lda Seed
	sec
@DivideLoop:
	sbc Range
	bcs @DivideLoop
	adc Range
	tax
	rts
; returns: X -- rng index for table
