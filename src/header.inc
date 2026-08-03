.segment "HEADER"

NES_MAPPER = 0 ; nrom
NES_MIRROR = 0 ; solder 'V'
NES_SRAM   = 0 ; no coincell

.byte 'N', 'E', 'S', $1A
.byte $02 ; 16k prg count
.byte $01 ; 8k chr count
.byte NES_MIRROR | (NES_SRAM << 1) | ((NES_MAPPER & $f) << 4)
.byte (NES_MAPPER & %11110000)
.byte $0, $0, $0, $0, $0, $0, $0, $0


