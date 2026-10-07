;
; program modes
;

MODE_TITLE		= $00
MODE_DUNGEON	= $01
MODE_DEATH		= $02
MODE_EXIT		= $03

TITLE_START_A	= $00
TITLE_START_B	= $01

LEFT =			$00
TOP =			$01
RIGHT =		$02
BOTTOM =	$03

;
; variables
;

.globalzp Scratch
.globalzp DarkScratch
.globalzp TmpPtr
.globalzp TmpPtr2
.globalzp PrgmMode
.globalzp PrgmMode_Diaper
.globalzp PrgmModeState
.globalzp PrgmFramePtr
.globalzp PrgmTimer
.globalzp PrgmTimer_4f
.globalzp GenericTimer
.globalzp ButtonsTimer
.globalzp NextRoomTimer
.globalzp ScrollNt
.globalzp NeedScroll

;
; subroutines
;

.global main
.global mainloop


; alphabet 
_A = $0A
_B = $0B
_C = $0C
_D = $0D
_E = $0E
_F = $0F
_G = $10
_H = $11
_I = $12
_J = $13
_K = $14
_L = $15
_M = $16
_N = $17
_O = $18
_P = $19
_Q = $1A
_R = $1B
_S = $1C
_T = $1D
_U = $1E
_V = $1F
_W = $20
_X = $21
_Y = $22
_Z = $22
__ = $FD
_PERIOD = $5A
_COPYRIGHT = $59
_LOCK = $65