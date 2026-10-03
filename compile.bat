@echo off

ca65 src/prgm.asm -o src/obj/prgm.o
ca65 src/nmi.asm -o src/obj/nmi.o
ca65 src/reset.asm -o src/obj/reset.o
ca65 src/buttons.asm -o src/obj/buttons.o
ca65 src/ppu_utility.asm -o src/obj/ppu_utility.o
ca65 src/prgm_title.asm -o src/obj/prgm_title.o
ca65 src/fairy.asm -o src/obj/fairy.o
ca65 src/prgm_dungeon.asm -o src/obj/prgm_dungeon.o
ca65 src/dungeon_room.asm -o src/obj/dungeon_room.o
ca65 src/rng.asm -o src/obj/rng.o
ca65 src/monsters.asm -o src/obj/monsters.o
ca65 src/score.asm -o src/obj/score.o
ca65 src/prgm_death.asm -o src/obj/prgm_death.o

ld65 -C "nes.cfg" ^
src/obj/prgm.o ^
src/obj/nmi.o ^
src/obj/reset.o ^
src/obj/buttons.o ^
src/obj/ppu_utility.o ^
src/obj/prgm_title.o ^
src/obj/fairy.o ^
src/obj/prgm_dungeon.o ^
src/obj/dungeon_room.o ^
src/obj/rng.o ^
src/obj/monsters.o ^
src/obj/score.o ^
src/obj/prgm_death.o ^
-o "doors.nes" --dbgfile "doors.dbg"

pause