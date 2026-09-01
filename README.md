# fracgame

`fracgame` is a clean-room Godot recreation of the 1990 DOS puzzle game FRAC. Solid 3D pieces fall into a 5×5×12
glass, completed horizontal layers disappear, and everything above them drops down.

The repository contains only the new implementation. The original DOS executable, artwork and other game files are
not included.

## Features

- Original nine solid piece types and their recovered selection weights.
- Keyboard and numeric-keypad movement, including diagonals.
- Single-button cyclic rotation.
- Active-piece projections on both far walls, without a floor shadow.
- Recovered DOS fall speeds, level timing, bonus table and scoring rules.
- Configurable glass dimensions, starting level, starting layers and available pieces.
- Local top-ten leaderboard.

## Controls

- Arrow keys or `QWE` / `AD` / `ZXC`: move a piece.
- Numeric keypad `1`–`9`: move in eight directions; `5` rotates.
- `S`: rotate.
- `Space`, `Insert`, `Delete`, keypad `0` or decimal point: hard drop.
- `Enter`: increase the speed level.
- `P` or `Escape`: pause.

## Run from source

Open `project.godot` with Godot 4.7 or newer.

Run the automated tests:

```powershell
& "C:\path\to\Godot_console.exe" --headless --path . --script res://tests/run_tests.gd
```

The current Windows build helper expects Godot 4.7.2 in `C:\path\Godot`:

```powershell
.\build_windows.ps1
```

## License

The new implementation is available under the MIT License. FRAC and any original assets belong to their respective
copyright holders and are not distributed here.
