**English** | [Русский](README.ru.md)

# fracgame

Clean-room Godot recreation of the 1990 DOS puzzle game FRAC. 3D pieces fall into a 5×5×12 glass; completed layers
disappear.

## Features

- nine piece types;
- keyboard and numeric-keypad controls;
- cyclic rotation and hard drop;
- wall projections;
- configurable glass, level and starting layers;
- local top-ten leaderboard.

## Controls

- arrows or `QWE` / `AD` / `ZXC`: move;
- keypad `1`–`9`: move, `5`: rotate;
- `S`: rotate;
- `Space`, `Insert`, `Delete` or keypad `0`: hard drop;
- `Enter`: increase speed;
- `P` or `Escape`: pause.

## Run and test

Open `project.godot` with Godot 4.7+.

```powershell
& "C:\path\Godot_console.exe" --headless --path . --script res://tests/run_tests.gd
```

Windows build:

```powershell
.\build_windows.ps1 -GodotConsole "C:\path\Godot_console.exe" -GodotRuntime "C:\path\Godot.exe"
```

MIT License. Original FRAC files and assets are not included.
