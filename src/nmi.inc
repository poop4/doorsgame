; variables

.global nmi_lock
.global nmi_count
.global nmi_status
.global nmt_updateRAM
.global nmt_update_len
.globalzp ScrollY
.globalzp ScrollNt
.globalzp oam_index
.globalzp SpritesOn
.global poop
.global oam
.global paletteRAM

; subroutines

.global nmi 
.global ppu_update
.global ppu_skip
.global ppu_off
.global ppu_address_tile
.global ppu_update_tile