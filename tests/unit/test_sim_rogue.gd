extends GutTest

const Fixtures = preload("res://tests/unit/fixtures.gd")
const GameData = preload("res://src/core/game_data.gd")
const MatchLog = preload("res://src/core/match_log.gd")

var sim

func before_each() -> void:
	sim = Fixtures.simulation()
	sim.gold = 1000

func _walker(distance: float, hp := 100000):
	var monster = sim.spawn_monster("goblin")
	monster.distance = distance
	monster.hp = hp
	return monster

func _rogue(level: int):
	var unit = sim.place_unit("rogue", Vector2i(1, 1))
	for i in level - 1:
		sim.upgrade_unit(unit)
	return unit

func _attack_once(unit) -> void:
	unit.cooldown = 0.0
	sim.tick(0.001)

func test_every_nth_attack_is_a_critical_without_luck() -> void:
	var monster = _walker(48.0)
	var unit = _rogue(1)
	var stats: Dictionary = unit.stats()
	var plain := int(stats.damage)
	var critical := roundi(stats.damage * stats.crit.multiplier)
	for attack in range(1, stats.crit.every * 2 + 1):
		var before: int = monster.hp
		_attack_once(unit)
		var expected: int = critical if attack % int(stats.crit.every) == 0 else plain
		assert_eq(before - monster.hp, expected, "ataque %d" % attack)

func test_attack_event_says_when_it_was_a_critical() -> void:
	_walker(48.0)
	var unit = _rogue(1)
	var flags := []
	for attack in unit.stats().crit.every:
		_attack_once(unit)
		for event: Dictionary in sim.drain_events():
			if event.type == "attack":
				flags.append(event.crit)
	assert_false(flags[0])
	assert_true(flags[-1])

func test_critical_ignores_the_monster_resistance() -> void:
	var monster = sim.spawn_monster("brute")
	monster.distance = 48.0
	monster.hp = 100000
	var unit = _rogue(1)
	var stats: Dictionary = unit.stats()
	for attack in int(stats.crit.every) - 1:
		_attack_once(unit)
	var before: int = monster.hp
	_attack_once(unit)
	assert_eq(before - monster.hp, roundi(stats.damage * stats.crit.multiplier))

func test_level_3_kill_pays_extra_gold() -> void:
	var monster = _walker(48.0, 1)
	var unit = _rogue(3)
	var before: int = sim.gold
	_attack_once(unit)
	assert_eq(sim.gold, before + monster.gold + int(unit.stats().kill_gold))

func test_level_1_kill_pays_only_the_normal_gold() -> void:
	var monster = _walker(48.0, 1)
	var unit = _rogue(1)
	var before: int = sim.gold
	_attack_once(unit)
	assert_eq(sim.gold, before + monster.gold)

func test_other_classes_do_not_pay_the_extra_gold() -> void:
	var monster = _walker(48.0, 1)
	var unit = sim.place_unit("warrior", Vector2i(1, 1))
	var before: int = sim.gold
	_attack_once(unit)
	assert_eq(sim.gold, before + monster.gold)

func test_kill_event_carries_the_extra_gold() -> void:
	_walker(48.0, 1)
	var unit = _rogue(3)
	_attack_once(unit)
	var kills: Array = sim.drain_events().filter(func(e): return e.type == "monster_killed")
	assert_eq(kills[0].bonus_gold, int(unit.stats().kill_gold))

func test_match_log_counts_the_extra_gold_of_the_kill() -> void:
	sim = Fixtures.simulation([Fixtures.wave([Fixtures.group("goblin")])])
	sim.gold = 1000
	var log := MatchLog.new("x", "2026-11-06T10:00:00")
	sim.call_next_wave()
	sim.tick(0.01)
	var monster = sim.monsters[0]
	monster.distance = 48.0
	monster.hp = 1
	var unit = _rogue(3)
	log.consume(sim.drain_events(), sim)
	_attack_once(unit)
	log.consume(sim.drain_events(), sim)
	assert_eq(log.to_dict().waves[0].kill_gold, monster.gold + int(unit.stats().kill_gold))

func test_real_rogue_has_short_range_and_pierces() -> void:
	var units: Dictionary = GameData.load_catalog().units
	for level in 3:
		assert_lt(units.rogue.levels[level].range, units.archer.levels[level].range)
	assert_eq(units.rogue.damage_type, "pierce")
	assert_true(units.rogue.levels[2].has("kill_gold"))
	assert_false(units.rogue.levels[1].has("kill_gold"))
