extends GutTest

const Fixtures = preload("res://tests/unit/fixtures.gd")
const Simulation = preload("res://src/core/simulation.gd")

const NORTH := [Vector2(0, 0), Vector2(100, 0), Vector2(100, 50)]
const SOUTH := [Vector2(0, 100), Vector2(100, 100), Vector2(100, 50)]

func _simulation(waves: Array = []) -> Simulation:
	var level := Fixtures.level(waves)
	level["routes"] = [NORTH, SOUTH]
	level["route"] = NORTH
	return Simulation.new(Fixtures.catalog(), level)

func _group(monster: String, route: int) -> Dictionary:
	var group := Fixtures.group(monster)
	group["route"] = route
	return group

func test_a_level_without_routes_uses_its_single_route() -> void:
	var sim := Fixtures.simulation()
	assert_eq(sim.routes.size(), 1)
	assert_eq(sim.spawn_monster("goblin").position(), Vector2(0, 0))

func test_monster_starts_on_the_chosen_route() -> void:
	var sim := _simulation()
	assert_eq(sim.spawn_monster("goblin", 1).position(), Vector2(0, 100))

func test_wave_group_chooses_its_route() -> void:
	var sim := _simulation([Fixtures.wave([_group("goblin", 1)])])
	sim.call_next_wave()
	sim.tick(0.01)
	assert_eq(sim.monsters.size(), 1)
	assert_almost_eq(sim.monsters[0].position().y, 100.0, 0.01)

func test_group_without_route_uses_the_first() -> void:
	var sim := _simulation([Fixtures.wave([Fixtures.group("goblin")])])
	sim.call_next_wave()
	sim.tick(0.01)
	assert_almost_eq(sim.monsters[0].position().y, 0.0, 0.01)

func test_monster_escapes_at_the_end_of_its_own_route() -> void:
	var catalog := Fixtures.catalog()
	var level := Fixtures.level()
	level["routes"] = [[Vector2(0, 0), Vector2(1000, 0)], [Vector2(0, 100), Vector2(10, 100)]]
	var sim := Simulation.new(catalog, level)
	sim.spawn_monster("goblin", 1)
	sim.tick(2.0)
	assert_eq(sim.lives, 9)
	assert_eq(sim.monsters.size(), 0)

func test_split_children_stay_on_the_route_of_the_parent() -> void:
	var sim := _simulation()
	var slime = sim.spawn_monster("slime", 1)
	slime.distance = 50.0
	sim._damage(slime, 100, "test")
	assert_eq(sim.monsters.size(), 2)
	for child in sim.monsters:
		assert_almost_eq(child.position().y, 100.0, 0.01)

func test_next_wave_tells_which_routes_it_uses() -> void:
	var sim := _simulation([
		Fixtures.wave([_group("goblin", 1)]),
		Fixtures.wave([_group("goblin", 0), _group("slime", 1)]),
	])
	assert_eq(sim.next_wave_routes(), [1])
	sim.call_next_wave()
	assert_eq(sim.next_wave_routes(), [0, 1])

func test_no_routes_to_warn_about_after_the_last_wave() -> void:
	var sim := _simulation()
	assert_eq(sim.next_wave_routes(), [])
