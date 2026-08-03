;
;
;

; Constants
TILE_WALLS = $FE
TILE_FLOOR = $FF

OBJ_DOOR	= $00
OBJ_STONE	= $01
OBJ_BRICK	= $02

ROOMOBJ_MAX = $10

; Variables
.global RoomObjects
.global RoomObjBoxes_Left
.global RoomObjBoxes_Top
.global RoomObjBoxes_Right
.global RoomObjBoxes_Bottom
.global RoomObjStates

; Subroutines
.global GenerateRoom
.global CreateRoomObject

; Tables
.global table_RoomObjBehavior
.global dungeon_palette