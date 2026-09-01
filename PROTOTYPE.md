# fracgame

Minimal Windows prototype of a 3D falling-block puzzle. The original DOS files are reference material only and are not
loaded or modified by the Godot project.

The ready-to-run Windows bundle is in `builds/windows`. Keep `fracgame.exe` and `fracgame.pck` together, then start
`fracgame.exe`.

The current local Godot installation does not contain export templates. `build_windows.ps1` therefore creates a PCK
and bundles it with the supplied Godot executable. This is suitable for the prototype, but produces a large executable.

## Controls

- The game starts at the main menu: Start begins a game, Records opens high scores and Exit closes the game.
- Settings are shown in a separate panel on the left. Press Tab or Left from the menu to focus them.
- In settings, Up and Down select an option; Left and Right change it; Space toggles a piece; Enter returns to the menu.
- The main menu and every setting can also be selected with the mouse.
- Arrow keys: move over the floor of the playfield; Up moves toward the far wall.
- QWE/AD/ZXC, numeric keypad or number-row 1-4 and 6-9: move, including diagonally.
- S or numeric keypad/number-row 5: cycle through the original three-axis orientations.
- If a diagonal is blocked, the piece tries to slide along each free axis, as in iFRAC.
- Enter: immediately increase the speed level, as in the DOS game.
- Space, Insert, Delete, numeric keypad 0 or decimal point: hard drop.
- P or Escape: pause.

Starting layers reproduce the DOS rule: the original 5x5 glass gets ten random cubes in each selected layer. For custom
glass sizes, each selected layer is filled to 40% and always retains at least one empty cell.

After game over, type a name and press Enter. The ten best name/score pairs are saved in
`user://high_scores.json`; Enter, Space or Escape returns from the high-score table to the main menu.

## Run

Open `project.godot` in Godot 4 or run it from a console:

```powershell
& "C:\path\Godot\Godot_v4.7.2-stable_win64_console.exe" --path "C:\path\fracgame" --editor
```

## Tests

```powershell
& "C:\path\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path "C:\path\fracgame" `
    --script "res://tests/run_tests.gd"
```

## Build for Windows

```powershell
& "C:\path\fracgame\build_windows.ps1"
```
