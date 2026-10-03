;
; Crows
;

.include "birds.inc"
.include "prgm.inc"
.include "dungeon_room.inc"
.include "ppu_utility.inc"
.debuginfo+
.smart


.segment "ZEROPAGE"
BirdsMode: 			.res 4 ; state
BIRDMODE_NULL = $00
BIRDMODE_ALIVE = $01
BIRDMODE_DEAD = $02
BirdsState: 		.res 4 ; sub state
BIRDSTATE_IDLE = $00
BIRDSTATE_FLYING = $01
BIRDSTATE_FIGHTING = $02
BirdsMood:			.res 4 ; sub sub state
BIRDSMOOD_HUNGRY = $00
BIRDSMOOD_CONTENT = $01
BIRDSMOOD_UPSET = $02
BirdsStateTimers:	.res 4 ; used for state & animations
BirdsMomentum:		.res 4 ; x or y movement

.segment "BSS"
BirdsBoxes_left:		.res 4
BirdsBoxes_top:			.res 4
BirdsBoxes_right:		.res 4
BirdsBoxes_bottom:		.res 4
BirdsCells0:			.res 8
BirdsCells1:			.res 8
BirdsCells2:			.res 8
BirdsCells3:			.res 8