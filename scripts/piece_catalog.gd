extends RefCounted
class_name FracPieceCatalog

const PIECES := [
	{"name": "1x1x1", "color": Color("506ee8"), "size": Vector3i(1, 1, 1), "frequency": 30},
	{"name": "1x1x2", "color": Color("35b7c4"), "size": Vector3i(2, 1, 1), "frequency": 60},
	{"name": "1x1x3", "color": Color("33c878"), "size": Vector3i(3, 1, 1), "frequency": 60},
	{"name": "1x1x4", "color": Color("f0783f"), "size": Vector3i(4, 1, 1), "frequency": 6},
	{"name": "2x2x1", "color": Color("a75bc8"), "size": Vector3i(1, 2, 2), "frequency": 60},
	{"name": "2x2x2", "color": Color("c7c2a0"), "size": Vector3i(2, 2, 2), "frequency": 40},
	{"name": "2x2x3", "color": Color("df4c78"), "size": Vector3i(3, 2, 2), "frequency": 6},
	{"name": "3x3x1", "color": Color("42a48f"), "size": Vector3i(1, 3, 3), "frequency": 15},
	{"name": "3x3x3", "color": Color("8f96a3"), "size": Vector3i(3, 3, 3), "frequency": 1},
]


static func get_piece(index: int) -> Dictionary:
	return PIECES[posmod(index, PIECES.size())]


static func pick_piece(rng: RandomNumberGenerator, enabled_indices: Array = []) -> int:
	var candidates: Array = enabled_indices
	if candidates.is_empty():
		candidates = range(PIECES.size())
	var total_frequency := 0
	for index_value in candidates:
		total_frequency += int(PIECES[int(index_value)]["frequency"])
	var choice := rng.randi_range(0, total_frequency - 1)
	for index_value in candidates:
		var index := int(index_value)
		choice -= int(PIECES[index]["frequency"])
		if choice < 0:
			return index
	return int(candidates[-1])


static func get_orientations(initial_size: Vector3i) -> Array:
	var result: Array = []
	var size := initial_size
	for unused_turn in range(3):
		var cells := cells_for_size(size)
		if not _contains_same_cells(result, cells):
			result.append(cells)
		size = Vector3i(size.z, size.x, size.y)
	return result


static func cells_for_size(size: Vector3i) -> Array:
	var cells: Array = []
	for x in range(size.x):
		for y in range(size.y):
			for z in range(size.z):
				cells.append(Vector3i(x, y, z))
	return cells


static func size_for_cells(cells: Array) -> Vector3i:
	var maximum := Vector3i.ZERO
	for cell_value in cells:
		var cell: Vector3i = cell_value
		maximum.x = maxi(maximum.x, cell.x)
		maximum.y = maxi(maximum.y, cell.y)
		maximum.z = maxi(maximum.z, cell.z)
	return maximum + Vector3i.ONE


static func _contains_same_cells(orientations: Array, candidate: Array) -> bool:
	for orientation in orientations:
		if orientation.size() != candidate.size():
			continue
		var matches := true
		for cell in candidate:
			if not orientation.has(cell):
				matches = false
				break
		if matches:
			return true
	return false
