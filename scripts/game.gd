extends Node2D

const BoardClass = preload("res://scripts/board.gd")
const PieceCatalog = preload("res://scripts/piece_catalog.gd")

const DEFAULT_BOARD_WIDTH := 5
const DEFAULT_BOARD_HEIGHT := 12
const DEFAULT_BOARD_DEPTH := 5
const MIN_BOARD_SIDE := 3
const MAX_BOARD_SIDE := 9
const MIN_BOARD_HEIGHT := 6
const MAX_BOARD_HEIGHT := 20
const START_BONUS := 20
const LAYER_SCORE := 100
const LEVEL_INTERVALS := [0.70, 0.60, 0.50, 0.40, 0.30, 0.25, 0.22, 0.18, 0.05]
const LEVEL_DURATION_UNIT := 60.0
const LEVEL_DURATION_MULTIPLIERS := [2, 2, 2, 2, 2, 2, 2, 2, 999]
const BONUS_TABLE := [20, 17, 15, 13, 12, 11, 10, 10, 9, 9, 8, 8, 7, 7, 6, 6, 6, 5, 5, 5, 4, 4, 4, 4, 4]
const LEADERBOARD_LIMIT := 10
const HIGH_SCORES_PATH := "user://high_scores.json"
const MAIN_MENU_ITEMS := ["START", "RECORDS", "EXIT"]
const ISO_HALF_WIDTH := 34.0
const ISO_HALF_HEIGHT := 11.0
const CUBE_HEIGHT := 36.0

enum ScreenMode { SETUP, PLAYING, NAME_ENTRY, LEADERBOARD }

var board
var board_width := DEFAULT_BOARD_WIDTH
var board_height := DEFAULT_BOARD_HEIGHT
var board_depth := DEFAULT_BOARD_DEPTH
var start_level := 1
var start_layers := 0
var enabled_piece_indices: Array = range(PieceCatalog.PIECES.size())
var setup_row := 0
var setup_piece_cursor := 0
var setup_focus_settings := false
var main_menu_index := 0
var screen_mode := ScreenMode.SETUP
var active_cells: Array = []
var active_orientations: Array = []
var active_position := Vector3i.ZERO
var active_piece_index := 0
var active_orientation_index := 0
var next_piece_index := 0
var fall_elapsed := 0.0
var cleared_layers := 0
var locked_pieces := 0
var score := 0
var bonus := START_BONUS
var level := 1
var level_elapsed := 0.0
var next_level_at := 0.0
var piece_elapsed := 0.0
var paused := false
var game_over := false
var rng := RandomNumberGenerator.new()
var ui_font: Font
var high_scores: Array = []
var entered_name := ""
var last_score_entry: Dictionary = {}


func _ready() -> void:
	board = BoardClass.new(board_width, board_height, board_depth)
	ui_font = ThemeDB.fallback_font
	rng.randomize()
	_load_high_scores()
	queue_redraw()


func new_game() -> void:
	board = BoardClass.new(board_width, board_height, board_depth)
	cleared_layers = 0
	locked_pieces = 0
	score = 0
	bonus = START_BONUS
	level = start_level
	level_elapsed = 0.0
	next_level_at = level_threshold_for_start(level)
	piece_elapsed = 0.0
	paused = false
	game_over = false
	screen_mode = ScreenMode.PLAYING
	fall_elapsed = 0.0
	_fill_starting_layers()
	next_piece_index = PieceCatalog.pick_piece(rng, enabled_piece_indices)
	_spawn_piece()
	queue_redraw()


func _process(delta: float) -> void:
	if screen_mode != ScreenMode.PLAYING or paused or game_over:
		return
	level_elapsed += delta
	while level_elapsed >= next_level_at and level < LEVEL_INTERVALS.size():
		_increase_level()
	piece_elapsed += delta
	bonus = bonus_for_elapsed(piece_elapsed)
	var interval := interval_for_level(level)
	fall_elapsed += delta
	while fall_elapsed >= interval:
		fall_elapsed -= interval
		_step_down()
		if game_over:
			break
	queue_redraw()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return
	var key: int = event.physical_keycode
	if key == 0:
		key = event.keycode
	if screen_mode == ScreenMode.SETUP:
		_handle_setup_key(event, key)
		return
	if screen_mode == ScreenMode.NAME_ENTRY:
		_handle_name_key(event, key)
		return
	if screen_mode == ScreenMode.LEADERBOARD:
		if not event.echo and key in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_ESCAPE]:
			_return_to_main_menu()
		return
	if key == KEY_P or key == KEY_ESCAPE:
		if not event.echo and not game_over:
			paused = not paused
			queue_redraw()
		return
	if paused or game_over:
		return

	var movement := movement_for_key(key)
	if movement != Vector3i.ZERO:
		_try_horizontal_move(movement)
	else:
		match key:
			KEY_S, KEY_5, KEY_KP_5:
				if not event.echo:
					_cycle_rotation()
			KEY_ENTER, KEY_KP_ENTER:
				if not event.echo:
					_increase_level(true)
			KEY_SPACE, KEY_INSERT, KEY_DELETE, KEY_KP_0, KEY_KP_PERIOD:
				if not event.echo:
					_hard_drop()
	queue_redraw()


static func movement_for_key(key: int) -> Vector3i:
	match key:
		KEY_UP:
			return Vector3i(0, 0, -1)
		KEY_DOWN:
			return Vector3i(0, 0, 1)
		KEY_LEFT:
			return Vector3i(-1, 0, 0)
		KEY_RIGHT:
			return Vector3i(1, 0, 0)
		KEY_Q, KEY_7, KEY_KP_7:
			return Vector3i(-1, 0, -1)
		KEY_W, KEY_8, KEY_KP_8:
			return Vector3i(0, 0, -1)
		KEY_E, KEY_9, KEY_KP_9:
			return Vector3i(1, 0, -1)
		KEY_A, KEY_4, KEY_KP_4:
			return Vector3i(-1, 0, 0)
		KEY_D, KEY_6, KEY_KP_6:
			return Vector3i(1, 0, 0)
		KEY_Z, KEY_1, KEY_KP_1:
			return Vector3i(-1, 0, 1)
		KEY_X, KEY_2, KEY_KP_2:
			return Vector3i(0, 0, 1)
		KEY_C, KEY_3, KEY_KP_3:
			return Vector3i(1, 0, 1)
	return Vector3i.ZERO


func _handle_setup_key(event: InputEventKey, key: int) -> void:
	if key == KEY_TAB and not event.echo:
		setup_focus_settings = not setup_focus_settings
		queue_redraw()
		return
	if not setup_focus_settings:
		match key:
			KEY_UP:
				main_menu_index = posmod(main_menu_index - 1, MAIN_MENU_ITEMS.size())
			KEY_DOWN:
				main_menu_index = posmod(main_menu_index + 1, MAIN_MENU_ITEMS.size())
			KEY_LEFT:
				setup_focus_settings = true
			KEY_ENTER, KEY_KP_ENTER:
				if not event.echo:
					_activate_main_menu()
		queue_redraw()
		return
	match key:
		KEY_UP:
			setup_row = posmod(setup_row - 1, 6)
		KEY_DOWN:
			setup_row = posmod(setup_row + 1, 6)
		KEY_LEFT:
			_change_setup_value(-1)
		KEY_RIGHT:
			_change_setup_value(1)
		KEY_SPACE:
			if setup_row == 5 and not event.echo:
				_toggle_setup_piece()
		KEY_ENTER, KEY_KP_ENTER, KEY_ESCAPE:
			setup_focus_settings = false
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if screen_mode != ScreenMode.SETUP:
		return
	if not event is InputEventMouseButton or not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return
	for index in range(MAIN_MENU_ITEMS.size()):
		if _main_menu_item_rect(index).has_point(event.position):
			setup_focus_settings = false
			main_menu_index = index
			_activate_main_menu()
			return
	for row in range(5):
		var item := _setting_row_rect(row)
		if item.has_point(event.position):
			setup_focus_settings = true
			setup_row = row
			if event.position.x >= item.end.x - 150:
				var direction := -1 if event.position.x < item.end.x - 75 else 1
				_change_setup_value(direction)
			queue_redraw()
			return
	for index in range(PieceCatalog.PIECES.size()):
		if _piece_item_rect(index).has_point(event.position):
			setup_focus_settings = true
			setup_row = 5
			setup_piece_cursor = index
			_toggle_setup_piece()
			queue_redraw()
			return


func _activate_main_menu() -> void:
	match main_menu_index:
		0:
			new_game()
		1:
			screen_mode = ScreenMode.LEADERBOARD
			last_score_entry = {}
		2:
			get_tree().quit()
	queue_redraw()


func _return_to_main_menu() -> void:
	screen_mode = ScreenMode.SETUP
	game_over = false
	paused = false
	setup_focus_settings = false
	main_menu_index = 0
	queue_redraw()


func _change_setup_value(direction: int) -> void:
	match setup_row:
		0:
			board_width = clampi(board_width + direction, MIN_BOARD_SIDE, MAX_BOARD_SIDE)
		1:
			board_depth = clampi(board_depth + direction, MIN_BOARD_SIDE, MAX_BOARD_SIDE)
		2:
			board_height = clampi(board_height + direction, MIN_BOARD_HEIGHT, MAX_BOARD_HEIGHT)
			start_layers = mini(start_layers, _max_start_layers())
		3:
			start_level = clampi(start_level + direction, 1, LEVEL_INTERVALS.size())
		4:
			start_layers = clampi(start_layers + direction, 0, _max_start_layers())
		5:
			setup_piece_cursor = posmod(setup_piece_cursor + direction, PieceCatalog.PIECES.size())


func _toggle_setup_piece() -> void:
	if enabled_piece_indices.has(setup_piece_cursor):
		if enabled_piece_indices.size() > 1:
			enabled_piece_indices.erase(setup_piece_cursor)
	else:
		enabled_piece_indices.append(setup_piece_cursor)
		enabled_piece_indices.sort()


func _handle_name_key(event: InputEventKey, key: int) -> void:
	if key in [KEY_ENTER, KEY_KP_ENTER] and not event.echo:
		var player_name := entered_name.strip_edges()
		if player_name.is_empty():
			player_name = "PLAYER"
		_record_score(player_name)
		screen_mode = ScreenMode.LEADERBOARD
		queue_redraw()
		return
	if key == KEY_BACKSPACE and not event.echo:
		entered_name = entered_name.left(maxi(0, entered_name.length() - 1))
	elif not event.echo and event.unicode >= 32 and entered_name.length() < 12:
		entered_name += String.chr(event.unicode)
	queue_redraw()


func _spawn_piece() -> void:
	active_piece_index = next_piece_index
	next_piece_index = PieceCatalog.pick_piece(rng, enabled_piece_indices)
	var initial_size: Vector3i = PieceCatalog.get_piece(active_piece_index)["size"]
	active_orientations = []
	for orientation in PieceCatalog.get_orientations(initial_size):
		var size := PieceCatalog.size_for_cells(orientation)
		if size.x <= board_width and size.y <= board_height and size.z <= board_depth:
			active_orientations.append(orientation)
	if active_orientations.is_empty():
		_begin_game_over()
		return
	active_orientation_index = rng.randi_range(0, active_orientations.size() - 1)
	active_cells = active_orientations[active_orientation_index].duplicate()
	active_position = _far_spawn_position(active_cells)
	bonus = START_BONUS
	piece_elapsed = 0.0
	if not board.can_place(_world_cells(active_cells, active_position)):
		_begin_game_over()


func _far_spawn_position(local_cells: Array) -> Vector3i:
	var maximum_y := 0
	for cell_value in local_cells:
		var cell: Vector3i = cell_value
		maximum_y = maxi(maximum_y, cell.y)
	return Vector3i(0, board_height - 1 - maximum_y, 0)


func _try_move(offset: Vector3i) -> bool:
	var candidate := active_position + offset
	if not board.can_place(_world_cells(active_cells, candidate)):
		return false
	active_position = candidate
	return true


func _try_horizontal_move(offset: Vector3i) -> bool:
	if _try_move(offset):
		return true
	if offset.x == 0 or offset.z == 0:
		return false
	if _try_move(Vector3i(offset.x, 0, 0)):
		return true
	return _try_move(Vector3i(0, 0, offset.z))


func _cycle_rotation() -> bool:
	var next_orientation := (active_orientation_index + 1) % active_orientations.size()
	var rotated: Array = active_orientations[next_orientation]
	var old_size := PieceCatalog.size_for_cells(active_cells)
	var new_size := PieceCatalog.size_for_cells(rotated)
	var candidate_position := _rotation_position(active_position, old_size, new_size)
	if not board.can_place(_world_cells(rotated, candidate_position)):
		return false
	active_orientation_index = next_orientation
	active_cells = rotated.duplicate()
	active_position = candidate_position
	return true


func _rotation_position(position: Vector3i, old_size: Vector3i, new_size: Vector3i) -> Vector3i:
	var result := position
	for axis in range(3):
		var old_length := old_size[axis]
		var new_length := new_size[axis]
		if old_length == new_length:
			continue
		if axis != 1 or new_length < old_length:
			result[axis] += int(float(old_length - new_length) / 2.0)
		else:
			result[axis] += old_length - new_length
	result.x = clampi(result.x, 0, board_width - new_size.x)
	result.y = clampi(result.y, 0, board_height - new_size.y)
	result.z = clampi(result.z, 0, board_depth - new_size.z)
	return result


func _step_down() -> void:
	if _try_move(Vector3i(0, -1, 0)):
		return
	_lock_active_piece()


func _hard_drop() -> void:
	while _try_move(Vector3i(0, -1, 0)):
		pass
	_lock_active_piece()


func _lock_active_piece() -> void:
	var color_index := active_piece_index
	if not board.lock(_world_cells(active_cells, active_position), color_index):
		_begin_game_over()
		return
	locked_pieces += 1
	score += bonus
	var released_layers: int = board.clear_full_layers()
	cleared_layers += released_layers
	score += score_for_layers(released_layers)
	fall_elapsed = 0.0
	_spawn_piece()


static func score_for_layers(layer_count: int) -> int:
	return maxi(0, layer_count) * LAYER_SCORE


static func interval_for_level(speed_level: int) -> float:
	return LEVEL_INTERVALS[clampi(speed_level, 1, LEVEL_INTERVALS.size()) - 1]


static func level_duration_for_level(speed_level: int) -> float:
	var index := clampi(speed_level, 1, LEVEL_DURATION_MULTIPLIERS.size()) - 1
	return float(LEVEL_DURATION_MULTIPLIERS[index]) * LEVEL_DURATION_UNIT


static func level_threshold_for_start(speed_level: int) -> float:
	var threshold := 0.0
	for current_level in range(1, clampi(speed_level, 1, LEVEL_INTERVALS.size()) + 1):
		threshold += level_duration_for_level(current_level)
	return threshold


static func bonus_for_elapsed(elapsed_seconds: float) -> int:
	var bucket := maxi(0, floori(elapsed_seconds * 2.0))
	if bucket < BONUS_TABLE.size():
		return BONUS_TABLE[bucket]
	if bucket < 45:
		return 2
	return 0


func _increase_level(manual: bool = false) -> void:
	if level >= LEVEL_INTERVALS.size():
		return
	level += 1
	var next_duration := level_duration_for_level(level)
	if manual:
		next_level_at = level_elapsed + next_duration
	else:
		next_level_at += next_duration


static func starting_cells_per_layer(width: int, depth: int) -> int:
	var area := width * depth
	return mini(area - 1, maxi(1, roundi(float(area) * 0.4)))


func _max_start_layers() -> int:
	return mini(9, board_height - 3)


func _fill_starting_layers() -> void:
	var count := starting_cells_per_layer(board_width, board_depth)
	for y in range(start_layers):
		var positions: Array[Vector3i] = []
		for x in range(board_width):
			for z in range(board_depth):
				positions.append(Vector3i(x, y, z))
		for index in range(positions.size() - 1, 0, -1):
			var swap_index := rng.randi_range(0, index)
			var saved := positions[index]
			positions[index] = positions[swap_index]
			positions[swap_index] = saved
		for index in range(count):
			var color_index: int = enabled_piece_indices[rng.randi_range(0, enabled_piece_indices.size() - 1)]
			board.cells[positions[index]] = color_index


func _begin_game_over() -> void:
	game_over = true
	screen_mode = ScreenMode.NAME_ENTRY
	entered_name = ""
	queue_redraw()


func _world_cells(local_cells: Array, origin: Vector3i) -> Array:
	var result: Array = []
	for local_value in local_cells:
		var local_cell: Vector3i = local_value
		result.append(local_cell + origin)
	return result


func _load_high_scores() -> void:
	high_scores = []
	if not FileAccess.file_exists(HIGH_SCORES_PATH):
		return
	var file := FileAccess.open(HIGH_SCORES_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Array:
		for entry in parsed:
			if entry is Dictionary and entry.has("name") and entry.has("score"):
				high_scores.append({"name": str(entry["name"]), "score": int(entry["score"])})
	high_scores = rank_scores(high_scores)


func _record_score(player_name: String) -> void:
	last_score_entry = {"name": player_name, "score": score}
	high_scores.append(last_score_entry)
	high_scores = rank_scores(high_scores)
	var file := FileAccess.open(HIGH_SCORES_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(high_scores, "\t"))


static func rank_scores(entries: Array) -> Array:
	var ranked := entries.duplicate(true)
	ranked.sort_custom(_score_before)
	if ranked.size() > LEADERBOARD_LIMIT:
		ranked.resize(LEADERBOARD_LIMIT)
	return ranked


static func _score_before(first: Dictionary, second: Dictionary) -> bool:
	var first_score := int(first.get("score", 0))
	var second_score := int(second.get("score", 0))
	if first_score != second_score:
		return first_score > second_score
	return str(first.get("name", "")) < str(second.get("name", ""))


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(1280, 720)), Color("0c111a"))
	if screen_mode == ScreenMode.SETUP:
		_draw_setup()
		return
	if screen_mode == ScreenMode.LEADERBOARD:
		_draw_leaderboard()
		return
	_draw_hud()
	_draw_wall_shadows()
	_draw_board_grid()
	_draw_board_outline()
	_draw_all_cubes()
	if paused or screen_mode == ScreenMode.NAME_ENTRY:
		_draw_overlay()


func _draw_setup() -> void:
	var settings_panel := Rect2(30, 24, 540, 672)
	var settings_border := Color("94a3b8") if setup_focus_settings else Color("526171")
	draw_rect(settings_panel, Color(0.02, 0.04, 0.08, 0.94), true)
	draw_rect(settings_panel, settings_border, false, 2.0)
	_draw_centered("GAME SETTINGS", settings_panel, 70, 24, Color("e7edf5"))
	var labels := ["GLASS WIDTH", "GLASS DEPTH", "GLASS HEIGHT", "START LEVEL", "START LAYERS"]
	var values := [board_width, board_depth, board_height, start_level, start_layers]
	for row in range(labels.size()):
		var item := _setting_row_rect(row)
		var baseline := item.position.y + 28.0
		if setup_focus_settings and setup_row == row:
			draw_rect(item, Color(0.13, 0.20, 0.29, 0.9), true)
		draw_string(ui_font, Vector2(item.position.x + 14, baseline), labels[row], 0, -1, 17, Color("9aa9b8"))
		draw_string(
			ui_font,
			Vector2(item.end.x - 150, baseline),
			"<  %d  >" % values[row],
			HORIZONTAL_ALIGNMENT_CENTER,
			140,
			17,
			Color("e7edf5")
		)
	var figure_color := Color("e7edf5") if setup_focus_settings and setup_row == 5 else Color("9aa9b8")
	draw_string(ui_font, Vector2(72, 354), "AVAILABLE PIECES", 0, -1, 17, figure_color)
	for index in range(PieceCatalog.PIECES.size()):
		var item := _piece_item_rect(index)
		if setup_focus_settings and setup_row == 5 and setup_piece_cursor == index:
			draw_rect(item, Color(0.13, 0.20, 0.29, 0.9), true)
			draw_rect(item, Color("94a3b8"), false, 1.0)
		var marker := "[X]" if enabled_piece_indices.has(index) else "[ ]"
		var piece_name := str(PieceCatalog.get_piece(index)["name"])
		var color := _piece_color(index) if enabled_piece_indices.has(index) else Color("596675")
		draw_string(ui_font, item.position + Vector2(8, 23), "%s %s" % [marker, piece_name], 0, -1, 15, color)
	_draw_centered("Arrows: change     Space: toggle piece", settings_panel, 575, 15, Color("9aa9b8"))
	_draw_centered("Enter / Esc: back to menu", settings_panel, 605, 15, Color("9aa9b8"))
	_draw_centered("Starting layers are filled to 40%", settings_panel, 650, 14, Color("738293"))
	var menu_area := Rect2(650, 85, 540, 540)
	_draw_centered("FRAC", menu_area, 164, 50, Color("e7edf5"))
	_draw_centered("3D FALLING BLOCKS", menu_area, 199, 17, Color("738293"))
	for index in range(MAIN_MENU_ITEMS.size()):
		var item := _main_menu_item_rect(index)
		if main_menu_index == index:
			var fill := Color(0.14, 0.27, 0.40, 0.96) if not setup_focus_settings else Color(0.08, 0.14, 0.21)
			draw_rect(item, fill, true)
			draw_rect(item, Color("94a3b8"), false, 2.0)
		_draw_centered(MAIN_MENU_ITEMS[index], item, item.position.y + 41, 25, Color("e7edf5"))
	_draw_centered("Up / Down: select     Enter: confirm", menu_area, 544, 16, Color("9aa9b8"))
	_draw_centered("Tab or Left: settings     Mouse supported", menu_area, 576, 16, Color("9aa9b8"))


func _setting_row_rect(row: int) -> Rect2:
	return Rect2(58, 91 + row * 46, 484, 38)


func _piece_item_rect(index: int) -> Rect2:
	var column := index % 3
	var row := floori(float(index) / 3.0)
	return Rect2(62 + column * 162, 375 + row * 45, 148, 34)


func _main_menu_item_rect(index: int) -> Rect2:
	return Rect2(730, 245 + index * 82, 380, 62)


func _draw_leaderboard() -> void:
	var panel := Rect2(340, 55, 600, 610)
	draw_rect(panel, Color(0.02, 0.04, 0.08, 0.94), true)
	draw_rect(panel, Color("94a3b8"), false, 2.0)
	_draw_centered("HIGH SCORES", panel, 111, 34, Color("e7edf5"))
	draw_string(ui_font, Vector2(410, 151), "NAME", 0, -1, 17, Color("9aa9b8"))
	draw_string(ui_font, Vector2(732, 151), "SCORE", 0, -1, 17, Color("9aa9b8"))
	if high_scores.is_empty():
		_draw_centered("No scores yet", panel, 220, 20, Color("738293"))
	for index in range(high_scores.size()):
		var entry: Dictionary = high_scores[index]
		var baseline := 190.0 + index * 38.0
		draw_string(ui_font, Vector2(395, baseline), "%2d." % (index + 1), 0, -1, 18, Color("738293"))
		draw_string(ui_font, Vector2(440, baseline), str(entry["name"]), 0, -1, 18, Color("e7edf5"))
		draw_string(
			ui_font,
			Vector2(700, baseline),
			str(entry["score"]),
			HORIZONTAL_ALIGNMENT_RIGHT,
			150,
			18,
			Color("e7edf5")
		)
	if not last_score_entry.is_empty() and not high_scores.has(last_score_entry):
		var result := "%s — %d" % [last_score_entry["name"], last_score_entry["score"]]
		_draw_centered("YOUR SCORE: " + result, panel, 600, 17, Color("dfb85b"))
	_draw_centered("Enter / Space / Esc: main menu", panel, 638, 16, Color("9aa9b8"))


func _draw_hud() -> void:
	draw_string(ui_font, Vector2(32, 43), "FRAC", 0, -1, 24, Color("e7edf5"))
	draw_string(ui_font, Vector2(32, 75), "LEVEL  %d" % level, 0, -1, 17, Color("9aa9b8"))
	draw_string(ui_font, Vector2(32, 101), "SCORE  %d" % score, 0, -1, 17, Color("9aa9b8"))
	draw_string(ui_font, Vector2(32, 127), "BONUS  %d" % bonus, 0, -1, 17, Color("9aa9b8"))
	var controls := "Arrows / QWE AD ZXC / Num: move     S / Num 5: rotate"
	draw_string(ui_font, Vector2(32, 674), controls, 0, -1, 16, Color("9aa9b8"))
	var secondary := "Enter: increase level     Space / Ins / Del: drop     P / Esc: pause"
	draw_string(ui_font, Vector2(32, 700), secondary, 0, -1, 16, Color("9aa9b8"))


func _draw_board_grid() -> void:
	var grid_color := Color(0.34, 0.40, 0.46, 0.50)
	var strong_color := Color(0.58, 0.65, 0.72, 0.78)
	for x in range(board_width + 1):
		draw_line(_project(Vector3(x, 0, 0)), _project(Vector3(x, 0, board_depth)), grid_color, 1.0)
		draw_line(
			_project(Vector3(x, 0, 0)),
			_project(Vector3(x, board_height, 0)),
			grid_color,
			1.0
		)
	for z in range(board_depth + 1):
		draw_line(_project(Vector3(0, 0, z)), _project(Vector3(board_width, 0, z)), grid_color, 1.0)
		draw_line(_project(Vector3(0, 0, z)), _project(Vector3(0, board_height, z)), grid_color, 1.0)
	for y in range(board_height + 1):
		draw_line(
			_project(Vector3(0, y, 0)),
			_project(Vector3(board_width, y, 0)),
			grid_color,
			1.0
		)
		draw_line(_project(Vector3(0, y, 0)), _project(Vector3(0, y, board_depth)), grid_color, 1.0)
	draw_line(_project(Vector3.ZERO), _project(Vector3(0, board_height, 0)), strong_color, 2.0)


func _draw_wall_shadows() -> void:
	if game_over or active_cells.is_empty():
		return
	var world_cells := _world_cells(active_cells, active_position)
	var shadows := wall_shadow_cells(world_cells)
	var shadow_color := Color(0.56, 0.52, 0.78, 0.72)
	for coordinate_value in shadows["wall_z"]:
		var coordinate: Vector2i = coordinate_value
		var wall_z := PackedVector2Array([
			_project(Vector3(coordinate.x, coordinate.y, 0)),
			_project(Vector3(coordinate.x + 1, coordinate.y, 0)),
			_project(Vector3(coordinate.x + 1, coordinate.y + 1, 0)),
			_project(Vector3(coordinate.x, coordinate.y + 1, 0)),
		])
		draw_colored_polygon(wall_z, shadow_color)
	for coordinate_value in shadows["wall_x"]:
		var coordinate: Vector2i = coordinate_value
		var wall_x := PackedVector2Array([
			_project(Vector3(0, coordinate.y, coordinate.x)),
			_project(Vector3(0, coordinate.y, coordinate.x + 1)),
			_project(Vector3(0, coordinate.y + 1, coordinate.x + 1)),
			_project(Vector3(0, coordinate.y + 1, coordinate.x)),
		])
		draw_colored_polygon(wall_x, shadow_color)


static func wall_shadow_cells(world_cells: Array) -> Dictionary:
	var wall_x := {}
	var wall_z := {}
	for cell_value in world_cells:
		var cell: Vector3i = cell_value
		wall_x[Vector2i(cell.z, cell.y)] = true
		wall_z[Vector2i(cell.x, cell.y)] = true
	return {"wall_x": wall_x, "wall_z": wall_z}


func _draw_board_outline() -> void:
	var outline := Color("94a3b8")
	var bottom := [
		_project(Vector3(0, 0, 0)),
		_project(Vector3(board_width, 0, 0)),
		_project(Vector3(board_width, 0, board_depth)),
		_project(Vector3(0, 0, board_depth)),
	]
	for index in range(4):
		draw_line(bottom[index], bottom[(index + 1) % 4], outline, 2.0)
	for corner in [
		Vector3(0, 0, 0),
		Vector3(board_width, 0, 0),
		Vector3(0, 0, board_depth),
	]:
		draw_line(_project(corner), _project(corner + Vector3(0, board_height, 0)), outline, 2.0)


func _draw_all_cubes() -> void:
	var items: Array = []
	var occupied: Dictionary = {}
	for position_value in board.cells:
		var position: Vector3i = position_value
		items.append({"position": position, "color": _piece_color(board.cells[position]), "alpha": 1.0})
		occupied[position] = true
	if not game_over:
		for position_value in _world_cells(active_cells, active_position):
			items.append({"position": position_value, "color": _piece_color(active_piece_index), "alpha": 1.0})
			occupied[position_value] = true
	items.sort_custom(_cube_before)
	for item in items:
		var position: Vector3i = item["position"]
		var show_top := not occupied.has(position + Vector3i(0, 1, 0))
		var show_right := not occupied.has(position + Vector3i(1, 0, 0))
		var show_left := not occupied.has(position + Vector3i(0, 0, 1))
		_draw_cube(position, item["color"], item["alpha"], show_top, show_right, show_left)


func _cube_before(first: Dictionary, second: Dictionary) -> bool:
	var first_position: Vector3i = first["position"]
	var second_position: Vector3i = second["position"]
	var first_depth := first_position.x + first_position.z
	var second_depth := second_position.x + second_position.z
	if first_depth != second_depth:
		return first_depth < second_depth
	if first_position.y != second_position.y:
		return first_position.y < second_position.y
	return first_position.x < second_position.x


func _draw_cube(
	cell: Vector3i,
	base_color: Color,
	alpha: float,
	show_top: bool,
	show_right: bool,
	show_left: bool
) -> void:
	var x := float(cell.x)
	var y := float(cell.y)
	var z := float(cell.z)
	var top := PackedVector2Array([
		_project(Vector3(x, y + 1, z)),
		_project(Vector3(x + 1, y + 1, z)),
		_project(Vector3(x + 1, y + 1, z + 1)),
		_project(Vector3(x, y + 1, z + 1)),
	])
	var right := PackedVector2Array([
		_project(Vector3(x + 1, y, z)),
		_project(Vector3(x + 1, y, z + 1)),
		_project(Vector3(x + 1, y + 1, z + 1)),
		_project(Vector3(x + 1, y + 1, z)),
	])
	var left := PackedVector2Array([
		_project(Vector3(x, y, z + 1)),
		_project(Vector3(x + 1, y, z + 1)),
		_project(Vector3(x + 1, y + 1, z + 1)),
		_project(Vector3(x, y + 1, z + 1)),
	])
	var edge := Color(0.86, 0.91, 0.95, 0.72 * alpha)
	if show_left:
		draw_colored_polygon(left, Color(base_color.r * 0.34, base_color.g * 0.34, base_color.b * 0.34, alpha))
		_draw_face_shadow(left, alpha, 0)
		draw_polyline(_closed_polygon(left), edge, 1.2)
	if show_right:
		draw_colored_polygon(right, Color(base_color.r * 0.48, base_color.g * 0.48, base_color.b * 0.48, alpha))
		_draw_face_shadow(right, alpha, 1)
		draw_polyline(_closed_polygon(right), edge, 1.2)
	if show_top:
		draw_colored_polygon(top, Color(base_color.r, base_color.g, base_color.b, alpha))
		draw_polyline(_closed_polygon(top), edge, 1.2)


func _draw_face_shadow(face: PackedVector2Array, alpha: float, phase: int) -> void:
	var shadow_color := Color(0.01, 0.02, 0.03, 0.58 * alpha)
	var dot_radius := maxf(0.45, _board_scale() * 0.65)
	for row in range(7):
		for column in range(7):
			if (row + column + phase) % 2 != 0:
				continue
			var horizontal := (float(column) + 0.5) / 7.0
			var vertical := (float(row) + 0.5) / 7.0
			var bottom := face[0].lerp(face[1], horizontal)
			var top := face[3].lerp(face[2], horizontal)
			draw_circle(bottom.lerp(top, vertical), dot_radius, shadow_color)


func _closed_polygon(points: PackedVector2Array) -> PackedVector2Array:
	var result := points.duplicate()
	result.append(points[0])
	return result


func _project(point: Vector3) -> Vector2:
	var scale := _board_scale()
	return _board_origin() + Vector2(
		(point.x - point.z) * ISO_HALF_WIDTH * scale,
		((point.x + point.z) * ISO_HALF_HEIGHT - point.y * CUBE_HEIGHT) * scale
	)


func _board_origin() -> Vector2:
	var scale := _board_scale()
	var horizontal_offset := float(board_width - board_depth) * ISO_HALF_WIDTH * scale * 0.5
	var vertical_span := float(board_width + board_depth) * ISO_HALF_HEIGHT - board_height * CUBE_HEIGHT
	vertical_span *= scale
	return Vector2(640.0 - horizontal_offset, 360.0 - vertical_span * 0.5)


func _board_scale() -> float:
	var horizontal_extent := float(board_width + board_depth) * ISO_HALF_WIDTH
	var vertical_extent := board_height * CUBE_HEIGHT + float(board_width + board_depth) * ISO_HALF_HEIGHT
	return minf(1.0, minf(920.0 / horizontal_extent, 570.0 / vertical_extent))


func _piece_color(index: int) -> Color:
	return PieceCatalog.get_piece(index)["color"]


func _draw_overlay() -> void:
	var panel := Rect2(356, 285, 568, 150)
	if screen_mode == ScreenMode.NAME_ENTRY:
		panel = Rect2(320, 235, 640, 250)
	draw_rect(panel, Color(0.02, 0.04, 0.08, 0.90), true)
	draw_rect(panel, Color("94a3b8"), false, 2.0)
	if screen_mode == ScreenMode.NAME_ENTRY:
		_draw_centered("GAME OVER", panel, 298, 36, Color("e7edf5"))
		_draw_centered("SCORE  %d" % score, panel, 341, 21, Color("dfb85b"))
		var shown_name := entered_name + "_"
		_draw_centered("NAME:  " + shown_name, panel, 394, 23, Color("e7edf5"))
		_draw_centered("Type a name and press Enter", panel, 445, 17, Color("9aa9b8"))
	else:
		_draw_centered("PAUSED", panel, 348, 38, Color("e7edf5"))
		_draw_centered("Press P or Esc to continue", panel, 396, 20, Color("9aa9b8"))


func _draw_centered(text: String, area: Rect2, baseline: float, font_size: int, color: Color) -> void:
	draw_string(
		ui_font,
		Vector2(area.position.x, baseline),
		text,
		HORIZONTAL_ALIGNMENT_CENTER,
		area.size.x,
		font_size,
		color
	)
