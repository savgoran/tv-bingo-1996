# TV Bingo 1996

Historical source-code archive of a real-time computerized TV bingo system originally developed in Serbia in the mid-1990s under the name **TV Tombola**.

The preserved codebase is primarily written in **CA-Clipper** and **x86 assembly**. It includes source for the live draw application, ticket distribution/processing, printing, XMS memory handling, winner-search routines, Sound Blaster support, operator correction/recovery logic, and related build files.

## Original dataset

The original preserved dataset containing **6,000,000 unique bingo combinations** is stored separately from the Git history as a GitHub Release asset:

**Original TV Bingo Dataset — 6 Million Combinations**

Tag: `original-6m-bingo-dataset`

The release includes the original `tombola.zip` archive together with its SHA-256 checksum.

## Historical build dependencies

The original DOS/Clipper build referenced commercial third-party development tools and libraries that are **not included in this repository**, including CA-Clipper, Blinker, SuccessWare SIX/SIXCDX, CA-Tools, Light Lib Graphics, and Sentinel/SuperPro components.

The Sound Blaster integration used the documented hardware programming interface available to DOS developers at the time. Consulting manufacturer documentation and contemporary programming examples was normal engineering practice, particularly for low-level DSP, DMA, and interrupt handling. Similarity in hardware I/O sequences does not, by itself, imply improper copying or diminish the original engineering work involved in integrating audio support into the TV Tombola system. Any verbatim third-party source code, if identified, should be assessed separately for attribution and redistribution terms.

The repository is preserved primarily for historical and technical study. Reproducing the original executable requires compatible historical development tools and dependencies.

## License

No open-source license is currently granted. The source is published as a historical archive while authorship, third-party dependencies, and original project rights are being reviewed.
