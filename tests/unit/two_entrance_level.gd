extends "res://tests/unit/test_level_scene.gd"
## Verificações das fases com duas entradas. Sem o prefixo test_, o GUT só roda o que herda daqui.

const Route = preload("res://src/core/route.gd")

const MONSTER_REACH := 40.0
const LONGEST_RANGE := 112.0
const MOST_OF_A_ROUTE := 0.15
const SAMPLE := 8.0

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
