# NoAMOS.Library

mock/rtg assembly library for XDEF c extensions or "Custom Chip" less runtimes

# AMOS.Library @ 1536 bytes

AMOS/APSystem/AMOS.library

for use with the command line compiler only:

a replacement AMOS.library for programs that use extension supplied screens and not AMOS native screens, or only have CLI output - it functions correctly with most code as it is, native AMOS.library graphics routines aren't there and can be troublesome in some cases so use this to build programs that don't use the AMOS native graphic calls. classes can be re-enabled in +w.s for experimenting  - vbl is disabled which has some impact, it can be re-enabled by changing '+w.vbl.mock.s' to '+w.vbl.s' and rebuilding.

the build expects the assign AmosProfessional: and the AMOS/ folder to be available

with the MOCK switch it can build a library that can log activity

you can replace the normal AMOS.library so the current compiler can find it, or use the modified APCmp that can load the library from a local folder

to compile something and embed this library change the NOAMOS switch to 1 in +w.s use the command line:

*execute aw"

this builds the noAMOS.libraryy, so then compile with:

*APCmp hello_world.asc NOERR NODEF INCLIB LIBS="AmosProfessional:AMOS/APSystem/*

to use the MOCK switch (default no) allows redirecting graphic calls to help develop new graphics drivers. it requires the use of modified compiler headers
