extends "res://scripts/game.gd"


func _ready() -> void:
	super._ready()
	set_process(false)
	screen_mode = ScreenMode.PLAYING
	board.reset()
	_add_column(Vector3i(4, 0, 4), 5, 0)
	_add_column(Vector3i(2, 0, 3), 3, 5)
	_add_column(Vector3i(1, 0, 2), 2, 3)
	_add_column(Vector3i(3, 0, 2), 3, 2)
	board.cells[Vector3i(0, 0, 3)] = 3
	board.cells[Vector3i(1, 0, 3)] = 3
	board.cells[Vector3i(1, 1, 3)] = 3
	board.cells[Vector3i(2, 0, 4)] = 2
	board.cells[Vector3i(3, 0, 4)] = 0
	active_piece_index = 2
	var active_size: Vector3i = PieceCatalog.get_piece(active_piece_index)["size"]
	active_orientations = PieceCatalog.get_orientations(active_size)
	active_orientation_index = 0
	active_cells = active_orientations[active_orientation_index].duplicate()
	active_position = Vector3i(1, board_height - 1, 2)
	queue_redraw()


func _add_column(origin: Vector3i, column_height: int, color_index: int) -> void:
	for y in range(column_height):
		board.cells[origin + Vector3i(0, y, 0)] = color_index
