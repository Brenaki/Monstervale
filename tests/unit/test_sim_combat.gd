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

func _near_route_sim():
	var level = Fixtures.level()
	level["route"] = [Vector2(0, 80), Vector2(200, 80)]
	var near = load("res://src/core/simulation.gd").new(Fixtures.catalog(), level)
	near.gold = 1000
	return near

func test_passing_monster_hits_a_ranged_unit_in_its_reach() -> void:
	var near = _near_route_sim()
	var monster = near.spawn_monster("goblin")
	monster.distance = 48.0
	var unit = near.place_unit("archer", Vector2i(1, 1))
	near.tick(0.01)
	assert_eq(unit.hp, 16)

func test_monster_keeps_walking_while_hitting_a_ranged_unit() -> void:
	var near = _near_route_sim()
	var monster = near.spawn_monster("goblin")
	monster.distance = 48.0
	near.place_unit("archer", Vector2i(1, 1))
	near.tick(0.5)
	assert_almost_eq(monster.distance, 53.0, 0.01)
	assert_null(monster.blocker)

func test_passing_attack_respects_the_cooldown() -> void:
	var near = _near_route_sim()
	var monster = near.spawn_monster("goblin")
	monster.distance = 48.0
	monster.speed = 0.0
	var unit = near.place_unit("archer", Vector2i(1, 1))
	near.tick(0.01)
	near.tick(0.5)
	assert_eq(unit.hp, 16)
	near.tick(0.6)
	assert_eq(unit.hp, 12)

func test_ranged_unit_out_of_reach_is_safe() -> void:
	var monster = _spawn("brute", 48.0)
	monster.speed = 0.0
	var unit = sim.place_unit("archer", Vector2i(1, 1))
	sim.tick(2.0)
	assert_eq(unit.hp, 20, "48 px do caminho está fora dos 40 de alcance")

func test_ranged_unit_falls_and_stops_attacking() -> void:
	var near = _near_route_sim()
	var monster = near.spawn_monster("goblin")
	monster.distance = 48.0
	monster.speed = 0.0
	var unit = near.place_unit("archer", Vector2i(1, 1))
	unit.hp = 1
	near.tick(0.01)
	assert_true(unit.is_down())
	var hp: int = monster.hp
	near.tick(2.0)
	assert_eq(monster.hp, hp, "caído não atira")

func test_ranged_unit_returns_with_full_hp() -> void:
	var near = _near_route_sim()
	var monster = near.spawn_monster("goblin")
	monster.distance = 48.0
	monster.speed = 0.0
	var unit = near.place_unit("archer", Vector2i(1, 1))
	unit.hp = 1
	near.tick(0.01)
	near.monsters.clear()
	near.tick(5.1)
	assert_false(unit.is_down())
	assert_eq(unit.hp, 20)

func test_passing_monster_ignores_fallen_units_and_picks_the_nearest() -> void:
	var near = _near_route_sim()
	var monster = near.spawn_monster("brute")
	monster.distance = 60.0
	monster.speed = 0.0
	var close = near.place_unit("archer", Vector2i(1, 1))
	var other = near.place_unit("archer", Vector2i(2, 1))
	near.tick(0.01)
	assert_eq(close.hp, 16)
	assert_eq(other.hp, 20)
	close.down_timer = 100.0
	near.tick(1.1)
	assert_eq(other.hp, 16)

func test_blocked_monster_hits_only_its_blocker() -> void:
	var near = _near_route_sim()
	var monster = near.spawn_monster("brute")
	monster.distance = 48.0
	var blocker = near.place_unit("warrior", Vector2i(1, 1))
	var archer = near.place_unit("archer", Vector2i(2, 1))
	near.tick(0.01)
	assert_not_null(monster.blocker)
	assert_eq(blocker.hp, 16)
	assert_eq(archer.hp, 20)

func test_passing_monster_also_hits_a_melee_unit_without_room() -> void:
	var near = _near_route_sim()
	var first = near.spawn_monster("goblin")
	first.distance = 49.0
	first.speed = 0.0
	var second = near.spawn_monster("goblin")
	second.distance = 48.0
	second.speed = 0.0
	var unit = near.place_unit("warrior", Vector2i(1, 1))
	near.tick(0.01)
	assert_not_null(first.blocker)
	assert_null(second.blocker)
	assert_eq(unit.hp, 12, "um golpe de quem está bloqueado e outro de quem passa")

func test_monster_reach_comes_from_the_data() -> void:
	var catalog = Fixtures.catalog()
	catalog.monsters.goblin.reach = 10.0
	var level = Fixtures.level()
	level["route"] = [Vector2(0, 80), Vector2(200, 80)]
	var other = load("res://src/core/simulation.gd").new(catalog, level)
	other.gold = 1000
	var monster = other.spawn_monster("goblin")
	monster.distance = 48.0
	monster.speed = 0.0
	var unit = other.place_unit("archer", Vector2i(1, 1))
	other.tick(0.01)
	assert_eq(unit.hp, 20)

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

func _damaged_warrior(level: int, hp: int):
	var unit = sim.place_unit("warrior", Vector2i(1, 1))
	for i in level - 1:
		sim.upgrade_unit(unit)
	unit.hp = hp
	unit.time_since_hit = 0.0
	return unit

func _tick_for(seconds: float) -> void:
	for i in roundi(seconds * 60.0):
		sim.tick(1.0 / 60.0)

func test_level_one_warrior_does_not_recover() -> void:
	var unit = _damaged_warrior(1, 10)
	_tick_for(10.0)
	assert_eq(unit.hp, 10)

func test_level_two_warrior_recovers_after_a_while_without_damage() -> void:
	var unit = _damaged_warrior(2, 10)
	_tick_for(2.9)
	assert_eq(unit.hp, 10, "ainda na espera")
	_tick_for(2.1)
	assert_between(unit.hp, 13, 15, "cerca de 2 de vida por segundo depois da espera")

func test_level_three_warrior_recovers_faster() -> void:
	var unit = _damaged_warrior(3, 10)
	_tick_for(5.0)
	assert_between(unit.hp, 17, 19, "cerca de 4 de vida por segundo depois da espera")

func test_recovery_stops_at_full_health() -> void:
	var unit = _damaged_warrior(2, 29)
	_tick_for(10.0)
	assert_eq(unit.hp, 30)

func test_taking_a_hit_restarts_the_wait() -> void:
	var unit = _damaged_warrior(2, 20)
	_tick_for(2.9)
	var monster = _spawn("goblin", 48.0)
	monster.hp = 1
	sim.tick(1.0 / 60.0)
	assert_eq(unit.hp, 16, "o goblin bate uma vez e morre")
	_tick_for(2.9)
	assert_eq(unit.hp, 16, "a espera recomeçou")
	_tick_for(2.1)
	assert_between(unit.hp, 19, 21)

func test_fallen_warrior_does_not_recover_while_down() -> void:
	var unit = _damaged_warrior(2, 1)
	unit.hp = 0
	unit.down_timer = 2.0
	sim.tick(1.0)
	assert_eq(unit.hp, 0)

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
