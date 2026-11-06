extends "res://tests/unit/test_level_scene.gd"

func _level_id() -> String:
	return "level_02"

func test_swamp_uses_its_own_tiles() -> void:
	var ground: TileMapLayer = scene.get_node("Ground")
	assert_string_contains(ground.tile_set.resource_path, "swamp")

func test_swamp_route_is_not_the_one_from_the_fields() -> void:
	var fields: Node = load("res://src/game/levels/level_01.tscn").instantiate()
	add_child_autofree(fields)
	var route: Array = LevelReader.read(fields, GameData.load_level("level_01")).route
	assert_ne(level.route, route)

func test_swamp_mixes_slimes_and_earlier_monsters() -> void:
	var seen := {}
	for wave: Dictionary in level.waves:
		for group: Dictionary in wave.groups:
			seen[group.monster] = true
	assert_true(seen.has("slime"))
	assert_true(seen.has("goblin"), "cada fase mantém os monstros das anteriores")

func test_swamp_offers_the_mage() -> void:
	assert_eq(level.classes, ["archer", "warrior", "mage"])
