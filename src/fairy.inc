;
;
;

; const
FAIRY_NORMAL =	$00
FAIRY_STOPPED =	$01

; variables
.globalzp CursorX
.globalzp CursorY
.globalzp CursorState

; subroutines
.global FairyCreate
.global HandleFairyEvents
.global FairyBoundsCheck
.global FairyMove_Left
.global FairyMove_Up
.global FairyMove_Right
.global FairyMove_Down
.global FairyMove
.global FairyCheckInteract

; tables
.global sp_fairy