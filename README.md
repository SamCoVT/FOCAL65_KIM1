# FOCAL65_KIM1
FOCAL-65 for KIM-1 computers based on the source of the Aresco version (V3D) for TIM

Source code typed in from a scanned listing of a 1977 printout and
verified against a binary version saved by Hans Otten.  The goal is to
get source code that assembles to a byte-exact version of the
historical binary.  Hans has also typed in this code to recreate the
original assembly for both a KIM-1 and TIM version, and you can find
his sources here: http://retro.hansotten.nl/6502-sbc/focal-65-v3d/
along with some history.

Hans Otten also has an excellent simulator for the KIM-1 here:
http://retro.hansotten.nl/6502-sbc/kim-1-manuals-and-software/kim-1-simulator/
This software should run on the KIM-1 Simulator software but needs a
special FOCAL setting turned on (details on both the FOCAL-65 and
KIM-1 simulator pages).

This is a separate effort from Hans Otten's work to recreate this code
from the scanned listing.  This code has been formatted for the
Kowalski assembler, but should assemble with other assemblers with
only minor formatting or assembler directive changes.

# Current Status:

The source assembles but is not yet a binary match to the historical
version.  Most of the source code typos have been eliminated.  

I may also install the zero-page initialization patch.
The sources for this patch (and other historical
patches) are available on Hans Otten's FOCAL-65 page in the "KIM/6502
User notes" section:
http://retro.hansotten.nl/6502-sbc/focal-65-v3d/#articles

Hans Otten has also provided a "clean" version of the binary, as the
version I am currently comparing to has extra unneeded bytes in zero
page and on the end.  I will be switching to that binary version
shortly.

# Assembling Notes:
Using v1.3.4.7 from https://sbc.rictor.org/kowalski.html

Simulator (menu) -> Options -> Assembler Tab

Select Generate listing (and give file name) if you want a listing.

Unselect "Generate extra byte" under "Extra byte after BRK instruction"

Assemble (F7)

Assembled code is saved in simulator RAM and needs to be saved to disk.

File (menu) -> Save code

select format at bottom (Files of type: dropdown) and then provide file name

Additional note for using KIM1 simulator - Motorola S-records appear to
get all segments to load into the correct locations with a single file (Intel
hex does not).


# Binary comparison notes:
## Programs used:
Assemble with Kowalski simulator (see above) - it's very important to uncheck the
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
FOCAL-650000.bin - binary dump of zero page from PTP (papertape) file

FOCAL-652000.bin - binary dump of program (starting at $2000) from PTP file

FOCALNEW.bin - binary image (entire 64K memory space) from Kowalski assembler after assembling FOCAL-65-SOURCE_ARESCOV3D_RAW-WORK_V2.asm 

Cleaner original binary from Hans Otten:

FOCALZP.BIN - binary dump of zero page

FOCALM.BIN - binary dump of program (starting at $2000)

## Zero page compare
dhex FOCALNEW.bin FOCAL-650000.bin

## Program compare
dhex -a2h 2000 -o1h 2000 FOCALNEW.bin FOCAL-652000.bin
