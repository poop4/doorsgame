;
;
;


; Variables
.globalzp RoomSeed
.global objects
.global object_Boxes_Left
.global object_Boxes_Top
.global object_Boxes_Right
.global object_Boxes_Bottom
.global object_States

; Subroutines
.global create_Room
.global create_object
.global object_QueueBehavior
.global handler_object_Behavior

; Data
.globalzp DungeonInfo

; Tables
.global dungeon_palette

; Constants
TILE_WALLS = $FE
TILE_FLOOR = $FF

OBJ_DOOR		= $00
OBJ_DUERER		= $01
OBJ_SUBTITLE	= $02

OBJ_MAXAMT = $10
