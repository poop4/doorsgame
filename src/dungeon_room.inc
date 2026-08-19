;
;
;

; Constants
TILE_WALLS = $FE
TILE_FLOOR = $FF
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

OBJ_DOOR		= $00
OBJ_DUERER		= $01
OBJ_SUBTITLE	= $02

ROOMOBJ_MAX = $10

; Variables
.globalzp RoomSeed
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