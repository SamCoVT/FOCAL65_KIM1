# FOCAL65_KIM1
FOCAL-65 for KIM-1 computers based on the source of the Aresco version (V3D) for TIM

This version is the KIM-1 Aresco version, with reconstructed source
built based on the original Aresco binary from Hans Otten's site, plus
consultation of the similar 6502 Group/Program Exchange V3D source for
the TIM monitor (which Hans has reconstructed) to recreate source
for the Aresco version.

Hans has also typed in this code to recreate the original assembly for
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

This version has been modified to use the Kowalski simulator I/O at $F000

## Running Notes:

Using v1.3.4.7 from https://sbc.rictor.org/kowalski.html

Simulator (menu) -> Options -> Assembler Tab

Unselect "Generate extra byte" under "Extra byte after BRK instruction"

Assemble (F7)

Start Debug Mode (F6)

Turn on I/O Window (View menu -> Input/Output or press ALT-5)

Run (F5)

See here for FOCAL-65 User Manuals:
http://retro.hansotten.nl/6502-sbc/focal-65-v3d/#reference
