extends GutTest

const MatchLog = preload("res://src/core/match_log.gd")
const Fixtures = preload("res://tests/unit/fixtures.gd")

var sim
var log

func before_each() -> void:
	TranslationServer.set_locale("pt_BR")
	sim = Fixtures.simulation([
		Fixtures.wave([Fixtures.group("goblin", 2, 0.5)], 7),
		Fixtures.wave([Fixtures.group("brute", 1)]),
	])
	sim.gold = 500
	log = MatchLog.new("level_x", "2026-11-06 10:00:00")

func _step(seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < seconds:
		sim.tick(0.05)
		log.consume(sim.drain_events(), sim)
		elapsed += 0.05

func _act() -> void:
	log.consume(sim.drain_events(), sim)

func test_new_log_has_no_activity() -> void:
	assert_false(log.has_activity())

func test_placing_a_unit_counts_as_activity() -> void:
	sim.place_unit("archer", Vector2i(1, 1))
	_act()
	assert_true(log.has_activity())

func test_actions_record_time_cell_gold_and_wave() -> void:
	_step(1.0)
	sim.place_unit("archer", Vector2i(1, 1))
	_act()
	var action: Dictionary = log.to_dict().actions[0]
	assert_eq(action.action, "place")
	assert_eq(action.unit, "archer")
	assert_eq(action.cell, [1, 1])
	assert_eq(action.gold_after, 460)
	assert_eq(action.wave, 0)
	assert_almost_eq(action.time, 1.0, 0.1)

func test_upgrade_and_dismiss_are_recorded() -> void:
	var unit = sim.place_unit("archer", Vector2i(1, 1))
	sim.upgrade_unit(unit)
	sim.dismiss_unit(unit)
	_act()
	var actions: Array = log.to_dict().actions.map(func(a): return a.action)
	assert_eq(actions, ["place", "upgrade", "dismiss"])
	assert_eq(log.to_dict().actions[1].level, 2)

func test_wave_records_start_state_and_defenders() -> void:
	sim.place_unit("archer", Vector2i(1, 1))
	sim.place_unit("archer", Vector2i(2, 1))
	_act()
	var gold: int = sim.gold
	_step(1.0)
	sim.call_next_wave()
	_act()
	var wave: Dictionary = log.to_dict().waves[0]
	assert_eq(wave.number, 1)
	assert_eq(wave.lives_start, 10)
	assert_eq(wave.gold_start, gold + wave.early_bonus)
	assert_eq(wave.defenders, {"archer 1": 2})

func test_early_call_records_bonus() -> void:
	_step(4.0)
	sim.call_next_wave()
	_act()
	var wave: Dictionary = log.to_dict().waves[0]
	assert_true(wave.called_early)
	assert_eq(wave.early_bonus, 6)

func test_wave_called_after_the_wait_records_no_bonus() -> void:
	_step(10.5)
	sim.call_next_wave()
	_act()
	assert_eq(log.to_dict().waves[0].early_bonus, 0)

func test_wave_counts_spawned_killed_and_kill_gold() -> void:
	sim.place_unit("archer", Vector2i(1, 1))
	sim.call_next_wave()
	_step(0.1)
	for monster in sim.monsters:
		monster.hp = 1
	_step(3.0)
	var wave: Dictionary = log.to_dict().waves[0]
	assert_eq(wave.spawned, {"goblin": 2})
	assert_eq(wave.killed, {"goblin": 2})
	assert_eq(wave.escaped, {})
	assert_eq(wave.kill_gold, 6)

func test_damage_is_credited_to_the_class_that_dealt_it() -> void:
	sim.place_unit("archer", Vector2i(1, 1))
	sim.call_next_wave()
	_step(0.1)
	assert_eq(log.to_dict().waves[0].damage, {"archer": 5})

func test_clearing_a_wave_records_end_state_and_bonus() -> void:
	sim.place_unit("archer", Vector2i(1, 1))
	sim.call_next_wave()
	_step(0.1)
	for monster in sim.monsters:
		monster.hp = 1
	_step(3.0)
	var wave: Dictionary = log.to_dict().waves[0]
	assert_eq(wave.bonus, 7)
	assert_gt(wave.cleared_at, wave.started_at)
	assert_eq(wave.lives_end, 10)
	assert_eq(wave.gold_end, sim.gold)

func test_escaped_monsters_count_lost_lives() -> void:
	sim.call_next_wave()
	_step(21.5)
	var wave: Dictionary = log.to_dict().waves[0]
	assert_eq(wave.escaped, {"goblin": 2})
	assert_eq(wave.lives_end, 8)

func test_units_down_are_counted_in_the_wave() -> void:
	var unit = sim.place_unit("warrior", Vector2i(1, 1))
	unit.hp = 1
	sim.call_next_wave()
	_step(2.0)
	assert_eq(log.to_dict().waves[0].units_down, 1)

func test_monsters_of_overlapping_waves_stay_in_their_own_wave() -> void:
	sim.call_next_wave()
	_step(1.0)
	sim.call_next_wave()
	_step(1.5)
	var waves: Array = log.to_dict().waves
	assert_eq(waves[0].spawned, {"goblin": 2})
	assert_eq(waves[1].spawned, {"brute": 1})

func test_finish_records_result_and_final_state() -> void:
	_step(2.0)
	log.finish("restarted", sim)
	var data: Dictionary = log.to_dict()
	assert_eq(data.result, "restarted")
	assert_eq(data.lives_final, 10)
	assert_eq(data.gold_final, sim.gold)
	assert_almost_eq(data.duration, 2.0, 0.1)

func test_won_match_records_stars() -> void:
	sim.lives = 8
	log.finish("won", sim)
	assert_eq(log.to_dict().stars, 2)

func test_lost_match_has_no_stars() -> void:
	log.finish("lost", sim)
	assert_eq(log.to_dict().stars, 0)

func test_log_survives_a_json_round_trip() -> void:
	sim.place_unit("archer", Vector2i(1, 1))
	sim.call_next_wave()
	_step(1.0)
	log.finish("restarted", sim)
	var restored = JSON.parse_string(JSON.stringify(log.to_dict()))
	assert_eq(restored.level, "level_x")
	assert_eq(restored.waves[0].number, 1.0)

func test_markdown_has_summary_and_a_notes_line_per_wave() -> void:
	sim.place_unit("archer", Vector2i(1, 1))
	_act()
	sim.call_next_wave()
	_step(0.1)
	log.finish("won", sim)
	var text: String = log.to_markdown()
	assert_string_contains(text, "# Partida: level_x")
	assert_string_contains(text, "- Resultado: Vitória (3 estrelas)")
	assert_string_contains(text, "## Preparação inicial")
	assert_string_contains(text, "Posicionou Arqueiro em (1, 1)")
	assert_string_contains(text, "## Onda 1")
	assert_string_contains(text, "- Defesa no início: Arqueiro nível 1 x1")
	assert_string_contains(text, "- Monstros:")
	assert_string_contains(text, "- Notas:")

func test_markdown_marks_a_wave_that_never_ended() -> void:
	sim.call_next_wave()
	_step(0.1)
	log.finish("restarted", sim)
	assert_string_contains(log.to_markdown(), "- Fim: não terminou")

func test_file_name_combines_date_and_level() -> void:
	assert_eq(log.file_stem(), "partida_2026-11-06_10-00-00_level_x")

func test_report_stays_in_portuguese_when_the_game_is_in_english() -> void:
	TranslationServer.set_locale("en")
	sim.place_unit("archer", Vector2i(1, 1))
	_act()
	sim.call_next_wave()
	_step(0.1)
	log.finish("restarted", sim)
	var text: String = log.to_markdown()
	TranslationServer.set_locale("pt_BR")
	assert_string_contains(text, "Posicionou Arqueiro")
	assert_string_contains(text, "Arqueiro nível 1 x1")
	assert_string_contains(text, "Monstros: Goblin x1")
	assert_false(text.contains("Archer"))
