;
; systems related to:
; creating/destroying floor items
; handling item events as needed
;

.smart
.debuginfo+
.include "items.inc"
.include "prgm.inc"
.include "dungeon_room.inc"
.include "ppu_utility.inc"
.include "buttons.inc"
.include "fairy.inc"

; there are two items planned at time of writing
; feather - 
; dropped from plucked birds, activates on and nullifies death
; key	  - 
; dropped by certain room objects under certain conditions, allows opening one 'locked' door

.segment "ZEROPAGE"
items_Modes:  .res 4
items_States: .res 4
items_Feather_Timers: .res 4
items_Feather_Floors: .res 4 ; used as reference point from fall

items_Inventory: .res 2 ; 8 2-bit indices

.segment "BSS"
cells_item0: .res 5
cells_item1: .res 5
cells_item2: .res 5
cells_item3: .res 5


.segment "CODE"
; _______________________________________________________________
; 																|
; 				initialize/destroy key or feather				|
;																|
; Parameters:
; A -- item index
; X,Y -- screen index (px)
; Scratch+0 -- per-item parameters
.proc create_item

ItemExtraParams := Scratch+0
ItemX := Scratch+1
ItemY := Scratch+2
ItemMode := Scratch+3
ItemIndex := Scratch+4
ItemCellsPtr := TmpPtr

	sta ItemMode
	stx ItemX
	sty ItemY
	
; TODO handle xtra parameters
	
	
; Loop thru items modes and store mode & index
	ldx #$FF
:
	inx
	lda items_Modes, X
	cmp #$FF
	bne :-
	
	stx ItemIndex
	lda ItemMode
	sta items_Modes, X
	lda #$00
	sta items_States, X
	lda ItemExtraParams ; for now just feathers use this
	sta items_Feather_Floors, X
	
; Put item in cells list
	
	; Grab cells ptr
	ldx ItemIndex
	lda loptr_table_cells_items, X
	sta ItemCellsPtr
	lda hiptr_table_cells_items, X
	sta ItemCellsPtr+1
	
	; search for open spot
	ldx #0
:
	lda cells_Ptrs+1, X
	beq :+
	inx
	inx
	jmp :-
:
	; st cells ptr in open spot
	lda ItemCellsPtr
	sta cells_Ptrs, X
	lda ItemCellsPtr+1
	sta cells_Ptrs+1, X
	
; Fill item cells per-mode
	ldy #0
	
	lda ItemY
	sta (ItemCellsPtr), Y
	iny
	
	ldx ItemMode
	lda table_items_OAM1, X
	sta (ItemCellsPtr), Y
	iny
	
	lda #%00000011 ; may need to adjust later if items use other palettes
	sta (ItemCellsPtr), Y
	iny
	
	lda ItemX
	sta (ItemCellsPtr), Y
	iny
	
	lda #$FF
	sta (ItemCellsPtr), Y
	
	rts
	
; __ __

table_items_OAM1:
.byte $12 ; Key
.byte $13 ; Feathre

.endproc

loptr_table_cells_items:
.lobytes cells_item0
.lobytes cells_item1
.lobytes cells_item2
.lobytes cells_item3
	
hiptr_table_cells_items:
.hibytes cells_item0
.hibytes cells_item1
.hibytes cells_item2
.hibytes cells_item3


; clears an item from the list. also removes from cells memory
.proc destroy_item
; Parameters:
; X -- item index

; Clear from list
	lda #$FF
	sta items_Modes, X
	lda #$00
	sta items_States, X
	
; Surf thru cells list for matching pointer
	ldy #$FE
:
	cpy #CELLS_MAX ; loop error/
	beq @Done
	iny
	iny
	lda loptr_table_cells_items, X
	cmp cells_Ptrs, Y
	beq :+
	
	jmp :-
:
	lda hiptr_table_cells_items, X
	cmp cells_Ptrs+1, Y
	bne :--
	
; Found match, delete
	lda #$00
	sta cells_Ptrs-1, Y
	sta cells_Ptrs, Y
	
@Done:
	rts
	
.endproc
;															END |
; ______________________________________________________________|


; _______________________________________________________________
; 																|
; 						items event handler						|
; 																|
.proc handler_items

StateEventPtr := TmpPtr
OuterLoopItemIndex := Scratch+0

; for each nonFFmode member of items process an event handler
	ldx #0
	stx OuterLoopItemIndex
@ItemsLoop:
	lda items_Modes, X
	cmp #$FF
	bne :+
	
	jmp @Loop
:
	
	; Index for this iteration established!
	stx OuterLoopItemIndex
	tax ; mode
	
; Assign event table, read state and jump to current event
@ItemsEventLoop:
	lda table_offsets_ItemEvents, X ; Choose mode
	clc
	ldx OuterLoopItemIndex
	adc items_States, X ; Add state of looped item
	tax
	lda loptr_table_ItemEvents, X
	sta StateEventPtr
	lda hiptr_table_ItemEvents, X
	sta StateEventPtr+1

	; whee!
	jsr trampoline

; Next item?
@Loop:
	ldx OuterLoopItemIndex
	inx
	stx OuterLoopItemIndex
	cpx #4
	bne @ItemsLoop
	
	rts
	
	
trampoline:
	jmp (StateEventPtr)
	
	
table_offsets_ItemEvents:
.byte (lo_Key - loptr_table_ItemEvents)
.byte (lo_Feather - loptr_table_ItemEvents)

; __ __

loptr_table_ItemEvents:

lo_Key:
.lobytes item_Generic_IdleEvent
.lobytes item_Key_PickupEvent

lo_Feather:
.lobytes item_Feather_FallEvent
.lobytes item_Generic_IdleEvent
.lobytes item_Feather_PickupEvent

hiptr_table_ItemEvents:

hi_Key:
.hibytes item_Generic_IdleEvent
.hibytes item_Key_PickupEvent

hi_Feather:
.hibytes item_Feather_FallEvent
.hibytes item_Generic_IdleEvent
.hibytes item_Feather_PickupEvent
;																|
; __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __| Events
;																|
item_Generic_IdleEvent:

ItemX := Scratch+1
ItemY := Scratch+2

; Wait for buttonpress then check fairyXY against itemXY ish
	lda #PAD_A
	jsr CheckButtons
	beq @Done
	
	; ok grab cell pos of this item
	ldx OuterLoopItemIndex
	
	ldy #$FE ; acct for dinc
:
	iny
	iny
	lda loptr_table_cells_items, X
	cmp cells_Ptrs, Y
	beq :+
	
	jmp :-
:
	lda hiptr_table_cells_items, X
	cmp cells_Ptrs+1, Y
	bne :--
	
	; Found the cells pointer
	sta TmpPtr+1
	lda loptr_table_cells_items, X
	sta TmpPtr
	
; Compare xys

	; Grab itemxy
	ldy #0
	lda (TmpPtr), Y
	sta ItemY
	iny
	iny
	iny
	lda (TmpPtr), Y
	sta ItemX
	
	; Cmp fairy values w/box
	lda ItemY
	sec
	sbc #$08
	cmp fairy_Y ; (FAIRY.ASM)
	

; we don't really need to do anything after that

@Done:

	rts
; __ __ 

item_Key_PickupEvent:
	
	
	
	ldx OuterLoopItemIndex
	jmp destroy_item
	
; __ __

item_Feather_FallEvent:
	
	rts
; __ __

item_Feather_PickupEvent:
	
	
	
	ldx OuterLoopItemIndex
	jmp destroy_item
; __ __

.endproc
;															END |
; ______________________________________________________________|