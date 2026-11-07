extends GutTest

const Fixtures = preload("res://tests/unit/fixtures.gd")
const GameData = preload("res://src/core/game_data.gd")

func _hit_events(sim) -> Array:
	return sim.drain_events().filter(func(e): return e.type == "monster_hit")

func test_monster_hit_says_how_the_damage_type_worked() -> void:
	var sim = Fixtures.simulation()
	sim.gold = 1000
	var monster = sim.spawn_monster("brute")
	monster.distance = 48.0
	monster.hp = 100000
	var unit = sim.place_unit("archer", Vector2i(1, 1))
	unit.cooldown = 0.0
	sim.tick(0.001)
	assert_eq(_hit_events(sim)[0].effect, "resisted")
	sim.dismiss_unit(unit)
	unit = sim.place_unit("warrior", Vector2i(1, 1))
	unit.cooldown = 0.0
	sim.tick(0.001)
	assert_eq(_hit_events(sim)[0].effect, "weak")

func test_neutral_hit_is_marked_as_normal() -> void:
	var sim = Fixtures.simulation()
	sim.gold = 1000
	var monster = sim.spawn_monster("goblin")
	monster.distance = 48.0
	monster.hp = 100000
	var unit = sim.place_unit("archer", Vector2i(1, 1))
	unit.cooldown = 0.0
	sim.tick(0.001)
	assert_eq(_hit_events(sim)[0].effect, "normal")

func test_next_wave_weaknesses_list_each_type_once() -> void:
	var sim = Fixtures.simulation([
		Fixtures.wave([Fixtures.group("brute"), Fixtures.group("goblin"), Fixtures.group("brute")]),
		Fixtures.wave([Fixtures.group("goblin")]),
	])
	assert_eq(sim.next_wave_weaknesses(), ["impact"])
	sim.call_next_wave()
	assert_eq(sim.next_wave_weaknesses(), [])
	sim.tick(5.0)
	sim.call_next_wave()
	assert_eq(sim.next_wave_weaknesses(), [])

func test_unit_damage_type_comes_from_the_catalog() -> void:
	var sim = Fixtures.simulation()
	assert_eq(sim.unit_damage_type("mage"), "magic")

func test_each_skeleton_asks_for_a_different_answer() -> void:
	var monsters: Dictionary = GameData.load_catalog().monsters
	assert_lt(monsters.skeleton.resist.pierce, 1.0)
	assert_gt(monsters.skeleton.resist.impact, 1.0)
	assert_lt(monsters.skeleton_knight.resist.pierce, 1.0)
	assert_lt(monsters.skeleton_knight.resist.impact, 1.0)
	assert_gt(monsters.skeleton_knight.resist.magic, 1.0)
