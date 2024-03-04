# FOCAL65_KIM1
Aresco FOCAL-65 for KIM-1 computers, based on the source of the Denver 6502 Group/Program Exchange version (V3D) for TIM.

This version is the KIM-1 Aresco version, with reconstructed source
built based on the original Aresco binary from Hans Otten's site, plus
consultation of the similar 6502 Group/Program Exchange V3D source for
the TIM monitor (which Hans has reconstructed) to recreate source
for the Aresco version.

Hans has also typed in the code to recreate the original assembly for
both a KIM-1 and TIM version, and you can find his sources here:
http://retro.hansotten.nl/6502-sbc/focal-65-v3d/ along with some
history.

Hans Otten also has an excellent simulator for the KIM-1 here:
http://retro.hansotten.nl/6502-sbc/kim-1-manuals-and-software/kim-1-simulator/
This software should run on the KIM-1 Simulator software but needs
special FOCAL V3D break handling turned on in the settings.

This is a separate effort from Hans Otten's work to recreate and
verify this code from the scanned listing.  This code has been
formatted for the Kowalski assembler, but should assemble with other
assemblers with only minor formatting or assembler directive changes.

# Current Status:

The source assembles and is a binary match to the historical version
provided by Hans Otten with the exception of extra bytes at the end of
zero page and at the end of the program and the KIM-1 specific I/O
patch (which can be found in the KIM/6502 User Notes on Hans' site:
http://retro.hansotten.nl/6502-sbc/focal-65-v3d/#articles).

This version appears to work in the KIM1 simulator (lightly tested).

I tried adding the zero page initialization routine from the FOCAL
6502 User Notes, but FOCAL does not run properly so that has been
removed in this version.  There appear to be some addresses that are
hard coded that need to be adjusted above and beyond the zero page
values listed in the FOCAL 6502 User Notes.  The code for this patch
has been placed in zpinit.asm.

# Assembling Notes:
Using v1.3.4.7 from https://sbc.rictor.org/kowalski.html

Simulator (menu) -> Options -> Assembler Tab

Select Generate listing (and give file name) if you want a listing.

Unselect "Generate extra byte" under "Extra byte after BRK instruction"

Assemble (F7)

Assembled code is saved in simulator RAM and needs to be saved to disk.

File (menu) -> Save code

select format at bottom (Files of type: dropdown) and then provide file name

Additional note for using KIM1 simulator - Motorola S-records appear
to get all segments to load into the correct locations with a single
file (Intel hex does not.  Binary dumps the entire 64K memory space
and will overwrite hardware configuration registers for the KIM-1, 
causing failure as well).

To get a PTP file, use the Motorola S-records format when saving from the
Kowalski assembler and then use Hans Otten's Convert8bitFormat program
to convert from S-records to MOS PTP format.

# Binary comparison notes:
## Programs used:
Assemble with Kowalski simulator (see above) - it's **very important** to uncheck the
assembler option that generates an extra byte after the BRK instruction.

Save code as "Binary image" to filename FOCALNEW.bin

Convert8bitHexFormat (v2.7 by Hans Otten - had to install some Ubuntu dependencies)

http://retro.hansotten.nl/6502-sbc/kim-1-manuals-and-software/pc-utilities/#converthex

Convert the original PTP (Paper TaPe) file from "MOS papertape" to Binary

Use "FOCAL-65.bin" for filename and you will get FOCAL-650000.bin for zero page data
and FOCAL-652000.bin for program starting at $2000

dhex 0.69 used for binary comparison

http://www.dettus.net/dhex/

## Filenames used:
Original binary from Dave Hassler with some patches applied (I/O and 16K KIM1?):

FOCAL-650000.bin - binary dump of zero page from PTP (papertape) file

FOCAL-652000.bin - binary dump of program (starting at $2000) from PTP file

FOCALNEW.bin - binary image (entire 64K memory space) from Kowalski assembler after assembling FOCAL-65-SOURCE_ARESCOV3D.asm 

Cleaner (no patches) original binary from Hans Otten:

FOCALZP.BIN - binary dump of zero page from Hans Otten

FOCALM.BIN - binary dump of program (starting at $2000) from Hans Otten

## Zero page compare
dhex FOCALNEW.bin FOCALZP.bin

## Program compare
dhex -a2h 2000 -o1h 2000 FOCALNEW.bin FOCALM.bin
