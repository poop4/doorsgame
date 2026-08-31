;
; button ids and container
;

PAD_A		= $01
PAD_B 		= $02
PAD_SELECT	= $04
PAD_START	= $08
PAD_UP		= $10
PAD_DOWN	= $20
PAD_LEFT	= $40
PAD_RIGHT	= $80

; subroutine

.global ReadJoypad1
.global CheckButtons

; variable

.globalzp Buttons