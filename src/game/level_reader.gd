extends RefCounted
## Junta a cena da fase, editável no Godot, com os dados de balanceamento em JSON.

const CELL_SIZE := 32


static func read(scene: Node, data: Dictionary) -> Dictionary:
	var level := data.duplicate()
	level["cell_size"] = CELL_SIZE
	level["routes"] = _all_routes(scene)
	level["route"] = level.routes[0]
	level["buildable"] = _buildable_cells(scene.get_node("Ground"), scene.get_node("Decor"))
	return level


## Route é a primeira entrada; Route2 em diante são as outras, quando a fase tem mais de uma.
static func _all_routes(scene: Node) -> Array:
	var routes := [_route_points(scene.get_node("Route"))]
	var index := 2
	while scene.has_node("Route%d" % index):
		routes.append(_route_points(scene.get_node("Route%d" % index)))
		index += 1
	return routes


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
