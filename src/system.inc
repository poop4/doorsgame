;
; system const
;

PPUCTRL = $2000 ; w x--x x-xx  nmi enable, bg/sp CHR selects, nametable select
PPUMASK = $2001 ; w ---x x---  sp enable, bg enable
PPUSTATUS = $2002 ; r xx-- ----  vblank detection, sprite0 behavior, resets ppuaddr latch 

PPUSCROLL = $2005 ; uhh. later.

PPUADDR = $2006 ; w2 xxxx xxxx  vram addr increments after ppudata access
PPUDATA = $2007 ; rw xxxx xxxx  2kb vram 

OAMADDR = $2003 ; always write $00
OAMDMA = $4014 ; always write $02

JOYPAD1 = $4016 ; controller port
JOYPAD2 = $4017
