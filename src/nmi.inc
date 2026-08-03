; variables

.global nmi_lock
.global nmi_count
.global nmi_status
.global nmt_updateRAM
.global nmt_update_len
.global poop
.global oam_used
.global oam
.global paletteRAM

; subroutines

.global nmi 
.global ppu_update
.global ppu_skip
.global ppu_off
.global ppu_address_tile
.global ppu_update_tile