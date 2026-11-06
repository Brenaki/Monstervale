extends GutTest

const Fixtures = preload("res://tests/unit/fixtures.gd")

var sim

func before_each() -> void:
	sim = Fixtures.simulation()
	sim.gold = 1000

func _dying_slime(distance := 40.0):
	var slime = sim.spawn_monster("slime")
	slime.distance = distance
	slime.hp = 1
	return slime

func _kill_with_archer() -> void:
	sim.place_unit("archer", Vector2i(1, 1))
	sim.tick(0.01)

func test_killed_slime_leaves_its_children() -> void:
	_dying_slime()
	_kill_with_archer()
	assert_eq(sim.monsters.map(func(m): return m.kind), ["slimelet", "slimelet"])

func test_children_appear_around_the_parent_without_overlapping() -> void:
	_dying_slime()
	_kill_with_archer()
	var first: float = sim.monsters[0].distance
	var second: float = sim.monsters[1].distance
	assert_ne(first, second)
	assert_almost_eq((first + second) / 2.0, 40.0, 1.0)

func test_children_never_appear_before_the_start_of_the_route() -> void:
	_dying_slime(0.0)
	_kill_with_archer()
	for child in sim.monsters:
		assert_gte(child.distance, 0.0)

func test_children_are_announced_so_the_game_can_draw_them() -> void:
	_dying_slime()
	sim.drain_events()
	_kill_with_archer()
	var spawned: Array = sim.drain_events().filter(func(e): return e.type == "monster_spawned")
	assert_eq(spawned.size(), 2)

func test_only_the_slime_itself_pays_gold() -> void:
	_dying_slime()
	var before: int = sim.gold - 40
	_kill_with_archer()
	assert_eq(sim.gold, before + 2)

func test_a_slime_that_reaches_the_village_does_not_split() -> void:
	var slime = sim.spawn_monster("slime")
	slime.distance = 199.9
	sim.tick(0.1)
	assert_eq(sim.monsters.size(), 0)
	assert_eq(sim.lives, 8)

func test_children_that_reach_the_village_cost_lives() -> void:
	var child = sim.spawn_monster("slimelet")
	child.distance = 199.9
	sim.tick(0.1)
	assert_eq(sim.lives, 9)

func test_a_wave_only_clears_after_the_children_die() -> void:
	sim = Fixtures.simulation([Fixtures.wave([Fixtures.group("slime")], 5)])
	sim.gold = 1000
	sim.call_next_wave()
	sim.tick(0.01)
	sim.monsters[0].hp = 1
	sim.monsters[0].distance = 40.0
	sim.drain_events()
	_kill_with_archer()
	assert_eq(sim.monsters.size(), 2)
	assert_false(sim.drain_events().any(func(e): return e.type == "wave_cleared"))
	for child in sim.monsters:
		child.hp = 1
	sim.tick(1.1)
	sim.tick(1.1)
	assert_true(sim.drain_events().any(func(e): return e.type == "wave_cleared"))

func test_a_level_is_not_won_while_children_are_alive() -> void:
	sim = Fixtures.simulation([Fixtures.wave([Fixtures.group("slime")])])
	sim.gold = 1000
	sim.call_next_wave()
	sim.tick(0.01)
	sim.monsters[0].hp = 1
	sim.monsters[0].distance = 40.0
	_kill_with_archer()
	assert_eq(sim.state, "playing")

func test_children_inherit_the_wave_for_the_report() -> void:
	sim = Fixtures.simulation([Fixtures.wave([Fixtures.group("slime")])])
	sim.gold = 1000
	sim.call_next_wave()
	sim.tick(0.01)
	var wave = sim.monsters[0].wave
	sim.monsters[0].hp = 1
	sim.monsters[0].distance = 40.0
	_kill_with_archer()
	for child in sim.monsters:
		assert_eq(child.wave, wave)

func test_children_keep_the_parent_facing() -> void:
	var level := Fixtures.level()
	level["route"] = [Vector2(200, 0), Vector2(0, 0)]
	sim = load("res://src/core/simulation.gd").new(Fixtures.catalog(), level)
	sim.gold = 1000
	_dying_slime(120.0)
	_kill_with_archer()
	assert_eq(sim.monsters[0].facing, -1)

func test_a_warrior_can_block_the_children() -> void:
	_dying_slime(48.0)
	var unit = sim.place_unit("warrior", Vector2i(1, 1))
	sim.tick(0.01)
	sim.tick(0.01)
	assert_eq(unit.blocked.size(), 1, "o guerreiro de teste segura um por vez")
