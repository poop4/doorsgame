;
;
;

; const
FAIRY_NORMAL =	$00
FAIRY_STOPPED =	$01

; variables
.globalzp fairy_X
.globalzp fairy_Y
.globalzp fairy_State

; subroutines
.global create_fairy
.global handler_fairy_Behavior
.global fairy_BoundsCheck
.global fairy_MoveLeft
.global fairy_MoveUp
.global fairy_MoveRight
.global fairy_MoveDown
.global fairy_Move
.global fairy_CheckInteract

; tables
.global sp_fairy