; variables

.global NMI_Lock
.global NMI_Status
.global NmtUpdateRAM
.globalzp Nmt_Diaper
.globalzp ScrollY
.globalzp ScrollNt
.globalzp OAM_Index
.globalzp SpritesOn
.global poop
.global oam
.global paletteRAM

; subroutines

.global nmi 
.global ppu_update
.global ppu_skip
.global ppu_off
.global PPU_OFF_AddressTile
.global PPU_ON_AddressTile