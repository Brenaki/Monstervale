extends GutTest

const Fixtures = preload("res://tests/unit/fixtures.gd")

func _run(sim, seconds: float, step: float = 0.1) -> void:
	var elapsed := 0.0
	while elapsed < seconds:
		sim.tick(step)
		elapsed += step

func test_waves_only_start_when_the_player_calls_them() -> void:
	var sim = Fixtures.simulation([Fixtures.wave([Fixtures.group("goblin")])])
	_run(sim, 60.0)
	assert_eq(sim.waves_started(), 0)
	assert_eq(sim.monsters.size(), 0)
	assert_true(sim.call_next_wave())
	sim.tick(0.01)
	assert_eq(sim.monsters.size(), 1)

func test_the_next_wave_also_waits_for_the_player() -> void:
	var sim = Fixtures.simulation([Fixtures.wave([Fixtures.group("goblin")]), Fixtures.wave([Fixtures.group("goblin")])])
	sim.call_next_wave()
	_run(sim, 60.0)
	assert_eq(sim.waves_started(), 1)

func test_bonus_runs_out_and_stays_at_zero() -> void:
	var sim = Fixtures.simulation([Fixtures.wave([Fixtures.group("goblin")])])
	_run(sim, 30.0)
	assert_eq(sim.next_wave_countdown, 0.0)
	assert_eq(sim.early_call_bonus(), 0)
	sim.call_next_wave()
	assert_eq(sim.gold, 100)

func test_group_spawns_at_its_interval() -> void:
	var sim = Fixtures.simulation([Fixtures.wave([Fixtures.group("goblin", 3, 1.0)])])
	sim.call_next_wave()
	sim.tick(0.01)
	assert_eq(sim.monsters.size(), 1)
	_run(sim, 1.05)
	assert_eq(sim.monsters.size(), 2)
	_run(sim, 1.05)
	assert_eq(sim.monsters.size(), 3)

func test_group_delay_postpones_the_first_spawn() -> void:
	var sim = Fixtures.simulation([Fixtures.wave([Fixtures.group("goblin", 1, 1.0, 2.0)])])
	sim.call_next_wave()
	_run(sim, 1.5)
	assert_eq(sim.monsters.size(), 0)
	_run(sim, 0.7)
	assert_eq(sim.monsters.size(), 1)

func test_calling_early_pays_gold_for_remaining_time() -> void:
	var sim = Fixtures.simulation([Fixtures.wave([Fixtures.group("goblin")])])
	_run(sim, 4.0)
	assert_true(sim.call_next_wave())
	assert_eq(sim.gold, 106, "6 segundos restantes a 1 ouro por segundo")

func test_cannot_call_while_a_wave_is_spawning() -> void:
	var sim = Fixtures.simulation([
		Fixtures.wave([Fixtures.group("goblin", 5, 1.0)]),
		Fixtures.wave([Fixtures.group("goblin")]),
	])
	assert_true(sim.call_next_wave())
	assert_false(sim.call_next_wave())

func test_cannot_call_after_the_last_wave() -> void:
	var sim = Fixtures.simulation([Fixtures.wave([Fixtures.group("goblin")])])
	assert_true(sim.call_next_wave())
	sim.tick(0.01)
	assert_false(sim.call_next_wave())

func test_preview_counts_monsters_of_next_wave() -> void:
	var sim = Fixtures.simulation([
		Fixtures.wave([Fixtures.group("goblin", 3), Fixtures.group("brute", 1), Fixtures.group("goblin", 2)]),
	])
	assert_eq(sim.next_wave_preview(), {"goblin": 5, "brute": 1})
	sim.call_next_wave()
	assert_eq(sim.next_wave_preview(), {})

func test_monster_walks_along_the_route() -> void:
	var sim = Fixtures.simulation([Fixtures.wave([Fixtures.group("goblin")])])
	sim.call_next_wave()
	sim.tick(0.01)
	_run(sim, 2.0)
	assert_almost_eq(sim.monsters[0].position().x, 20.0, 1.5)

func test_monster_reaching_the_end_costs_its_lives() -> void:
	var sim = Fixtures.simulation([Fixtures.wave([Fixtures.group("brute")])])
	sim.call_next_wave()
	_run(sim, 21.0)
	assert_eq(sim.monsters.size(), 0)
	assert_eq(sim.lives, 7)

func test_zero_lives_loses_the_level_and_stops_the_simulation() -> void:
	var sim = Fixtures.simulation([Fixtures.wave([Fixtures.group("brute", 4, 0.1)])])
	sim.call_next_wave()
	_run(sim, 21.5)
	assert_eq(sim.state, "lost")
	assert_eq(sim.lives, 0)
	var count: int = sim.monsters.size()
	_run(sim, 5.0)
	assert_eq(sim.monsters.size(), count)

func test_clearing_a_wave_pays_its_bonus_once() -> void:
	var sim = Fixtures.simulation([
		Fixtures.wave([Fixtures.group("goblin")], 25),
		Fixtures.wave([Fixtures.group("goblin")]),
	])
	sim.place_unit("archer", Vector2i(1, 1))
	sim.gold = 0
	sim.call_next_wave()
	sim.tick(0.01)
	sim.monsters[0].hp = 1
	_run(sim, 1.5)
	assert_eq(sim.gold, 38, "10 da chamada antecipada + 3 do abate + 25 do bônus")

func test_killing_every_monster_of_last_wave_wins() -> void:
	var sim = Fixtures.simulation([Fixtures.wave([Fixtures.group("goblin")])])
	sim.place_unit("archer", Vector2i(1, 1))
	sim.call_next_wave()
	sim.tick(0.01)
	sim.monsters[0].hp = 1
	_run(sim, 1.5)
	assert_eq(sim.state, "won")

func test_stars_follow_remaining_lives() -> void:
	var sim = Fixtures.simulation()
	var expected := {10: 3, 9: 3, 8: 2, 5: 2, 4: 1, 1: 1}
	for lives: int in expected:
		sim.lives = lives
		assert_eq(sim.stars(), expected[lives], "%d vidas" % lives)

func test_wave_counters_for_the_hud() -> void:
	var sim = Fixtures.simulation([Fixtures.wave([Fixtures.group("goblin")]), Fixtures.wave([Fixtures.group("goblin")])])
	assert_eq(sim.waves_started(), 0)
	assert_eq(sim.waves_total(), 2)
	sim.call_next_wave()
	assert_eq(sim.waves_started(), 1)
