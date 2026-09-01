extends SceneTree

const BoardClass = preload("res://scripts/board.gd")
const PieceCatalog = preload("res://scripts/piece_catalog.gd")
const GameClass = preload("res://scripts/game.gd")

var failures := 0


func _init() -> void:
	_test_collision_bounds()
	_test_single_layer_clear()
	_test_multiple_layer_clear()
	_test_original_piece_catalog()
	_test_single_button_orientations()
	_test_far_corner_spawn()
	_test_arrow_directions()
	_test_numpad_directions()
	_test_original_letter_directions()
	_test_diagonal_slide()
	_test_scoring_rules()
	_test_piece_bonus()
	_test_original_timing_tables()
	_test_enter_increases_level()
	_test_game_configuration()
	_test_starting_fill()
	_test_leaderboard_ranking()
	_test_main_menu()
	if failures == 0:
		print("PASS: all fracgame tests passed")
	else:
		printerr("FAIL: %d fracgame test(s) failed" % failures)
	quit(failures)


func _test_collision_bounds() -> void:
	var board = BoardClass.new(5, 12, 5)
	_expect(board.can_place([Vector3i(0, 0, 0)]), "an empty in-bounds cell is available")
	_expect(not board.can_place([Vector3i(-1, 0, 0)]), "negative X is rejected")
	_expect(not board.can_place([Vector3i(0, -1, 0)]), "cells below the floor are rejected")
	board.cells[Vector3i(2, 3, 2)] = 0
	_expect(not board.can_place([Vector3i(2, 3, 2)]), "occupied cells are rejected")


func _test_single_layer_clear() -> void:
	var board = BoardClass.new(2, 4, 2)
	_fill_layer(board, 0, 1)
	board.cells[Vector3i(1, 2, 1)] = 2
	_expect(board.clear_full_layers() == 1, "one full layer is reported")
	_expect(board.cells.has(Vector3i(1, 1, 1)), "cells above a cleared layer fall by one")
	_expect(not board.cells.has(Vector3i(1, 2, 1)), "the previous upper position is empty")


func _test_multiple_layer_clear() -> void:
	var board = BoardClass.new(2, 5, 2)
	_fill_layer(board, 0, 1)
	_fill_layer(board, 2, 2)
	board.cells[Vector3i(0, 4, 0)] = 3
	_expect(board.clear_full_layers() == 2, "two full layers are reported")
	_expect(board.cells.has(Vector3i(0, 2, 0)), "cells fall once for every cleared layer below")


func _test_original_piece_catalog() -> void:
	var expected_sizes := [
		Vector3i(1, 1, 1),
		Vector3i(2, 1, 1),
		Vector3i(3, 1, 1),
		Vector3i(4, 1, 1),
		Vector3i(1, 2, 2),
		Vector3i(2, 2, 2),
		Vector3i(3, 2, 2),
		Vector3i(1, 3, 3),
		Vector3i(3, 3, 3),
	]
	_expect(PieceCatalog.PIECES.size() == expected_sizes.size(), "the original catalog has nine prisms")
	for index in range(expected_sizes.size()):
		var size: Vector3i = PieceCatalog.get_piece(index)["size"]
		_expect(size == expected_sizes[index], "piece %d has the original dimensions" % (index + 1))
		var cells := PieceCatalog.cells_for_size(size)
		_expect(cells.size() == size.x * size.y * size.z, "piece %d has a solid volume" % (index + 1))


func _test_single_button_orientations() -> void:
	var orientation_counts := [1, 3, 3, 3, 3, 1, 3, 3, 1]
	for index in range(PieceCatalog.PIECES.size()):
		var size: Vector3i = PieceCatalog.get_piece(index)["size"]
		var orientations := PieceCatalog.get_orientations(size)
		_expect(orientations.size() == orientation_counts[index], "piece %d has only original turns" % (index + 1))
		for orientation in orientations:
			_expect(orientation.size() == size.x * size.y * size.z, "turn preserves piece %d volume" % (index + 1))


func _test_numpad_directions() -> void:
	var expected := {
		KEY_KP_7: Vector3i(-1, 0, -1),
		KEY_KP_8: Vector3i(0, 0, -1),
		KEY_KP_9: Vector3i(1, 0, -1),
		KEY_KP_4: Vector3i(-1, 0, 0),
		KEY_KP_6: Vector3i(1, 0, 0),
		KEY_KP_1: Vector3i(-1, 0, 1),
		KEY_KP_2: Vector3i(0, 0, 1),
		KEY_KP_3: Vector3i(1, 0, 1),
	}
	for key in expected:
		_expect(GameClass.movement_for_key(key) == expected[key], "numeric keypad direction %s is mapped" % key)
	_expect(GameClass.movement_for_key(KEY_KP_8) == GameClass.movement_for_key(KEY_UP), "Num 8 matches Up")
	_expect(GameClass.movement_for_key(KEY_KP_2) == GameClass.movement_for_key(KEY_DOWN), "Num 2 matches Down")


func _test_arrow_directions() -> void:
	var expected := {
		KEY_UP: Vector3i(0, 0, -1),
		KEY_DOWN: Vector3i(0, 0, 1),
		KEY_LEFT: Vector3i(-1, 0, 0),
		KEY_RIGHT: Vector3i(1, 0, 0),
	}
	for key in expected:
		_expect(GameClass.movement_for_key(key) == expected[key], "isometric arrow direction %s is mapped" % key)


func _test_original_letter_directions() -> void:
	var keys := [KEY_Q, KEY_W, KEY_E, KEY_A, KEY_D, KEY_Z, KEY_X, KEY_C]
	var numpad := [KEY_KP_7, KEY_KP_8, KEY_KP_9, KEY_KP_4, KEY_KP_6, KEY_KP_1, KEY_KP_2, KEY_KP_3]
	for index in range(keys.size()):
		var message := "original letter %s matches its numeric keypad direction" % keys[index]
		_expect(GameClass.movement_for_key(keys[index]) == GameClass.movement_for_key(numpad[index]), message)


func _test_far_corner_spawn() -> void:
	var game = GameClass.new()
	var vertical_piece := PieceCatalog.cells_for_size(Vector3i(1, 4, 1))
	var spawn_position: Vector3i = game._far_spawn_position(vertical_piece)
	_expect(spawn_position == Vector3i(0, 8, 0), "a tall piece spawns fully inside the far corner")
	game.free()


func _test_diagonal_slide() -> void:
	var game = GameClass.new()
	game.board = BoardClass.new(5, 12, 5)
	game.active_cells = [Vector3i.ZERO]
	game.active_position = Vector3i(1, 1, 1)
	game.board.cells[Vector3i(2, 1, 0)] = 1
	_expect(game._try_horizontal_move(Vector3i(1, 0, -1)), "blocked diagonal slides along its first axis")
	_expect(game.active_position == Vector3i(2, 1, 1), "diagonal sliding uses the original axis order")
	game.free()


func _test_scoring_rules() -> void:
	_expect(GameClass.score_for_layers(0) == 0, "no cleared layer gives no layer score")
	_expect(GameClass.score_for_layers(1) == 100, "one cleared layer gives 100 points")
	_expect(GameClass.score_for_layers(2) == 200, "two cleared layers give 200 points")
	_expect(GameClass.score_for_layers(3) == 300, "three cleared layers give 300 points")
	_expect(GameClass.score_for_layers(4) == 400, "four cleared layers give 400 points")


func _test_piece_bonus() -> void:
	var game = GameClass.new()
	game.board = BoardClass.new(5, 12, 5)
	game.rng.seed = 1
	game.next_piece_index = 0
	game.active_piece_index = 0
	game.active_cells = [Vector3i.ZERO]
	game.active_position = Vector3i.ZERO
	game.bonus = 17
	game._lock_active_piece()
	_expect(game.score == 17, "locking a piece awards its remaining bonus")
	_expect(game.bonus == GameClass.START_BONUS, "the next piece receives a fresh bonus")
	game.free()


func _test_original_timing_tables() -> void:
	var expected_intervals := [0.70, 0.60, 0.50, 0.40, 0.30, 0.25, 0.22, 0.18, 0.05]
	for index in range(expected_intervals.size()):
		var actual := GameClass.interval_for_level(index + 1)
		_expect(is_equal_approx(actual, expected_intervals[index]), "level %d uses the DOS interval" % (index + 1))
	_expect(GameClass.level_duration_for_level(1) == 120.0, "levels use the DOS two-minute duration")
	_expect(GameClass.level_threshold_for_start(3) == 360.0, "start level preserves the DOS cumulative timer")
	_expect(GameClass.bonus_for_elapsed(0.0) == 20, "a new piece starts with the DOS bonus")
	_expect(GameClass.bonus_for_elapsed(0.49) == 20, "the initial bonus lasts half a second")
	_expect(GameClass.bonus_for_elapsed(0.50) == 17, "the bonus follows the first DOS table step")
	_expect(GameClass.bonus_for_elapsed(12.49) == 4, "the last explicit DOS bonus bucket is four")
	_expect(GameClass.bonus_for_elapsed(12.50) == 2, "the DOS bonus becomes two after 12.5 seconds")
	_expect(GameClass.bonus_for_elapsed(22.49) == 2, "the DOS bonus remains two before 22.5 seconds")
	_expect(GameClass.bonus_for_elapsed(22.50) == 0, "the DOS bonus becomes zero after 22.5 seconds")


func _test_enter_increases_level() -> void:
	var game = GameClass.new()
	game.screen_mode = GameClass.ScreenMode.PLAYING
	game.level = 1
	game.level_elapsed = 15.0
	game.next_level_at = 120.0
	var event := InputEventKey.new()
	event.pressed = true
	event.physical_keycode = KEY_ENTER
	game._unhandled_key_input(event)
	_expect(game.level == 2, "Enter advances the speed level instead of soft-dropping")
	_expect(game.next_level_at == 135.0, "Enter restarts the two-minute level timer")
	game.free()


func _test_game_configuration() -> void:
	_expect(GameClass.starting_cells_per_layer(5, 5) == 10, "original start layers contain ten cubes")
	_expect(GameClass.starting_cells_per_layer(3, 3) < 9, "a configured start layer is never completely full")
	for speed_level in range(1, GameClass.LEVEL_INTERVALS.size()):
		var current := GameClass.interval_for_level(speed_level)
		var faster := GameClass.interval_for_level(speed_level + 1)
		_expect(faster < current, "speed level %d is faster than the previous level" % (speed_level + 1))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for unused_pick in range(20):
		_expect(PieceCatalog.pick_piece(rng, [4]) == 4, "disabled pieces are excluded from selection")
	var game = GameClass.new()
	game.board_width = GameClass.MAX_BOARD_SIDE
	game.board_depth = GameClass.MAX_BOARD_SIDE
	game.board_height = GameClass.MAX_BOARD_HEIGHT
	_expect(game._board_scale() < 1.0, "the largest configured glass is scaled to fit the window")
	game.free()


func _test_starting_fill() -> void:
	var game = GameClass.new()
	game.rng.seed = 11
	game.start_layers = 2
	game.new_game()
	for layer in range(2):
		var cells_in_layer := 0
		for position_value in game.board.cells:
			var position: Vector3i = position_value
			if position.y == layer:
				cells_in_layer += 1
		_expect(cells_in_layer == 10, "configured original-size layer %d starts with ten cubes" % layer)
	game.free()


func _test_leaderboard_ranking() -> void:
	var ranked := GameClass.rank_scores([
		{"name": "LOW", "score": 10},
		{"name": "HIGH", "score": 90},
		{"name": "MID", "score": 50},
	])
	_expect(ranked[0]["name"] == "HIGH", "leaderboard places the highest score first")
	_expect(ranked[2]["name"] == "LOW", "leaderboard places the lowest score last")


func _test_main_menu() -> void:
	var game = GameClass.new()
	var event := InputEventKey.new()
	game._handle_setup_key(event, KEY_DOWN)
	_expect(game.main_menu_index == 1, "main menu moves from Start to Records")
	game._handle_setup_key(event, KEY_ENTER)
	_expect(game.screen_mode == GameClass.ScreenMode.LEADERBOARD, "Records opens the leaderboard")
	game._return_to_main_menu()
	game._handle_setup_key(event, KEY_TAB)
	_expect(game.setup_focus_settings, "Tab moves focus from the main menu to settings")
	game._return_to_main_menu()
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = true
	mouse.position = game._main_menu_item_rect(1).get_center()
	game._unhandled_input(mouse)
	_expect(game.screen_mode == GameClass.ScreenMode.LEADERBOARD, "clicking Records opens the leaderboard")
	game.free()


func _fill_layer(board, layer: int, color_index: int) -> void:
	for x in range(board.width):
		for z in range(board.depth):
			board.cells[Vector3i(x, layer, z)] = color_index


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: " + message)
	else:
		failures += 1
		printerr("FAIL: " + message)
