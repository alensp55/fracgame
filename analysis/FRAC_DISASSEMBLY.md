# DOS FRAC static analysis

## Examined file

- File: `C:\path\fracgame\FRAC.EXE`
- Size: 67,120 bytes
- Timestamp stored on disk: 1990-01-26 11:26:44
- SHA-256: `33DE60685B061932782910EED93C203F3BF0B39DB61788A09D2B293D897076BD`
- Format: 16-bit DOS MZ executable, 3,248-byte header, 804 relocation records
- Entry point in the load module: `0000:2571`

`disassemble_frac.py` uses Capstone in 8086 mode and follows direct local calls and branches from the entry point. The
generated `frac_recursive_disassembly.asm` contains 4,023 discovered instructions. It is a recursive static listing,
not a claim that every byte of the executable is code; indirect jumps and Borland library internals need separate work.

## Confirmed original behavior

| Behavior | Binary evidence | Prototype status |
| --- | --- | --- |
| Playfield is 5x5x12 | Bounds use 6, 6 and 13 at `0A4A-0A5C`; index zero is a guard border | Default is 5x5x12 |
| Setup selects level and layers | Values are read into globals at `22F1-2321` | Available on the new setup screen |
| Initial layers receive ten random cubes | `21B8-2295` loops ten times per selected layer and picks X/Z from 1..5 | Ten of 25; custom sizes use 40% |
| Levels range from 1 through 9 | Maximum-level comparison at `1B6E`; current level increments at `1B87` | Levels 1..9 |
| Automatic level increase is time based | Duration words are multiplied by `0x1770` centiseconds | Two minutes per level |
| Movement uses QWE/AD/ZXC and the numeric keypad | Key comparisons begin at `1C1D`; 7/Q at `1DD9`, 9/E at `1E51` | Implemented |
| One cyclic rotation action uses 5/S | Comparisons at `1EC9-1EE5` | Implemented |
| Space/Delete/Insert drop immediately | Comparisons at `1EEB-1F22`, including ASCII 0, `.`, space and scan codes | Implemented |
| Enter advances the speed level | At `1F29-1F38` the next-level threshold is replaced by the current time | Implemented |
| B toggles sound | Toggle at `1F3A-1F4E` | Deliberately omitted; prototype has no sound |
| Escape ends the current DOS game | Branch at `1F50-1F67` | Prototype currently uses P/Escape for pause |
| Each completed layer adds 100 points | Cleared count is multiplied by 100 at `1301-1317` | Implemented |
| Game over waits for a key | Text at file offset `026E6`, used at `2118-214A` | Replaced by requested name entry |
| A persistent high-score flow exists | `HISCORES.3D`, `HISCORES.TXT` and name/play-again strings are embedded | Local top-ten table implemented |

## Recovered initialized data

- The level delay words are `70, 60, 50, 40, 30, 25, 22, 18, 5` centiseconds for levels 1 through 9.
- The level-duration multipliers are eight values of `2`, followed by `999` for the terminal ninth level. Each multiplier
  is multiplied by 60 seconds. Starting at level N initially schedules the threshold after N accumulated durations.
- The first 25 half-second bonus buckets are
  `20, 17, 15, 13, 12, 11, 10, 10, 9, 9, 8, 8, 7, 7, 6, 6, 6, 5, 5, 5, 4, 4, 4, 4, 4`.
  The bonus is 2 from 12.5 through 22.49 seconds, then 0.
- The 21 weighted orientation records reduce to the nine solid prisms already used by the prototype. Their aggregate
  weights are `30, 60, 60, 6, 60, 40, 6, 15, 1`, for a total weight of 278.

## Still not fully recovered

- The high-score record layout and any score obfuscation in `HISCORES.3D` have not yet been reconstructed.

No original machine code is copied into the Godot project. The listing is used only to document observable rules and
compare the clean-room prototype with the DOS executable.
