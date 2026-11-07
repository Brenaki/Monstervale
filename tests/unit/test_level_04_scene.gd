extends "res://tests/unit/two_entrance_level.gd"

func _level_id() -> String:
	return "level_04"

func test_cemetery_uses_its_own_tiles() -> void:
	var ground: TileMapLayer = scene.get_node("Ground")
	assert_string_contains(ground.tile_set.resource_path, "cemetery")

func test_entrances_come_from_opposite_sides_of_the_map() -> void:
	assert_eq(level.routes.size(), 2)
	assert_lt(level.routes[0][0].x, 0.0)
	assert_gt(level.routes[1][0].x, 640.0)
	assert_eq(level.routes[0][-1], level.routes[1][-1])

func test_cemetery_mixes_skeletons_and_earlier_monsters() -> void:
	var seen := {}
	for wave: Dictionary in level.waves:
		for group: Dictionary in wave.groups:
			seen[group.monster] = true
	for kind: String in ["skeleton", "skeleton_knight", "goblin", "wolf", "slime"]:
		assert_true(seen.has(kind), kind)

func test_cemetery_offers_all_seven_classes() -> void:
	assert_eq(level.classes.size(), 7)
	assert_true("monk" in level.classes)
	assert_true("rogue" in level.classes)
