extends GutTest

const Fixtures = preload("res://tests/unit/fixtures.gd")

var sim

func before_each() -> void:
	sim = Fixtures.simulation()
	sim.gold = 1000

func _standing(kind: String, distance: float):
	var monster = sim.spawn_monster(kind)
	monster.distance = distance
	monster.speed = 0.0
	return monster

func _mage(level: int):
	var unit = sim.place_unit("mage", Vector2i(1, 1))
	for i in level - 1:
		sim.upgrade_unit(unit)
	return unit

func test_explosion_hits_everyone_in_the_radius_with_full_damage() -> void:
	var target = _standing("goblin", 70.0)
	var near = _standing("goblin", 50.0)
	_mage(1)
	sim.tick(0.01)
	assert_eq(target.hp, 6)
	assert_eq(near.hp, 6)

func test_explosion_spares_who_is_outside_the_radius() -> void:
	_standing("goblin", 70.0)
	var far = _standing("goblin", 30.0)
	_mage(1)
	sim.tick(0.01)
	assert_eq(far.hp, 10)

func test_explosion_is_limited_to_its_targets_nearest_first() -> void:
	var catalog := Fixtures.catalog()
	catalog.units.mage.levels[0].splash_targets = 2
	sim = load("res://src/core/simulation.gd").new(catalog, Fixtures.level())
	sim.gold = 1000
	var target = _standing("goblin", 70.0)
	var nearest = _standing("goblin", 60.0)
	var spared = _standing("goblin", 50.0)
	_mage(1)
	sim.tick(0.01)
	assert_eq(target.hp, 6)
	assert_eq(nearest.hp, 6)
	assert_eq(spared.hp, 10)

func test_explosion_respects_magic_resistance() -> void:
	var catalog := Fixtures.catalog()
	catalog.monsters.goblin.resist.magic = 0.5
	sim = load("res://src/core/simulation.gd").new(catalog, Fixtures.level())
	sim.gold = 1000
	var target = _standing("goblin", 70.0)
	_mage(1)
	sim.tick(0.01)
	assert_eq(target.hp, 8)

func test_report_counts_explosion_damage_for_the_mage() -> void:
	_standing("goblin", 70.0)
	_standing("goblin", 50.0)
	_mage(1)
	sim.drain_events()
	sim.tick(0.01)
	var hits: Array = sim.drain_events().filter(func(e): return e.type == "monster_hit")
	assert_eq(hits.map(func(e): return e.source), ["mage", "mage"])

func test_children_born_from_an_explosion_are_not_hit_by_it() -> void:
	var slime = _standing("slime", 70.0)
	slime.hp = 1
	_mage(1)
	sim.tick(0.01)
	for child in sim.monsters:
		assert_eq(child.hp, 4)

func test_levels_one_and_two_leave_no_fire() -> void:
	_standing("brute", 70.0)
	_mage(2)
	sim.tick(0.01)
	assert_eq(sim.fires.size(), 0)

func test_level_three_leaves_fire_where_the_target_was() -> void:
	var target = _standing("brute", 70.0)
	_mage(3)
	sim.tick(0.01)
	assert_eq(sim.fires.size(), 1)
	assert_eq(sim.fires[0].position, target.position())

func test_fire_burns_who_stands_in_it_until_it_goes_out() -> void:
	var target = _standing("brute", 70.0)
	var unit = _mage(3)
	sim.tick(0.01)
	unit.cooldown = 99.0
	assert_eq(target.hp, 32)
	sim.tick(0.5)
	assert_eq(target.hp, 30)
	sim.tick(0.5)
	sim.tick(0.5)
	sim.tick(0.5)
	assert_eq(target.hp, 24)
	assert_eq(sim.fires.size(), 0)
	sim.tick(0.5)
	assert_eq(target.hp, 24, "o fogo apagou")

func test_fire_spares_who_is_outside_it() -> void:
	_standing("brute", 70.0)
	var unit = _mage(3)
	sim.tick(0.01)
	unit.cooldown = 99.0
	var far = _standing("brute", 30.0)
	sim.tick(0.5)
	assert_eq(far.hp, 40)

func test_fire_can_kill_and_pays_gold() -> void:
	var target = _standing("brute", 70.0)
	var unit = _mage(3)
	sim.tick(0.01)
	unit.cooldown = 99.0
	target.hp = 1
	var before: int = sim.gold
	sim.tick(0.5)
	assert_eq(sim.monsters.size(), 0)
	assert_eq(sim.gold, before + 8)

func test_fire_on_a_slime_splits_it() -> void:
	var target = _standing("slime", 70.0)
	var unit = _mage(3)
	target.hp = 100
	sim.tick(0.01)
	unit.cooldown = 99.0
	target.hp = 1
	sim.tick(0.5)
	assert_eq(sim.monsters.map(func(m): return m.kind), ["slimelet", "slimelet"])
