extends SceneTree
## Gera os SpriteFrames, os TileSets e a primeira versão das cenas das fases.
## Uso: godot --headless --path . -s tools/build_assets.gd
## Depois de gerada, a cena pode ser editada no Godot; rode com --scene só para recriá-la.

const AsepriteFrames = preload("res://src/core/aseprite_frames.gd")

const SPRITES_DIR := "res://assets/sprites/"
const LEVEL_PATH := "res://src/game/levels/%s.tscn"
const TILE := 32
const GRID := Vector2i(20, 11)
const ATLAS_SIZE := Vector2i(8, 3)
const BUSH := Vector2i(4, 0)
const LOCKED_GRASS := Vector2i(5, 0)
const BERRY_BUSH := Vector2i(6, 0)
const ROCK := Vector2i(7, 0)
const LAST_GRASS_COLUMN := 3
const VILLAGE_CELLS := Rect2i(15, 1, 5, 5)
const LEVELS := {
	"level_01": {
		"node": "Level01",
		"tiles": "res://assets/tiles/tiles.png",
		"tileset": "res://assets/tiles/tileset.tres",
		"path_runs": [
			[Vector2i(0, 7), Vector2i(8, 7)],
			[Vector2i(8, 3), Vector2i(8, 7)],
			[Vector2i(8, 3), Vector2i(17, 3)],
			[Vector2i(15, 4), Vector2i(17, 4)],
		],
		"route": [Vector2(-16, 240), Vector2(272, 240), Vector2(272, 112), Vector2(560, 112)],
		"decor": {
			Vector2i(1, 2): BUSH, Vector2i(4, 1): ROCK, Vector2i(2, 5): BERRY_BUSH, Vector2i(13, 1): BUSH,
			Vector2i(18, 7): BERRY_BUSH, Vector2i(15, 7): BUSH, Vector2i(1, 9): BUSH, Vector2i(5, 9): BERRY_BUSH,
			Vector2i(11, 8): ROCK, Vector2i(16, 9): BUSH, Vector2i(10, 1): BERRY_BUSH, Vector2i(18, 9): ROCK,
		},
	},
	"level_02": {
		"node": "Level02",
		"tiles": "res://assets/tiles/tiles_swamp.png",
		"tileset": "res://assets/tiles/tileset_swamp.tres",
		"path_runs": [
			[Vector2i(0, 2), Vector2i(4, 2)],
			[Vector2i(4, 2), Vector2i(4, 8)],
			[Vector2i(4, 8), Vector2i(12, 8)],
			[Vector2i(12, 3), Vector2i(12, 8)],
			[Vector2i(12, 3), Vector2i(17, 3)],
			[Vector2i(15, 4), Vector2i(17, 4)],
		],
		"route": [Vector2(-16, 80), Vector2(144, 80), Vector2(144, 272), Vector2(400, 272), Vector2(400, 112), Vector2(560, 112)],
		"decor": {
			Vector2i(1, 1): BUSH, Vector2i(2, 5): BERRY_BUSH, Vector2i(3, 1): ROCK, Vector2i(7, 2): BUSH,
			Vector2i(9, 1): BERRY_BUSH, Vector2i(13, 1): ROCK, Vector2i(2, 8): BUSH, Vector2i(1, 9): ROCK,
			Vector2i(8, 5): BUSH, Vector2i(10, 4): BERRY_BUSH, Vector2i(7, 6): ROCK, Vector2i(15, 7): BUSH,
			Vector2i(18, 7): BERRY_BUSH, Vector2i(14, 9): ROCK, Vector2i(17, 9): BUSH,
		},
	},
	"level_03": {
		"node": "Level03",
		"tiles": "res://assets/tiles/tiles_forest.png",
		"tileset": "res://assets/tiles/tileset_forest.tres",
		"path_runs": [
			[Vector2i(0, 2), Vector2i(7, 2)],
			[Vector2i(7, 2), Vector2i(7, 4)],
			[Vector2i(7, 4), Vector2i(13, 4)],
			[Vector2i(0, 8), Vector2i(10, 8)],
			[Vector2i(10, 6), Vector2i(10, 8)],
			[Vector2i(10, 6), Vector2i(13, 6)],
			[Vector2i(13, 3), Vector2i(13, 6)],
			[Vector2i(13, 3), Vector2i(17, 3)],
			[Vector2i(15, 4), Vector2i(17, 4)],
		],
		"route": [Vector2(-16, 80), Vector2(240, 80), Vector2(240, 144), Vector2(432, 144), Vector2(432, 112), Vector2(560, 112)],
		"route2": [Vector2(-16, 272), Vector2(336, 272), Vector2(336, 208), Vector2(432, 208), Vector2(432, 112), Vector2(560, 112)],
		"decor": {
			Vector2i(1, 1): BUSH, Vector2i(4, 1): BUSH, Vector2i(9, 1): ROCK, Vector2i(11, 2): BUSH,
			Vector2i(13, 1): BUSH, Vector2i(1, 4): BERRY_BUSH, Vector2i(3, 5): BUSH, Vector2i(9, 2): BUSH,
			Vector2i(5, 6): ROCK, Vector2i(2, 6): ROCK, Vector2i(8, 6): BUSH, Vector2i(12, 8): BERRY_BUSH,
			Vector2i(15, 7): BUSH, Vector2i(1, 9): BUSH, Vector2i(6, 9): ROCK, Vector2i(13, 9): BUSH,
			Vector2i(18, 8): BUSH, Vector2i(16, 9): ROCK, Vector2i(9, 9): BERRY_BUSH,
		},
	},
	"level_04": {
		"node": "Level04",
		"tiles": "res://assets/tiles/tiles_cemetery.png",
		"tileset": "res://assets/tiles/tileset_cemetery.tres",
		"path_runs": [
			[Vector2i(0, 7), Vector2i(5, 7)],
			[Vector2i(5, 2), Vector2i(5, 7)],
			[Vector2i(5, 2), Vector2i(10, 2)],
			[Vector2i(10, 2), Vector2i(10, 4)],
			[Vector2i(10, 4), Vector2i(13, 4)],
			[Vector2i(8, 9), Vector2i(19, 9)],
			[Vector2i(8, 6), Vector2i(8, 9)],
			[Vector2i(8, 6), Vector2i(13, 6)],
			[Vector2i(13, 3), Vector2i(13, 6)],
			[Vector2i(13, 3), Vector2i(17, 3)],
			[Vector2i(15, 4), Vector2i(17, 4)],
		],
		"route": [Vector2(-16, 240), Vector2(176, 240), Vector2(176, 80), Vector2(336, 80), Vector2(336, 144), Vector2(432, 144), Vector2(432, 112), Vector2(560, 112)],
		"route2": [Vector2(656, 304), Vector2(272, 304), Vector2(272, 208), Vector2(432, 208), Vector2(432, 112), Vector2(560, 112)],
		"decor": {
			Vector2i(6, 3): BUSH, Vector2i(7, 3): BERRY_BUSH, Vector2i(8, 3): BUSH, Vector2i(9, 3): ROCK,
			Vector2i(6, 4): BERRY_BUSH, Vector2i(7, 4): BUSH, Vector2i(8, 4): BERRY_BUSH, Vector2i(9, 4): BUSH,
			Vector2i(6, 5): ROCK, Vector2i(7, 5): BERRY_BUSH, Vector2i(8, 5): BUSH, Vector2i(9, 5): BERRY_BUSH,
			Vector2i(1, 1): ROCK, Vector2i(3, 1): BUSH, Vector2i(1, 4): BERRY_BUSH, Vector2i(3, 5): BUSH,
			Vector2i(1, 9): BUSH, Vector2i(4, 9): ROCK, Vector2i(12, 1): BERRY_BUSH, Vector2i(18, 7): ROCK,
			Vector2i(16, 8): BUSH, Vector2i(6, 8): BUSH, Vector2i(6, 9): BERRY_BUSH,
		},
	},
}


func _init() -> void:
	for file_name in DirAccess.get_files_at(SPRITES_DIR):
		if file_name.get_extension() == "json":
			_build_sprite(file_name.get_basename())
	for level_id: String in LEVELS:
		var config: Dictionary = LEVELS[level_id]
		var tileset := _build_tileset(config.tiles, config.tileset)
		if "--scene" in OS.get_cmdline_user_args() or not FileAccess.file_exists(LEVEL_PATH % level_id):
			_build_level(level_id, config, tileset)
	quit()


func _build_sprite(sprite: String) -> void:
	var text := FileAccess.get_file_as_string("res://assets/sprites/%s.json" % sprite)
	var sheet := AsepriteFrames.parse(text)
	if sheet.error != "":
		push_error("%s: %s" % [sprite, sheet.error])
		quit(1)
		return
	var texture: Texture2D = load("res://assets/sprites/%s.png" % sprite)
	ResourceSaver.save(AsepriteFrames.build(sheet, texture), "res://assets/sprites/%s.tres" % sprite)


func _build_tileset(tiles_path: String, tileset_path: String) -> TileSet:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE, TILE)
	tileset.add_custom_data_layer()
	tileset.set_custom_data_layer_name(0, "buildable")
	tileset.set_custom_data_layer_type(0, TYPE_BOOL)
	tileset.add_terrain_set()
	tileset.set_terrain_set_mode(0, TileSet.TERRAIN_MODE_MATCH_SIDES)
	tileset.add_terrain(0)
	tileset.set_terrain_name(0, 0, "caminho")

	var source := TileSetAtlasSource.new()
	source.texture = load(tiles_path)
	source.texture_region_size = Vector2i(TILE, TILE)
	tileset.add_source(source, 0)
	for y in ATLAS_SIZE.y:
		for x in ATLAS_SIZE.x:
			var coords := Vector2i(x, y)
			source.create_tile(coords)
			source.get_tile_data(coords, 0).set_custom_data("buildable", y == 0 and x <= LAST_GRASS_COLUMN)
	for mask in 16:
		var data := source.get_tile_data(_path_tile(mask), 0)
		data.terrain_set = 0
		data.terrain = 0
		if mask & 1:
			data.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_TOP_SIDE, 0)
		if mask & 2:
			data.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_RIGHT_SIDE, 0)
		if mask & 4:
			data.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_BOTTOM_SIDE, 0)
		if mask & 8:
			data.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_LEFT_SIDE, 0)
	ResourceSaver.save(tileset, tileset_path)
	return load(tileset_path)


func _build_level(level_id: String, config: Dictionary, tileset: TileSet) -> void:
	var root := Node2D.new()
	root.name = config.node
	var ground := _layer("Ground", tileset, root)
	var decor := _layer("Decor", tileset, root)
	decor.y_sort_enabled = false

	var path_cells := _path_cells(config.path_runs)
	for y in GRID.y:
		for x in GRID.x:
			var cell := Vector2i(x, y)
			if path_cells.has(cell):
				ground.set_cell(cell, 0, _path_tile(_mask(cell, path_cells)))
			elif y == 0 or y == GRID.y - 1 or VILLAGE_CELLS.has_point(cell):
				ground.set_cell(cell, 0, LOCKED_GRASS)
			else:
				ground.set_cell(cell, 0, Vector2i((x * 7 + y * 13) % 4, 0))
	for cell: Vector2i in config.decor:
		decor.set_cell(cell, 0, config.decor[cell])

	root.add_child(_route_node("Route", config.route))
	if config.has("route2"):
		root.add_child(_route_node("Route2", config.route2))

	var village := Sprite2D.new()
	village.name = "Village"
	village.texture = load("res://assets/sprites/village.png")
	village.position = (Vector2(VILLAGE_CELLS.position) + Vector2(VILLAGE_CELLS.size) / 2.0) * TILE
	root.add_child(village)

	for child in root.get_children():
		child.owner = root
	var packed := PackedScene.new()
	packed.pack(root)
	var level_path := LEVEL_PATH % level_id
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(level_path.get_base_dir()))
	ResourceSaver.save(packed, level_path)
	root.free()


func _route_node(node_name: String, points: Array) -> Path2D:
	var route := Path2D.new()
	route.name = node_name
	route.curve = Curve2D.new()
	for point: Vector2 in points:
		route.curve.add_point(point)
	return route


func _layer(layer_name: String, tileset: TileSet, parent: Node) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = layer_name
	layer.tile_set = tileset
	parent.add_child(layer)
	return layer


func _path_cells(path_runs: Array) -> Dictionary:
	var cells := {}
	for run: Array in path_runs:
		for y in range(run[0].y, run[1].y + 1):
			for x in range(run[0].x, run[1].x + 1):
				cells[Vector2i(x, y)] = true
	return cells


## A entrada à esquerda e a saída à direita do mapa contam como caminho aberto.
func _mask(cell: Vector2i, cells: Dictionary) -> int:
	var mask := 0
	if cells.has(cell + Vector2i.UP):
		mask |= 1
	if cells.has(cell + Vector2i.RIGHT) or cell.x == GRID.x - 1:
		mask |= 2
	if cells.has(cell + Vector2i.DOWN):
		mask |= 4
	if cells.has(cell + Vector2i.LEFT) or cell.x == 0:
		mask |= 8
	return mask


func _path_tile(mask: int) -> Vector2i:
	return Vector2i(mask % 8, 1 + mask / 8)
