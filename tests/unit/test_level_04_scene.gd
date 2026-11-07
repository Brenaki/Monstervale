extends "res://tests/unit/test_level_scene.gd"

const Route = preload("res://src/core/route.gd")

const MONSTER_REACH := 40.0
const LONGEST_RANGE := 112.0
const MOST_OF_A_ROUTE := 0.15
const SAMPLE := 8.0

func _level_id() -> String:
	return "level_04"

func _routes() -> Array:
	return level.routes.map(func(points): return Route.new(points))

## Trecho de cada entrada ao alcance, sem contar o que as duas compartilham no fim.
func _coverage(center: Vector2, index: int) -> float:
	var route = _routes()[index]
	var other = _routes()[1 - index]
	var covered := 0.0
	var own := 0.0
	var distance := 0.0
	while distance < route.length:
		var point: Vector2 = route.position_at(distance)
		if _distance_to_route(point, other) > 1.0:
			own += SAMPLE
			if point.distance_to(center) <= LONGEST_RANGE:
				covered += SAMPLE
		distance += SAMPLE
	return covered / own

func _distance_to_route(point: Vector2, route) -> float:
	var nearest := INF
	var distance := 0.0
	while distance < route.length:
		nearest = minf(nearest, point.distance_to(route.position_at(distance)))
		distance += SAMPLE
	return nearest

func test_cemetery_uses_its_own_tiles() -> void:
	var ground: TileMapLayer = scene.get_node("Ground")
	assert_string_contains(ground.tile_set.resource_path, "cemetery")

func test_entrances_come_from_opposite_sides_of_the_map() -> void:
	assert_eq(level.routes.size(), 2)
	assert_lt(level.routes[0][0].x, 0.0)
	assert_gt(level.routes[1][0].x, 640.0)
	assert_eq(level.routes[0][-1], level.routes[1][-1])

func test_no_cell_along_any_route_is_buildable() -> void:
	for route in _routes():
		var distance := 0.0
		while distance < route.length:
			assert_false(level.buildable.has(_cell_of(route.position_at(distance))))
			distance += SAMPLE

func test_every_wave_is_used_by_both_entrances_over_the_level() -> void:
	var used := {}
	for wave: Dictionary in level.waves:
		for group: Dictionary in wave.groups:
			assert_lt(int(group.get("route", 0)), level.routes.size())
			used[int(group.get("route", 0))] = true
	assert_eq(used.size(), 2)

## Na Fase 3, um arqueiro em (7,6) cobria as duas entradas sem nunca ser alcançado.
func test_no_safe_cell_covers_both_entrances() -> void:
	var cell_centers := {}
	for cell: Vector2i in level.buildable:
		cell_centers[cell] = (Vector2(cell) + Vector2(0.5, 0.5)) * 32.0
	var routes := _routes()
	for cell: Vector2i in cell_centers:
		var center: Vector2 = cell_centers[cell]
		var nearest := minf(_distance_to_route(center, routes[0]), _distance_to_route(center, routes[1]))
		if nearest <= MONSTER_REACH:
			continue
		var both := minf(_coverage(center, 0), _coverage(center, 1))
		assert_lt(both, MOST_OF_A_ROUTE, "%s cobre as duas entradas a salvo" % cell)

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
