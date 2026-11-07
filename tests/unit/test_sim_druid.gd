extends GutTest

const Fixtures = preload("res://tests/unit/fixtures.gd")

var sim

func before_each() -> void:
	sim = Fixtures.simulation()
	sim.gold = 1000

func _walker(distance: float):
	var monster = sim.spawn_monster("goblin")
	monster.distance = distance
	return monster

func _druid(level: int):
	var unit = sim.place_unit("druid", Vector2i(1, 1))
	for i in level - 1:
		sim.upgrade_unit(unit)
	return unit

func test_slowed_monster_walks_slower_while_the_effect_lasts() -> void:
	var monster = _walker(50.0)
	monster.apply_slow(0.5, 1.0)
	var start: float = monster.distance
	sim.tick(0.5)
	assert_almost_eq(monster.distance - start, 2.5, 0.01)
	sim.tick(0.6)
	var middle: float = monster.distance
	sim.tick(0.5)
	assert_almost_eq(monster.distance - middle, 5.0, 0.01, "voltou ao normal")

func test_druid_attack_slows_the_target() -> void:
	var monster = _walker(50.0)
	_druid(1)
	sim.tick(0.01)
	assert_true(monster.is_slowed())
	assert_lt(monster.current_speed(), monster.speed)

func test_slow_with_a_radius_also_reaches_neighbors() -> void:
	var catalog := Fixtures.catalog()
	catalog.units.druid.levels[0].slow.radius = 20.0
	sim = load("res://src/core/simulation.gd").new(catalog, Fixtures.level())
	sim.gold = 1000
	var target = _walker(50.0)
	var near = _walker(40.0)
	var far = _walker(10.0)
	_druid(1)
	sim.tick(0.01)
	assert_true(target.is_slowed())
	assert_true(near.is_slowed())
	assert_false(far.is_slowed())

func test_stronger_slow_is_not_replaced_by_a_weaker_one() -> void:
	var monster = _walker(50.0)
	monster.apply_slow(0.3, 2.0)
	monster.apply_slow(0.8, 1.0)
	assert_almost_eq(monster.current_speed(), monster.speed * 0.3, 0.01)

func test_rooted_monster_does_not_walk_but_still_hits_nearby_humans() -> void:
	var monster = _walker(50.0)
	var archer = sim.place_unit("archer", Vector2i(1, 1))
	archer.cooldown = 100.0
	monster.reach = 100.0
	monster.apply_root(1.0)
	var start: float = monster.distance
	var hp: int = archer.hp
	sim.tick(0.5)
	assert_eq(monster.distance, start)
	sim.tick(0.6)
	assert_lt(archer.hp, hp)
	assert_gt(monster.distance, start, "as raízes soltaram")

func test_levels_one_and_two_never_root() -> void:
	var monster = _walker(50.0)
	monster.hp = 1000
	monster.max_hp = 1000
	var unit = _druid(2)
	for i in 6:
		unit.cooldown = 0.0
		sim.tick(0.01)
		assert_false(monster.is_rooted())

func test_level_three_roots_on_every_third_attack() -> void:
	var monster = _walker(50.0)
	monster.hp = 1000
	monster.max_hp = 1000
	var unit = _druid(3)
	var rooted := []
	for i in 6:
		unit.cooldown = 0.0
		monster.root_timer = 0.0
		sim.tick(0.01)
		rooted.append(monster.is_rooted())
	assert_eq(rooted, [false, false, true, false, false, true])
