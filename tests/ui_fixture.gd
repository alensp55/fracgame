extends "res://scripts/game.gd"


func _ready() -> void:
	super._ready()
	set_process(false)
	var mode := "setup"
	var arguments := OS.get_cmdline_user_args()
	if not arguments.is_empty():
		mode = arguments[0]
	match mode:
		"pause":
			new_game()
			paused = true
		"name":
			new_game()
			score = 1234
			_begin_game_over()
			entered_name = "PLAYER"
		"scores":
			high_scores = [
				{"name": "KRIS", "score": 5680},
				{"name": "T", "score": 4840},
				{"name": "P", "score": 4120},
			]
			screen_mode = ScreenMode.LEADERBOARD
		"max":
			board_width = MAX_BOARD_SIDE
			board_depth = MAX_BOARD_SIDE
			board_height = MAX_BOARD_HEIGHT
			start_layers = 9
			new_game()
	queue_redraw()
