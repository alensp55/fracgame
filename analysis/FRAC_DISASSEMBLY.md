# DOS FRAC static analysis

Analysed file: `FRAC.EXE`, 67,120 bytes, 16-bit DOS MZ.

SHA-256: `33DE60685B061932782910EED93C203F3BF0B39DB61788A09D2B293D897076BD`.

`disassemble_frac.py` uses Capstone in 8086 mode and follows local calls and branches from the entry point.

## Confirmed behaviour

- playfield: 5×5×12;
- levels: 1–9;
- ten random cubes per initial layer;
- controls: `QWE` / `AD` / `ZXC`, keypad, `5` / `S`, hard drop and `Enter`;
- completed layer: 100 points;
- persistent high-score flow.

Recovered level delays: `70, 60, 50, 40, 30, 25, 22, 18, 5` centiseconds.

Recovered piece weights: `30, 60, 60, 6, 60, 40, 6, 15, 1`.

The high-score record layout is not yet decoded. No original machine code is included in the Godot project.
