extends GutTest

const GameData = preload("res://src/core/game_data.gd")
const LevelReader = preload("res://src/game/level_reader.gd")

var scene: Node
var level: Dictionary

func _level_id() -> String:
	return "level_01"

func before_each() -> void:
	scene = load("res://src/game/levels/%s.tscn" % _level_id()).instantiate()
	add_child_autofree(scene)
	level = LevelReader.read(scene, GameData.load_level(_level_id()))

func _cell_of(point: Vector2) -> Vector2i:
	return Vector2i(int(floor(point.x / 32.0)), int(floor(point.y / 32.0)))

func test_reader_keeps_json_fields() -> void:
	assert_eq(level.id, _level_id())
	assert_eq(level.cell_size, 32)

func test_route_starts_off_screen_and_reaches_the_village() -> void:
	assert_lt(level.route[0].x, 0.0)
	assert_gt(level.route[-1].x, 500.0)

func test_no_cell_along_the_route_is_buildable() -> void:
	var route := preload("res://src/core/route.gd").new(level.route)
	var distance := 0.0
	while distance < route.length:
		var cell := _cell_of(route.position_at(distance))
		assert_false(level.buildable.has(cell), "%s no caminho" % cell)
		distance += 8.0

func test_bushes_block_building() -> void:
	var decor: TileMapLayer = scene.get_node("Decor")
	var used := decor.get_used_cells()
	assert_gt(used.size(), 0)
	for cell: Vector2i in used:
		assert_false(level.buildable.has(cell))

func test_hud_rows_are_not_buildable() -> void:
	for x in 20:
		assert_false(level.buildable.has(Vector2i(x, 0)))
		assert_false(level.buildable.has(Vector2i(x, 10)))

func test_every_buildable_cell_is_inside_the_map() -> void:
	for cell: Vector2i in level.buildable:
		assert_true(cell.x >= 0 and cell.x < 20 and cell.y >= 1 and cell.y < 10, str(cell))

func test_there_is_room_to_build() -> void:
	assert_gt(level.buildable.size(), 80)

func test_every_monster_points_to_an_existing_sprite() -> void:
	var catalog := GameData.load_catalog()
	for kind: String in catalog.monsters:
		assert_true(ResourceLoader.exists("res://assets/sprites/%s.tres" % catalog.monsters[kind].sprite), kind)

func test_nothing_can_be_built_under_the_village() -> void:
	var village: Sprite2D = scene.get_node("Village")
	var rect := Rect2(village.position - village.texture.get_size() / 2.0, village.texture.get_size())
	for y in range(int(rect.position.y) / 32, int(rect.end.y - 1) / 32 + 1):
		for x in range(int(rect.position.x) / 32, 20):
			assert_false(level.buildable.has(Vector2i(x, y)), "(%d, %d) sob a vila" % [x, y])

func test_village_is_larger_than_a_single_house() -> void:
	var village: Sprite2D = scene.get_node("Village")
	assert_gte(village.texture.get_width(), 96)
	assert_gte(village.texture.get_height(), 128)

func test_decor_has_more_than_one_kind_of_plant_or_rock() -> void:
	var decor: TileMapLayer = scene.get_node("Decor")
	var kinds := {}
	for cell: Vector2i in decor.get_used_cells():
		kinds[decor.get_cell_atlas_coords(cell)] = true
	assert_gte(kinds.size(), 3)

func test_variants_use_their_own_sprites_instead_of_a_tint() -> void:
	var catalog := GameData.load_catalog()
	assert_eq(catalog.monsters.goblin_fast.sprite, "goblin_fast")
	assert_eq(catalog.monsters.goblin_shield.sprite, "goblin_shield")
	for kind: String in catalog.monsters:
		assert_false(catalog.monsters[kind].has("tint"), kind)
