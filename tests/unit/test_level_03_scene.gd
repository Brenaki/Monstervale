extends "res://tests/unit/test_level_scene.gd"

const Route = preload("res://src/core/route.gd")

func _level_id() -> String:
	return "level_03"

func test_forest_uses_its_own_tiles() -> void:
	var ground: TileMapLayer = scene.get_node("Ground")
	assert_string_contains(ground.tile_set.resource_path, "forest")

func test_forest_has_two_entrances_that_end_at_the_same_village() -> void:
	assert_eq(level.routes.size(), 2)
	assert_ne(level.routes[0][0], level.routes[1][0])
	assert_eq(level.routes[0][-1], level.routes[1][-1])

func test_no_cell_along_any_route_is_buildable() -> void:
	for points: Array in level.routes:
		var route := Route.new(points)
		var distance := 0.0
		while distance < route.length:
			var cell := _cell_of(route.position_at(distance))
			assert_false(level.buildable.has(cell), "%s no caminho" % cell)
			distance += 8.0

func test_every_group_uses_an_existing_entrance() -> void:
	for wave: Dictionary in level.waves:
		for group: Dictionary in wave.groups:
			assert_lt(int(group.get("route", 0)), level.routes.size())

func test_waves_use_both_entrances() -> void:
	var used := {}
	for wave: Dictionary in level.waves:
		for group: Dictionary in wave.groups:
			used[int(group.get("route", 0))] = true
	assert_eq(used.size(), 2)

func test_forest_mixes_wolves_and_earlier_monsters() -> void:
	var seen := {}
	for wave: Dictionary in level.waves:
		for group: Dictionary in wave.groups:
			seen[group.monster] = true
	assert_true(seen.has("wolf"))
	assert_true(seen.has("goblin"), "cada fase mantém os monstros das anteriores")
	assert_true(seen.has("slime"), "cada fase mantém os monstros das anteriores")

func test_forest_offers_the_spearman_and_the_druid() -> void:
	assert_true("spearman" in level.classes)
	assert_true("druid" in level.classes)
