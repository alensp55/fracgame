extends RefCounted
class_name FracBoard

var width: int
var height: int
var depth: int
var cells: Dictionary = {}


func _init(board_width: int, board_height: int, board_depth: int) -> void:
	width = board_width
	height = board_height
	depth = board_depth


func reset() -> void:
	cells.clear()


func can_place(positions: Array) -> bool:
	for position_value in positions:
		var position: Vector3i = position_value
		if position.x < 0 or position.x >= width:
			return false
		if position.z < 0 or position.z >= depth:
			return false
		if position.y < 0:
			return false
		if position.y < height and cells.has(position):
			return false
	return true


func lock(positions: Array, color_index: int) -> bool:
	for position_value in positions:
		var position: Vector3i = position_value
		if position.y >= height:
			return false
	for position_value in positions:
		var position: Vector3i = position_value
		cells[position] = color_index
	return true


func clear_full_layers() -> int:
	var full_layers: Array[int] = []
	for layer in range(height):
		if _is_layer_full(layer):
			full_layers.append(layer)
	if full_layers.is_empty():
		return 0

	var collapsed: Dictionary = {}
	for position_value in cells:
		var position: Vector3i = position_value
		if full_layers.has(position.y):
			continue
		var shift := 0
		for cleared_layer in full_layers:
			if cleared_layer < position.y:
				shift += 1
		var collapsed_position := Vector3i(position.x, position.y - shift, position.z)
		collapsed[collapsed_position] = cells[position]
	cells = collapsed
	return full_layers.size()


func _is_layer_full(layer: int) -> bool:
	for x in range(width):
		for z in range(depth):
			if not cells.has(Vector3i(x, layer, z)):
				return false
	return true

