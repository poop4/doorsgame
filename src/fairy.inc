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
.globalzp CursorBoundsBox

; subroutines
.global CreateFairy
.global DrawFairy
.global FairyBoundsCheck
.global FairyMove_Player
.global FairyCheckInteract

; tables
.global sp_fairy