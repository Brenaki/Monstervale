extends RefCounted
## Junta a cena da fase, editável no Godot, com os dados de balanceamento em JSON.

const CELL_SIZE := 32


static func read(scene: Node, data: Dictionary) -> Dictionary:
	var level := data.duplicate()
	level["cell_size"] = CELL_SIZE
	level["route"] = _route_points(scene.get_node("Route"))
	level["buildable"] = _buildable_cells(scene.get_node("Ground"), scene.get_node("Decor"))
	return level


static func _route_points(path: Path2D) -> Array:
	var points := []
	for i in path.curve.point_count:
		points.append(path.position + path.curve.get_point_position(i))
	return points


static func _buildable_cells(ground: TileMapLayer, decor: TileMapLayer) -> Dictionary:
	var cells := {}
	for cell: Vector2i in ground.get_used_cells():
		var tile := ground.get_cell_tile_data(cell)
		if tile != null and tile.get_custom_data("buildable") and decor.get_cell_source_id(cell) == -1:
			cells[cell] = true
	return cells
