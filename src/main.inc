;
; program modes
;

MODE_TITLE		= $00
MODE_DUNGEON	= $01
MODE_EXIT		= $02
MODE_DEATH		= $03

TITLE_START		= $00
TITLE_HINTS		= $01

LEFT =			$00
TOP =			$01
RIGHT =		$02
BOTTOM =	$03


;
; variables
;

.globalzp Scratch
.globalzp TmpPtr
.globalzp PrgmMode
.globalzp PrgmMode_update
.globalzp PrgmFramePtr
.globalzp PrgmTimer
.globalzp ButtonsTimer
.globalzp DoorsTimer

;
; subroutines
;

.global main
.global mainloop