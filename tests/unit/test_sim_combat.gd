extends GutTest

const Fixtures = preload("res://tests/unit/fixtures.gd")

var sim

func before_each() -> void:
	sim = Fixtures.simulation()
	sim.gold = 1000

func _spawn(kind: String, distance: float):
	var monster = sim.spawn_monster(kind)
	monster.distance = distance
	return monster

func test_archer_hits_a_monster_in_range() -> void:
	var monster = _spawn("goblin", 40.0)
	sim.place_unit("archer", Vector2i(1, 1))
	sim.tick(0.01)
	assert_eq(monster.hp, 5)

func test_archer_ignores_a_monster_out_of_range() -> void:
	var monster = _spawn("goblin", 190.0)
	sim.place_unit("archer", Vector2i(1, 1))
	sim.tick(0.01)
	assert_eq(monster.hp, 10)

func test_attack_respects_the_cooldown() -> void:
	var monster = _spawn("brute", 40.0)
	monster.speed = 0.0
	sim.place_unit("archer", Vector2i(1, 1))
	sim.tick(0.01)
	sim.tick(0.5)
	assert_eq(monster.hp, 37, "só um ataque em meio segundo")
	sim.tick(0.6)
	assert_eq(monster.hp, 34)

func test_resistance_multiplies_damage() -> void:
	var monster = _spawn("brute", 48.0)
	sim.place_unit("warrior", Vector2i(1, 1))
	sim.tick(0.01)
	assert_eq(monster.hp, 30, "impacto dobra contra o bruto")

func test_kill_pays_gold_and_removes_monster() -> void:
	var monster = _spawn("goblin", 40.0)
	monster.hp = 1
	sim.place_unit("archer", Vector2i(1, 1))
	var before: int = sim.gold
	sim.tick(0.01)
	assert_eq(sim.gold, before + 3)
	assert_eq(sim.monsters.size(), 0)

func test_default_priority_targets_the_most_advanced() -> void:
	var behind = _spawn("goblin", 30.0)
	var ahead = _spawn("goblin", 60.0)
	sim.place_unit("archer", Vector2i(1, 1))
	sim.tick(0.01)
	assert_eq(ahead.hp, 5)
	assert_eq(behind.hp, 10)

func test_priority_last_targets_the_least_advanced() -> void:
	var behind = _spawn("goblin", 30.0)
	var ahead = _spawn("goblin", 60.0)
	var unit = sim.place_unit("archer", Vector2i(1, 1))
	unit.priority = "last"
	sim.tick(0.01)
	assert_eq(behind.hp, 5)
	assert_eq(ahead.hp, 10)

func test_priority_strongest_targets_highest_hp() -> void:
	var weak = _spawn("goblin", 60.0)
	var strong = _spawn("brute", 30.0)
	var unit = sim.place_unit("archer", Vector2i(1, 1))
	unit.priority = "strongest"
	sim.tick(0.01)
	assert_eq(strong.hp, 37, "perfurante vale metade contra o bruto")
	assert_eq(weak.hp, 10)

func test_priority_closest_targets_nearest_to_unit() -> void:
	var far = _spawn("goblin", 100.0)
	var near = _spawn("goblin", 48.0)
	var unit = sim.place_unit("archer", Vector2i(1, 1))
	unit.priority = "closest"
	sim.tick(0.01)
	assert_eq(near.hp, 5)
	assert_eq(far.hp, 10)

func test_level_three_arrow_pierces_a_nearby_monster() -> void:
	var first = _spawn("brute", 60.0)
	var second = _spawn("brute", 40.0)
	var third = _spawn("brute", 10.0)
	var unit = sim.place_unit("archer", Vector2i(1, 1))
	sim.upgrade_unit(unit)
	sim.upgrade_unit(unit)
	sim.tick(0.01)
	assert_eq(first.hp, 35)
	assert_eq(second.hp, 35)
	assert_eq(third.hp, 40, "só atravessa pierce_extra inimigos dentro do raio")

func test_melee_blocks_monster_in_range() -> void:
	var monster = _spawn("brute", 40.0)
	sim.place_unit("warrior", Vector2i(1, 1))
	sim.tick(0.01)
	var before: float = monster.distance
	sim.tick(0.5)
	assert_eq(monster.distance, before)
	assert_not_null(monster.blocker)

func test_ranged_unit_never_blocks() -> void:
	var monster = _spawn("brute", 40.0)
	sim.place_unit("archer", Vector2i(1, 1))
	sim.tick(0.01)
	var before: float = monster.distance
	sim.tick(0.5)
	assert_gt(monster.distance, before)

func test_block_capacity_lets_extra_monsters_pass() -> void:
	var first = _spawn("brute", 41.0)
	var second = _spawn("brute", 40.0)
	sim.place_unit("warrior", Vector2i(1, 1))
	sim.tick(0.01)
	assert_not_null(first.blocker)
	assert_null(second.blocker)

func test_level_three_warrior_blocks_one_more() -> void:
	var first = _spawn("brute", 41.0)
	var second = _spawn("brute", 40.0)
	var unit = sim.place_unit("warrior", Vector2i(1, 1))
	sim.upgrade_unit(unit)
	sim.upgrade_unit(unit)
	sim.tick(0.01)
	assert_not_null(first.blocker)
	assert_not_null(second.blocker)

func test_blocked_monster_damages_its_blocker() -> void:
	_spawn("brute", 40.0)
	var unit = sim.place_unit("warrior", Vector2i(1, 1))
	sim.tick(0.01)
	assert_eq(unit.hp, 16)
	sim.tick(1.0)
	assert_eq(unit.hp, 12)

func test_level_three_warrior_takes_less_damage() -> void:
	_spawn("brute", 40.0)
	var unit = sim.place_unit("warrior", Vector2i(1, 1))
	sim.upgrade_unit(unit)
	sim.upgrade_unit(unit)
	sim.tick(0.01)
	assert_eq(unit.hp, 38)

func test_ranged_unit_is_never_attacked() -> void:
	var monster = _spawn("brute", 40.0)
	monster.speed = 0.0
	var unit = sim.place_unit("archer", Vector2i(1, 1))
	sim.tick(1.0)
	assert_eq(unit.hp, 0)
	assert_false(unit.is_down())

func test_fallen_melee_releases_monsters_and_stops_acting() -> void:
	var monster = _spawn("brute", 40.0)
	var unit = sim.place_unit("warrior", Vector2i(1, 1))
	unit.hp = 1
	sim.tick(0.01)
	assert_true(unit.is_down())
	assert_null(monster.blocker)
	var hp: int = monster.hp
	sim.tick(1.2)
	assert_eq(monster.hp, hp)
	assert_null(monster.blocker)

func test_fallen_melee_returns_with_full_hp() -> void:
	var monster = _spawn("goblin", 40.0)
	monster.speed = 0.0
	monster.damage = 100
	var unit = sim.place_unit("warrior", Vector2i(1, 1))
	unit.hp = 1
	sim.tick(0.01)
	sim.monsters.clear()
	sim.tick(5.1)
	assert_false(unit.is_down())
	assert_eq(unit.hp, 20)

func test_dismissing_a_blocker_releases_its_monsters() -> void:
	var monster = _spawn("brute", 40.0)
	var unit = sim.place_unit("warrior", Vector2i(1, 1))
	sim.tick(0.01)
	sim.dismiss_unit(unit)
	assert_null(monster.blocker)

func test_killed_monster_frees_block_capacity() -> void:
	var first = _spawn("goblin", 44.0)
	first.hp = 1
	var unit = sim.place_unit("warrior", Vector2i(1, 1))
	sim.tick(0.01)
	assert_eq(unit.blocked.size(), 0)

func test_upgrade_keeps_damage_taken_but_adds_new_hp() -> void:
	var unit = sim.place_unit("warrior", Vector2i(1, 1))
	unit.hp = 15
	sim.upgrade_unit(unit)
	assert_eq(unit.hp, 25)

func test_facing_keeps_last_horizontal_direction() -> void:
	var level = Fixtures.level()
	level["route"] = [Vector2(100, 0), Vector2(0, 0), Vector2(0, 100)]
	var other = load("res://src/core/simulation.gd").new(Fixtures.catalog(), level)
	var monster = other.spawn_monster("goblin")
	other.tick(0.1)
	assert_eq(monster.facing, -1)
	monster.distance = 120.0
	other.tick(0.1)
	assert_eq(monster.facing, -1, "trecho vertical mantém o lado")

func test_events_are_drained_once() -> void:
	var monster = _spawn("goblin", 40.0)
	monster.hp = 1
	sim.place_unit("archer", Vector2i(1, 1))
	sim.tick(0.01)
	var types: Array = sim.drain_events().map(func(e): return e.type)
	assert_has(types, "attack")
	assert_has(types, "monster_killed")
	assert_eq(sim.drain_events(), [])
