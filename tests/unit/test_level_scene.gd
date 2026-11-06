extends GutTest

const GameData = preload("res://src/core/game_data.gd")
const LevelReader = preload("res://src/game/level_reader.gd")

var scene: Node
var level: Dictionary

func before_each() -> void:
	scene = load("res://src/game/levels/level_01.tscn").instantiate()
	add_child_autofree(scene)
	level = LevelReader.read(scene, GameData.load_level("level_01"))

func _cell_of(point: Vector2) -> Vector2i:
	return Vector2i(int(floor(point.x / 32.0)), int(floor(point.y / 32.0)))

func test_reader_keeps_json_fields() -> void:
	assert_eq(level.id, "level_01")
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

func test_generated_sprites_have_idle_animation() -> void:
	for name: String in ["goblin", "archer", "warrior"]:
		var frames: SpriteFrames = load("res://assets/sprites/%s.tres" % name)
		assert_gt(frames.get_frame_count("idle"), 0, name)

func test_every_monster_points_to_an_existing_sprite() -> void:
	var catalog := GameData.load_catalog()
	for kind: String in catalog.monsters:
		assert_true(ResourceLoader.exists("res://assets/sprites/%s.tres" % catalog.monsters[kind].sprite), kind)
