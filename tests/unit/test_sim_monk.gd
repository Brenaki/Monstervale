extends GutTest

const Fixtures = preload("res://tests/unit/fixtures.gd")
const GameData = preload("res://src/core/game_data.gd")

var sim

func before_each() -> void:
	sim = Fixtures.simulation()
	sim.gold = 1000

func _walker(distance: float):
	var monster = sim.spawn_monster("goblin")
	monster.distance = distance
	return monster

func _monk(level: int):
	var unit = sim.place_unit("monk", Vector2i(1, 1))
	for i in level - 1:
		sim.upgrade_unit(unit)
	return unit

func test_stunned_monster_does_not_walk_until_the_stun_ends() -> void:
	var monster = _walker(150.0)
	monster.apply_stun(1.0)
	sim.tick(0.5)
	assert_eq(monster.distance, 150.0)
	sim.tick(0.6)
	var after: float = monster.distance
	sim.tick(1.0)
	assert_gt(monster.distance, after)

func test_stunned_monster_does_not_hit_the_human_blocking_it() -> void:
	var monster = _walker(48.0)
	var unit = sim.place_unit("warrior", Vector2i(1, 1))
	sim.tick(0.01)
	assert_eq(monster.blocker, unit)
	monster.apply_stun(5.0)
	var hp_before: int = unit.hp
	monster.hp = 100000
	sim.tick(3.0)
	assert_eq(unit.hp, hp_before)

func test_stunned_monster_does_not_hit_in_passing() -> void:
	var monster = _walker(48.0)
	var unit = sim.place_unit("archer", Vector2i(1, 1))
	monster.apply_stun(5.0)
	monster.hp = 100000
	var hp_before: int = unit.hp
	sim.tick(3.0)
	assert_eq(unit.hp, hp_before)

func test_a_shorter_stun_does_not_cut_a_longer_one() -> void:
	var monster = _walker(50.0)
	monster.apply_stun(2.0)
	monster.apply_stun(0.5)
	sim.tick(1.0)
	assert_true(monster.is_stunned())

func test_monk_level_1_does_not_stun() -> void:
	var monster = _walker(48.0)
	monster.hp = 100000
	_monk(1)
	for i in 10:
		sim.tick(1.0)
		assert_false(monster.is_stunned())

func test_monk_level_3_stuns_on_every_nth_attack_without_luck() -> void:
	var monster = _walker(48.0)
	monster.hp = 100000
	var unit = _monk(3)
	var every: int = unit.stats().stun.every
	for attack in range(1, every * 2 + 1):
		sim.tick(float(unit.stats().cooldown) + 0.01)
		if unit.attacks_made % every == 0:
			assert_true(monster.is_stunned(), "ataque %d" % unit.attacks_made)
			monster.stun_timer = 0.0
		else:
			assert_false(monster.is_stunned(), "ataque %d" % unit.attacks_made)

func test_real_monk_attacks_faster_than_the_warrior_but_holds_fewer_monsters() -> void:
	var units: Dictionary = GameData.load_catalog().units
	for level in 3:
		assert_lt(units.monk.levels[level].cooldown, units.warrior.levels[level].cooldown)
		assert_lt(units.monk.levels[level].block, units.warrior.levels[level].block + 1)
		assert_lt(units.monk.levels[level].hp, units.warrior.levels[level].hp)
	assert_eq(units.monk.damage_type, "impact")
	assert_true(units.monk.levels[2].has("stun"))
