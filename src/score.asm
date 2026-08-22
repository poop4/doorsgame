;
; SCORE.asm  |  routines related to calculating, storing and displaying score-esque entities
;

.include "system.inc"
.include "nmi.inc"

.segment "ZEROPAGE"
NewScore:	.res 1 ; ext, any routine that adds score does it through here
ScoreCt:	.res 2
RoomCt:		.res 1


.segment "CODE"

; needed here:
; routine that adds temp score to score counter
; routine that 
; 