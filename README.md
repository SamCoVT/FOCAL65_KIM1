# FOCAL65_KIM1
FOCAL-65 for KIM-1 computers based on the source of the Aresco version (V3D) for TIM

# Assembling Notes:
Using v1.3.4.7 from https://sbc.rictor.org/kowalski.html
Simulator (menu) -> Options -> Assembler Tab
Select Generate listing (and give file name) if you want a listing.
Unselect "Generate extra byte" under "Extra byte after BRK instruction"
Assemble (F7)

Assembled code is saved in simulator RAM and needs to be saved to disk.
File (menu) -> Save code
select format at bottom (Files of type: dropdown) and then provide file name


# Binary comparison notes:
## Programs used:
Assemble with Kowalski simulator (see above) - it's very important to uncheck the
assembler option that generates an extra byte after the BRK instruction.
Save code as "Binary image" to filename FOCALNEW.BIN

Convert8bitHexFormat (v2.7 by Hans Otten - had to install some Ubuntu dependencies)
http://retro.hansotten.nl/6502-sbc/kim-1-manuals-and-software/pc-utilities/#converthex
Convert the original PTP (Paper TaPe) file from "MOS papertape" to Binary
Use "FOCAL-65.bin" for filename and you will get FOCAL-650000.bin for zero page data
and FOCAL-652000.bin for program starting at $2000

dhex 0.69 used for binary comparison
http://www.dettus.net/dhex/

## Filenames used:
FOCAL-650000.bin - binary dump of zero page from PTP (papertape) file
FOCAL-652000.bin - binary dump of program (starting at $2000) from PTP file
FOCALNEW.bin - binary image (entire 64K memory space) from Kowalski assembler after assembling FOCAL-65-SOURCE_ARESCOV3D_RAW-WORK_V2.asm 

## Zero page compare
dhex FOCALNEW.bin FOCAL-650000.bin

## program compare
dhex -a2h 2000 -o1h 2000 FOCALNEW.bin FOCAL-652000.bin
