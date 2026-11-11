# TV Bingo 1996 — TV Tombola

**A preserved, real-world DOS-era television bingo system developed in Serbia in the mid-1990s.**

TV Tombola was not just a drawing screen. It was a set of cooperating applications for distributing and accounting for tickets, preparing the sold combinations for a draw, processing results, and producing printed records. The archive preserves CA-Clipper and x86 assembly source from the original project.

This repository is a **historical source-code archive**, not a modernized or ready-to-run software distribution.

## Why this project matters

Running a televised bingo game in the 1990s meant working within DOS memory limits while handling a large volume of ticket combinations and producing results during a live broadcast. The engineering challenge was the **end-to-end workflow**: knowing which tickets had been distributed and sold, transforming that information into a searchable draw dataset, checking combinations efficiently, presenting results, and supporting the operators and printing workflow.

The preserved sources show how business-oriented Clipper code was combined with purpose-built assembly routines for performance-sensitive work.

## Where the system was used

The software was developed for real television bingo/tombola productions and subsequently used or adapted for multiple broadcasters and organizers across the region. The following is the author's recollection of deployments and collaborations; exact broadcast dates and surviving production records are not yet fully documented.

| Period | Broadcaster / location | Production or organizer |
| --- | --- | --- |
| **1995–1996** | **TV K9, Kragujevac** | Initial television tombola deployment |
| **1996–1997** | **Montenegro** | Lottery of Montenegro (Lutrija Crne Gore) |
| Later deployments; dates to be documented | **TV Toš** | Television tombola production |
| Later deployments; dates to be documented | **Top Volley** | Television tombola production |
| Date to be documented | **RTS (Radio Television of Serbia)** | **Keno**, organized by the Lottery of Serbia (Lutrija Srbije) |
| Date to be documented | **TV Politika** | Production organized by **Partizan Volleyball Club**, associated with **Radoslav “Raša” Karaklajić** |
| Date to be documented | **Banja Luka** | Production organized by **FK Borac** |
| Date to be documented | **Aranđelovac** | Local television production associated with a broadcaster/operator known as **“Kinez”**, described by the author as Vesna Zmijanac's manager |
| Date to be documented | **Novi Pazar** | Production associated with **Magi Sinanović** |

This deployment history is essential context for the source code: the system was designed for repeated use under real production conditions, across different venues and organizers, not merely as a laboratory demonstration.

The author recalls that comparatively few ready-made TV Tombola systems were available in the region at that time. This is a contemporary market impression, **not a verified market-share or exclusivity claim**.

## The system at a glance

| Area | Role | Source directory |
| --- | --- | --- |
| Ticket distribution and preparation | Ticket series, agents, assignment and reconciliation of ticket ranges, preparation of sold combinations | [`distribution/`](distribution/) |
| Live draw and results | Draw display, combination matching, prize/result calculations, on-screen presentation and operator functions | [`draw/`](draw/) |
| Printing and reporting | Ticket/record printing, prize reports and related operational outputs | [`printing/`](printing/) |

These are related parts of a larger workflow; individual filenames do not necessarily correspond to standalone programs.

## How a draw worked

1. **Create and distribute ticket series.** The distribution subsystem tracks numbered series and ranges allocated to agents.
2. **Reconcile the tickets.** Returned/unsold and sold ranges matter: the live draw must work against the appropriate participating combinations, not merely every possible ticket.
3. **Prepare the draw data.** The source in [`distribution/PRG/PRIPREMA.PRG`](distribution/PRG/PRIPREMA.PRG) builds `CNLIST.DAT` and related data from the distribution records. Its comments document a fixed-width representation of ticket combinations and a file header/end marker.
4. **Conduct the draw and count matches.** The draw subsystem uses Clipper for orchestration and assembly for tight loops over packed combinations.
5. **Display results and prepare records.** The result-processing and printing code produces winner data, prize information and reports for operational use.

This is a source-based outline of the preserved workflow, not a claim that every original deployment procedure has been reconstructed.

## Technical highlights

### Large-scale combination processing

The original preserved dataset contains **6,000,000 unique bingo combinations** (see the release below). The technical challenge was not simply generating numbers: it was organizing and processing combinations efficiently enough for a television draw.

The assembly routines show a compact, bit-oriented representation and match counting rather than a naive string-by-string comparison. For example:

- [`draw/PRG/CNTTCK.ASM`](draw/PRG/CNTTCK.ASM) scans encoded tickets and counts matches by operating on words and counting set bits.
- [`draw/PRG/SCNTCK.ASM`](draw/PRG/SCNTCK.ASM) implements a specialized complete-match check and collects matching ticket identifiers.
- [`draw/PRG/REZ.PRG`](draw/PRG/REZ.PRG) calls the counting routine and processes result categories, including 15, 14 and 13 matches.

The author recalls very fast searches, on the order of a million combinations per second on the target hardware. **That is a historical recollection, not a benchmark reproduced on modern hardware.** Any precise performance claim needs an identified original machine, dataset, measurement method and reproducible test.

### Custom XMS memory support for large files

One of the central engineering challenges was a limitation of the development environment: **CA-Clipper did not provide the large-file-in-memory workflow this application required.** The author therefore implemented a custom Clipper-to-assembly memory-management layer to make extended memory available to the TV Tombola application.

This was not a replacement for the DOS HIMEM/XMS driver. It was **application-level support built on top of the documented XMS interface**, enabling Clipper code to allocate and access extended memory and to stage large files there.

The preserved implementation shows the mechanism:

- [`draw/PRG/XMS.ASM`](draw/PRG/XMS.ASM) detects XMS, obtains the driver entry point, queries and allocates memory, transfers pages between conventional and extended memory, and supplies file-to-XMS and XMS-to-file operations.
- [`draw/PRG/SXMS.PRG`](draw/PRG/SXMS.PRG) exposes higher-level Clipper functions such as `XMS_Init`, `XMS_Alloc`, `F2XMS`, and `XMS_Close`.
- `F2XMS` reads a file in **32 KiB chunks** and moves those chunks into extended memory. It also handles the header of the prepared `CNLIST.DAT` draw dataset.
- [`draw/PRG/CNTTCK.ASM`](draw/PRG/CNTTCK.ASM) and [`draw/PRG/SCNTCK.ASM`](draw/PRG/SCNTCK.ASM) work through pages of encoded combinations held in extended memory, allowing performance-critical scanning without representing the entire dataset as ordinary Clipper objects.

This custom bridge between a high-level database application and low-level DOS memory services was a **prerequisite for the large-scale, fast combination processing** at the heart of the system.

### Operational controls and recoverability

A live broadcast is an operational environment: operators need predictable screens, data preparation, results and ways to handle corrections or interruptions. The repository contains draw/menu, result, utility and recovery-related code. These mechanisms are part of the system's significance even though they are less visually striking than the draw itself.

### Printing and distribution were first-class concerns

The preserved application is not limited to the studio. It also includes the practical work around the game: managing ticket inventory and sales ranges, preparing participating records, and generating printed outputs and reports. That wider scope is why the three directories should be understood together.

### Graphics and audio

The draw application also contains graphics/display code and Sound Blaster support. The audio routines used the documented programming interface available to DOS developers; using manufacturer documentation and contemporary examples was normal engineering practice. Audio was **a supporting feature, not the core innovation** of TV Tombola.

## Repository structure

```text
.
├── distribution/
│   ├── BIN/       # Historical build/link files
│   └── PRG/       # Distribution, reconciliation and draw preparation
├── draw/
│   ├── BIN/       # Historical build/link files
│   └── PRG/       # Draw, results, display, assembly and memory routines
├── printing/
│   ├── BIN/       # Historical build/link files
│   └── PRG/       # Printing and reporting
└── README.md
```

Some representative starting points:

| File | What to inspect |
| --- | --- |
| [`distribution/PRG/ZADUZM.PRG`](distribution/PRG/ZADUZM.PRG) | Assignment of ticket ranges to agents |
| [`distribution/PRG/PRIPREMA.PRG`](distribution/PRG/PRIPREMA.PRG) | Preparing the sold-combination dataset |
| [`draw/PRG/CNTTCK.ASM`](draw/PRG/CNTTCK.ASM) | Low-level match counting |
| [`draw/PRG/SCNTCK.ASM`](draw/PRG/SCNTCK.ASM) | Specialized complete-match search |
| [`draw/PRG/REZ.PRG`](draw/PRG/REZ.PRG) | Result and prize-category processing |
| [`printing/PRG/IZV.PRG`](printing/PRG/IZV.PRG) | Printed prize and winner reporting |
| [`draw/BIN/IZV.RMK`](draw/BIN/IZV.RMK) | Original Clipper/MASM/Blinker build recipe |

## Original six-million-combination dataset

The preserved dataset of **6,000,000 unique combinations** is intentionally stored outside normal Git history as a GitHub Release asset.

**Release:** [Original TV Bingo Dataset — 6 Million Combinations](https://github.com/savgoran/tv-bingo-1996/releases/tag/original-6m-bingo-dataset)  
**Tag:** `original-6m-bingo-dataset`

The release includes the original `tombola.zip` archive and a SHA-256 checksum. Retaining the dataset separately makes the source archive easier to explore.

## Historical development environment

The project reflects the tools and constraints of its time:

- **CA-Clipper** for application logic and database-oriented workflows;
- **x86 assembly / MASM** for performance-critical routines and low-level operations;
- **DOS extended memory (XMS)** for processing data beyond conventional memory;
- **Blinker** and third-party Clipper libraries for linking and runtime functionality;
- historical database, graphics, printing and hardware interfaces.

The build references commercial tools and libraries **not included in this repository**, including CA-Clipper, Blinker, SuccessWare SIX/SIXCDX, CA-Tools, Light Lib Graphics, and Sentinel/SuperPro components. Rebuilding the original programs requires compatible period tooling and dependencies; no modern build is claimed here.

## Historical context and attribution

The author originally developed the software in the mid-1990s for the TV Tombola workflow. This repository preserves available project source material for technical and historical study.

It is not presented as a claim that every library, hardware example, development tool or dependency was authored from scratch. The engineering work lies in the design, adaptation and integration of the complete solution. Where identifiable third-party code is present, its attribution and redistribution conditions should be considered separately.

## Archive status

The source has **not** been ported to a current platform or systematically rebuilt and benchmarked in this repository. Original operational history, hardware configurations and measured throughput can be documented further as supporting evidence becomes available.

## License

No open-source license is currently granted. The source is published as a historical archive while authorship, third-party dependencies, and original project rights are being reviewed.
