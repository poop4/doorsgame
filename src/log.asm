; 5/28
; TODO:
; write controller reading code
; write constants for palette values 
; write constants for tiles
; write tables for palettes and tile groups
; write proper nametable and attr table
; move a sprite or two around

; 6/3
; TODO
; draw doors
; --
; wrote basic controller read procedure
; not sure if it works yet

; 6/7 LOL!
; ok holpy fuck
; idk how i never realized this but
; NMI is the ONLY thing that runs every frame
; the CPU goes through my code from start to end, which effectively means
; after the JMP forever loop gets called, it is literally, called, forever
; my brain has been pretty fried since this information has come to light but
; it does make a lot of sense.
; moreal of the story?
; i actually sont know
; TODO:
; look at bradsmith example code and start from there

; 6/19
; mostly refactored stuff based on bbbs example 
; for the time being i wanna try keeping everything in one .asm file
; cool bit:
; .segments can be put pretty much anywhere, so i can organize code by
; defining zeropage & ram addresses needed for a particular segment of code
; directly before the code itself. very fun! 
; anyway
; finished reset handler and not much else
; should take a break for now
; --
; ok wrote some todos. little worried i might not learn from copying code but
; whatever

; 6/20
; gonna try writing nmi subroutines (badly) first then adjust from bbbs ex
; --
; busy night
; was slow at first but i got uhhh lets see
; fleshed out nmi states 
; wrote draw utils to be used in main for maintaining nmi behavior and 
; updating nametable memory. stuff took me a while to process
; cool bits:
; -dividing + multiplying y value for nmt addresses and row addresses 
;  two-birds-ing in this bitch, shits efficient
; -inf loops in nmi update subroutines, brings some comfort knowing
;  exactly when i should be using those 
; overall learned quite a bit and i feel more comfortable with control flow
; bbbs i could kiss you right now 
; TODO next:
; organize gamepad polls and write main supplementaries
; not too far from being able to start writing my own code...

; 6/22 00:40
; babys first debug session
; CONGRATULATIONS!!!
; got comfortable using debugger to poke around my code. 
; the problem: nmi handler was not working as intended. status and lock vars
; never got updated so ppu_update was stuck forever. fixing it was as simple
; as moving the status & lock value update code bits to where they should
; have been. it was fun seeing the game crash as an indicator that i had
; successfully run through all of the game code!! great job giddy
; next time:
; play around with screen layouts, get comfortable writing to nametables

; 6/24 15:28
; going fucking insane right now
; nametable writes don't line up vaguely with what shows up onscreen
; bbbs code WORKS it WORKS and thats what drives me up the wall about this
; because my code is effectively a 1:1 clone
; there has got to be ONE major inconsistency thats throwing everything off
; and right now i have no earthly idea what it is
; worst way to spend a sick day istg
; --
; I FUCKING SOLVED IT
; the culprit: neither my ppu_off nor ppu_update states were working as
; intended, haha. so there was no way for me to safely write to nametable 
; memory! i thought i had the issue figured out the first time around, when 
; i found rendering enabled in my reset vector... but that was just a piece 
; of it. really, it was a pretty generic logic flow issue. 
; initially, i had a #%00011100 write to PPUMASK after the nmi_end label,
; which meant that even when ppu_off skipped the majority of the nmi handler,
; its render disable write (the ONLY thing it does) was completely nullified!
; i only realized this control flow issue after i moved the render enable 
; write behind the nmi_end: label and panicked because now rendering NEVER 
; got enabled (and i forgot what exactly i had done, lol). it took a little
; debugging session through the nmi handler for me to realize that nmt_update
; wasn't just skipping its loop on 0-state, it was skipping everything up to
; nmi_end! so i added an @scroll label and had nmt_update redirect to there
; instead. and with that, all my rendering problems are behind me! for now...

; 6/27
; made door artwork

; 6/28
; wrote function to draw a door
; went through a lot of mental iterations before i found one that worked
; and made sense. feels good

; 6/29
; TODO rn:
; cursor code 

; 6/30
; ok today i wrote actual functional cursor code. just moves the selector 
; sprite to some xy position. was a fun little challenge, got a little baby 
; velocity/friction system going too. 
; what to do next... i'll try to get everything i can think of out
; TODO (overall)
; --room header in RAM; utility to read and build level off it
; --selector action: scan area of bg tiles around cursor and return 'hits'
; --game state handler; initgame, titlescreen, initstage, gameplay, end

; 7/1
; happy july
; today we will be trying to organize project code and set up game states

; 7/2
; and by trying i mean not trying 
; goddamn it
; --
; ok today i wrote basic implementation of jumptables 
; now i have to figure out how to make them
; not crash the game.
; im tired
; --
; ok got a little nervy about mode state implementation so
; gonna be reading nes-runner source later to get an idea of where to go

; 7/6
; ok after a good bout of self doubt i'm back on the saddle
; hmm lets see 

; 7/17
; ok was actually fake on the saddle. now i'm REAL on the saddle
; i spent a good portion of 7/14 finally getting the kernel set up, so now 
; all i really have to do is write actual game subroutines. scary!
; alright, let's see if i can't get all of ->this-> knocked out today...
; - Buttons checks on Title Frame, change mode to Dungeon or stall
; - Dungeon Init, render walls, doors, determine 'BoundsBox'es
; - Dungeon Frame, Fairy Move, Fairy Collision, Door Opened
; --
; LOL i really thought i could get all that done
; adhd holy fuck man its 3 am
; anyways. i got the buttons checks done.
; that's it. the fact i was doing this well past should be evidence enough 
; as to why. it was fun though!
; i guess we just go down the list from here
; after getting the data framework can focus on visuals for a little while

; 7/20
; ok did mostly workshopping today i've got some idea of how i wanna implement
; rng dungeon. probably need the following types, just implement one for now:
; -rng background element (16x16)
; -rng background element (32x32) (now that i think about it, maybe implement 
;  custom size elements instead, later)
; -rng monster
; --
; ok back gonna rework everything now
; two rngs: structural and events
;
; Structural:
;
; DOORS:
; 0-254 chance to appear
; range 0-2 to choose correct door
; ROCKS:
; 0-127 chance to appear
; range 0-7 for no. of, 0-7 = 1; 0-3 = 2; 0-1 = 3; 0 = 4;
; for each, range 0-7 for location onscreen
; fixed positions for now
; LAMPS:
; 128-192 chance to appear
; range 0-7 to determine initial state, 0 = on
; DRAWERS:
; 176-239 chance to appear
; range 0-3 contents, 0-1 = nothing; 2-3 = a golden key!
; PORTRAITS:
; 119-135 to appear
; range 0-7 for appearance, 0-6 = painting0, 7 = painting1
; GRAIL:
; appears at 255
;
; structure event initialization
; first clear nt_boundsboxRAM + count
; loop thru each event type ranges, rng > range0?, rng < range1?
; when an event check passes, run additional rng for object(s) & place it
; write to nt_boundsboxRAM & inc count
;
; ok thats enough rubbish for now
; got a pretty solid outline should start writing this asap
; definitely fucking myself staying up til 4 am, haha.
; oh well
; i feel productive
; next steps:
; 1. direct flow in dungeon frame, namely jumps to init and death based on 
;	 Door_Chosen "cmp Door_Good, beq Survived	gamestate=die jmp main"
; 2. write basic structural event initialiation
; 3. write additional rng checks
; 4. write boundsbox initialization
; 5. draw tiles!!
;
; good work today even if you didnt get a lot done
; progress is just around the corner~


; 7/23
; ok, yesterday i started the process of reorganizing everything in  the
; project so far into distinct modules. we've got:
; main, reset, nmi, buttons, title, dungeon... & header and system incs
; next steps:
; 1. shove existing title & dungeon code into their .asms, .incs
; 2. think on individual game systems and create files for each
; 3. insert existing subroutines and start prototyping new ones

; 7/27
; ok forgot to document some stuff thats ok
; basically i did title/dungeon code shoves, fairy movement logic, bounds 
; checking logic on friday, then some art/palette bullshit on 0 food and water 
; that sucked
; and today i implemented:
; - basic RNG; seed in zp, 8bit galois
; - brainstorming dungeon room, getting overwhelmed
; - implemented RoomObjects array, RoomBoxes array, and CreateRoomObject to 
;   handle initialization of both dynamically
;   now in DungeonLoad i should be able to generate IDs + XY offsets for room 
;   objects and then call CreateRoomObject to shove them in the list each time

; 7/28
; welp
; i learned about scoping today
; time to reformat all of my functions
; smiles
; -- 
; ok 
; ok
; WHEWWWWWWWWWW
; FINALLY FINISHED CreateRoomObject for now
; (still need to add attribute code) SHUT up
; I'm so happy about it! Hmm ok, what to do next...
; Let's see, fairy should get a routine to interact (collide) with a room object
; Determine which object we're interacting with and change its state
; Then send the object index to ChangeRoomObjState
; ChangeRoomObjState should jump to the specific behavior needed per ID, then return 
; to frame processing 

; 7/31
; wrote FairyCheckInteract
; runs collision for all in-dungeon objects, then changes state of hit object
; and runs its code via ID jump table hijinx
; THAT WAS FUN 
; next up: (general)
; - Make graphics for plenty of new objects!!!!!!!!! and their respective states
; - Separate fairy movement logic into separate direction subroutines, and friction
; - Implement fairy graphics and increase animation complexity
; - Make behavior code for each object as we create graphics
; - Learn basic audio implementation (use famitone) and integrate it into project
; - Implement psuedo random room generation features
; more can come after this but let's call this the TODO list to complete for now 
; we're doing it...

; 8/2
; fuck whatd i do yesterday
; oh yeah JUST door sprite hahah
; which i ended up scrapping
; cause it sucked
; and then did like
; a dozen more iterations
; and miraculously actually landed on something pretty good

; 8/4
; ok implemented basic scroll behavior yippee!
; still gotta fix a bug relating to first level behavior but
; for the most part it works yay!!! 
; the nametable selection stuff is super jank but it'll work for my purposes

; 8/5 
; fixed that bug, also unjanked the code 
; literally no reason for nttoggle to exist. new version is much cleaner
; very proud of the asl asl before ppuaddr writes that was clever 
; yesterday i felt like i kinda didn't understand what i was doing and now i'm
; much more confident and feel good about the code. but enough about that
; now the dungeon is basically functional
; --
; ok next bit: generate tiles based on dungeon id
; was puzzling over this for a bit but johnybot in nesdev server helped out a ton
; for now i'll implement it as such:
; each bit in the rng sequence beginning at the current seed determines whether 
; a wall or floor tile is placed in that position
; or something like that
; anyways this idea is really cute and fun to me
; the idea of each room's layout being its 'fingerprint' in relation to the full
; seed... haah... it's kinda romantic to me...

; 8/6
; spent an hour writing a DrawVerticalStripe subroutine
; most of this time was spent trying to circumvent making it a subroutine
; why am i like this
; its chill though hopefully i've learned my lesson. subroutines are great
; -- 
; partially related: spent half an hour this morning writing a complex loop that
; ultimately copied one byte to another byte. re: why am i like this
; anyways writing the decorative tile code now
; 