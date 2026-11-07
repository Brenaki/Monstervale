extends GutTest
## As partidas reais, jogadas de novo pela interface do jogo como a pessoa jogou.
## Toda partida em tests/fixtures/partidas entra sozinha na repetição geral.

const RecordedPlayer = preload("res://tests/e2e/recorded_player.gd")

const MATCHES_DIR := "res://tests/fixtures/partidas/"
const SAVE_PATH := "user://e2e_progress.json"
const SETTINGS_PATH := "user://test_settings.json"
const LOG_DIR := "user://e2e_partidas"
const FRAMES_BETWEEN_YIELDS := 120
const MAX_SECONDS := 1800.0
const APPROVED_LEVEL_1 := "partida_2026-11-06_13-21-26_level_01.json"
const EASY_LEVEL_2 := "partida_2026-11-06_14-38-38_level_02.json"
const HARD_LEVEL_2 := "partida_2026-11-06_16-11-59_level_02.json"
const LOST_LEVEL_2 := "partida_2026-11-06_16-58-07_level_02.json"
const APPROVED_LEVEL_2 := "partida_2026-11-06_17-02-07_level_02.json"
const SPARE_CELLS_LEVEL_2 := [
	Vector2i(7, 3), Vector2i(6, 2), Vector2i(7, 2), Vector2i(2, 5), Vector2i(2, 3), Vector2i(2, 6), Vector2i(7, 4),
]
const APPROVED_LEVEL_3 := "partida_2026-11-06_21-21-02_level_03.json"
const LEVEL_3_THREE_STARS := "partida_2026-11-06_20-23-07_level_03.json"
const LEVEL_3_FAR := "partida_2026-11-06_19-38-14_level_03.json"
const LEVEL_3_LATE_MAGE := "partida_2026-11-06_19-42-38_level_03.json"
const LEVEL_3_EARLY := "partida_2026-11-06_18-34-17_level_03.json"
const SPARE_CELLS_LEVEL_3 := [
	Vector2i(9, 5), Vector2i(10, 5), Vector2i(12, 7), Vector2i(12, 3), Vector2i(11, 7), Vector2i(10, 3), Vector2i(9, 7), Vector2i(8, 5),
]
const APPROVED_LEVEL_4 := "partida_2026-11-07_09-55-49_level_04.json"
const LEVEL_4_PIERCE := "partida_2026-11-07_09-17-17_level_04.json"
const LEVEL_4_PIERCE_2 := "partida_2026-11-07_09-21-02_level_04.json"
const SPARE_CELLS_LEVEL_4 := [
	Vector2i(12, 2), Vector2i(14, 7), Vector2i(15, 6), Vector2i(11, 2), Vector2i(10, 7), Vector2i(12, 7), Vector2i(12, 3),
]
const APPROVED_LEVEL_5 := "partida_2026-11-07_12-12-05_level_05.json"
const THREE_STAR_LIVES := 18
const TWO_STAR_LIVES := 10
const WAVE_FIELDS := ["spawned", "killed", "escaped", "units_down", "lives_end", "gold_end"]

var game
var gut_layer: CanvasLayer

## A janela do GUT cobre parte da tela e tomaria os cliques destinados ao jogo.
func before_all() -> void:
	gut_layer = get_tree().root.find_child("GutLayer", true, false)
	gut_layer.visible = false
	get_window().size = Vector2i(640, 360)

func before_each() -> void:
	DirAccess.remove_absolute(SETTINGS_PATH)
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"stars": {"0": 3, "1": 3, "2": 3, "3": 3}}))
	file.close()
	game = load("res://src/game/main.tscn").instantiate()
	game.progress_path = SAVE_PATH
	game.settings_path = SETTINGS_PATH
	game.start_on_title = false
	game.tutorials_enabled = false
	game.log_dir = LOG_DIR
	add_child_autofree(game)
	# Só o modo dev registra partidas, e estes testes leem os relatórios.
	game.set_dev("dev_mode", true)
	game.set_process(false)

func after_all() -> void:
	DirAccess.remove_absolute(SETTINGS_PATH)
	gut_layer.visible = true
	DirAccess.remove_absolute(SAVE_PATH)
	for file_name in DirAccess.get_files_at(LOG_DIR):
		DirAccess.remove_absolute("%s/%s" % [LOG_DIR, file_name])
	DirAccess.remove_absolute(LOG_DIR)

func _report(file_name: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(MATCHES_DIR + file_name))

func _play(report: Dictionary, reinvest_cells: Array = []) -> RecordedPlayer:
	var player := RecordedPlayer.new(game, report)
	player.reinvest_cells = reinvest_cells
	player.open_level()
	var frames := 0
	while not player.is_done() and game.sim.elapsed < MAX_SECONDS:
		player.step()
		frames += 1
		if frames % FRAMES_BETWEEN_YIELDS == 0:
			await get_tree().process_frame
	return player

func _saved_report() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(game.last_log_path.replace(".md", ".json")))

func test_every_recorded_match_can_be_clicked_through_the_interface() -> void:
	var files := Array(DirAccess.get_files_at(MATCHES_DIR)).filter(func(f): return f.ends_with(".json"))
	assert_gt(files.size(), 0)
	for file_name: String in files:
		var report := _report(file_name)
		game.restart()
		game.open_level(game.LEVEL_IDS.find(report.level))
		var player: RecordedPlayer = await _play(report)
		assert_eq(player.failed_clicks, [], file_name)

func _assert_repeats_exactly(file_name: String) -> void:
	var report := _report(file_name)
	var player: RecordedPlayer = await _play(report)
	assert_eq(player.failed_clicks, [])
	assert_eq(player.pending_actions(), 0)
	var saved := _saved_report()
	assert_eq(saved.result, report.result)
	assert_eq(saved.stars, report.stars)
	assert_eq(saved.lives_final, report.lives_final)
	assert_eq(saved.gold_final, report.gold_final)
	assert_eq(saved.waves.size(), report.waves.size())
	for i in report.waves.size():
		for field: String in WAVE_FIELDS:
			assert_eq(saved.waves[i][field], report.waves[i][field], "onda %d, %s" % [i + 1, field])

func test_level_1_approved_match_repeats_exactly() -> void:
	await _assert_repeats_exactly(APPROVED_LEVEL_1)

func test_level_2_approved_match_repeats_exactly() -> void:
	await _assert_repeats_exactly(APPROVED_LEVEL_2)

func test_level_3_approved_match_repeats_exactly() -> void:
	await _assert_repeats_exactly(APPROVED_LEVEL_3)

func test_level_3_three_star_match_repeats_exactly() -> void:
	await _assert_repeats_exactly(LEVEL_3_THREE_STARS)

func test_level_2_match_with_a_late_mage_still_loses() -> void:
	await _play(_report(LOST_LEVEL_2))
	assert_eq(game.sim.state, "lost")

func test_level_2_easy_match_no_longer_earns_three_stars() -> void:
	await _play(_report(EASY_LEVEL_2))
	assert_true(game.sim.state != "won" or game.sim.lives < THREE_STAR_LIVES, "terminou %s com %d vidas" % [game.sim.state, game.sim.lives])

## Nessa partida, a defesa evoluída perdeu nas duas últimas ondas e a fase pareceu impossível.
func test_level_2_hard_fought_match_wins_without_three_stars() -> void:
	var player: RecordedPlayer = await _play(_report(HARD_LEVEL_2))
	assert_eq(player.failed_clicks, [])
	assert_eq(game.sim.state, "won", "terminou com %d vidas" % game.sim.lives)
	assert_lt(game.sim.lives, THREE_STAR_LIVES)

func test_level_2_reacting_to_the_pressure_wins_with_more_lives() -> void:
	var report := _report(EASY_LEVEL_2)
	var player: RecordedPlayer = await _play(report, SPARE_CELLS_LEVEL_2)
	assert_eq(player.failed_clicks, [])
	assert_eq(game.sim.state, "won")
	assert_gte(game.sim.lives, TWO_STAR_LIVES)

func test_menu_works_with_real_mouse_clicks() -> void:
	var player := RecordedPlayer.new(game, _report(EASY_LEVEL_2))
	var locale := TranslationServer.get_locale()
	player.click(game.hud.menu_button)
	assert_true(game.hud.menu_panel.visible)
	assert_true(game.paused)
	player.click(game.hud.options_button)
	assert_true(game.options.visible)
	player.click(game.options.language_button)
	assert_ne(TranslationServer.get_locale(), locale)
	TranslationServer.set_locale(locale)
	player.click(game.options.back_button)
	assert_false(game.options.visible)
	player.click(game.hud.menu_resume)
	assert_false(game.hud.menu_panel.visible)
	assert_false(game.paused)

func test_levels_panel_opens_from_the_menu_and_closes_with_real_mouse_clicks() -> void:
	var player := RecordedPlayer.new(game, _report(EASY_LEVEL_2))
	player.click(game.hud.menu_button)
	player.click(game.hud.levels_button)
	assert_true(game.hud.levels_panel.visible)
	player.click(game.hud.levels_close)
	assert_false(game.hud.levels_panel.visible)
	assert_true(game.hud.menu_panel.visible, "volta ao menu de onde saiu")
	player.click(game.hud.menu_resume)
	assert_false(game.paused)

func test_title_and_main_menu_work_with_real_mouse_clicks() -> void:
	var player := RecordedPlayer.new(game, _report(EASY_LEVEL_2))
	player.click(game.hud.menu_button)
	player.click(game.hud.main_menu_button)
	assert_true(game.title.visible)
	player.click(game.title.options_button)
	var volume: float = game.settings.music_volume
	player.click(game.options.music_up)
	assert_almost_eq(game.settings.music_volume, minf(volume + 0.1, 1.0), 0.001)
	player.click(game.options.back_button)
	player.click(game.title.play_button)
	assert_false(game.title.visible)
	assert_true(game.hud.visible)
	assert_false(game.paused)

## Repete a partida gastando o ouro que sobra, como quem reage à dificuldade.
func _play_reacting(file_name: String) -> void:
	var report := _report(file_name)
	report.result = "lost"
	await _play(report, SPARE_CELLS_LEVEL_3)

func test_level_3_can_still_earn_three_stars() -> void:
	await _play_reacting(LEVEL_3_FAR)
	assert_eq(game.sim.state, "won")
	assert_gte(game.sim.lives, THREE_STAR_LIVES)

func test_level_3_early_attempt_can_also_earn_three_stars() -> void:
	await _play_reacting(LEVEL_3_EARLY)
	assert_eq(game.sim.state, "won")
	assert_gte(game.sim.lives, THREE_STAR_LIVES)

func test_level_3_late_mage_wins_but_costs_lives() -> void:
	await _play_reacting(LEVEL_3_LATE_MAGE)
	assert_eq(game.sim.state, "won")
	assert_lt(game.sim.lives, THREE_STAR_LIVES)

func test_level_3_is_lost_when_the_spare_gold_is_not_spent() -> void:
	await _play(_report(LEVEL_3_FAR))
	assert_eq(game.sim.state, "lost")

func test_level_3_new_classes_work_with_real_mouse_clicks() -> void:
	var report := {
		"level": "level_03", "result": "closed", "duration": 12.0, "waves": [],
		"actions": [
			{"action": "place", "unit": "spearman", "cell": [12, 5], "time": 0.5, "wave": 0},
			{"action": "place", "unit": "druid", "cell": [11, 5], "time": 1.0, "wave": 0},
			{"action": "upgrade", "cell": [12, 5], "time": 10.0, "wave": 0},
		],
	}
	game.sim.gold = 500
	var player: RecordedPlayer = await _play(report)
	assert_eq(player.failed_clicks, [])
	assert_eq(player.pending_actions(), 0)
	assert_eq(game.sim.unit_at(Vector2i(12, 5)).kind, "spearman")
	assert_eq(game.sim.unit_at(Vector2i(12, 5)).level, 2)
	assert_eq(game.sim.unit_at(Vector2i(11, 5)).kind, "druid")

## A partida aprovada perdeu 4 vidas na última onda, que depois encolheu.
func test_level_4_approved_match_now_earns_three_stars() -> void:
	var player: RecordedPlayer = await _play(_report(APPROVED_LEVEL_4))
	assert_eq(player.failed_clicks, [])
	assert_eq(game.sim.state, "won")
	assert_gte(game.sim.lives, THREE_STAR_LIVES)

func test_level_4_restarted_attempt_wins_when_reacting() -> void:
	var report := _report(LEVEL_4_PIERCE)
	report.result = "lost"
	await _play(report, SPARE_CELLS_LEVEL_4)
	assert_eq(game.sim.state, "won")

## Ladino, lanceiro e guerreiro sem melhorar quase não ferem os esqueletos.
func test_level_4_piercing_defense_without_reacting_loses() -> void:
	var report := _report(LEVEL_4_PIERCE_2)
	report.result = "lost"
	await _play(report)
	assert_eq(game.sim.state, "lost")

func test_level_5_approved_match_repeats_exactly() -> void:
	await _assert_repeats_exactly(APPROVED_LEVEL_5)

func test_level_4_new_classes_work_with_real_mouse_clicks() -> void:
	var report := {
		"level": "level_04", "result": "closed", "duration": 12.0, "waves": [],
		"actions": [
			{"action": "place", "unit": "monk", "cell": [12, 5], "time": 0.5, "wave": 0},
			{"action": "place", "unit": "rogue", "cell": [12, 2], "time": 1.0, "wave": 0},
			{"action": "upgrade", "cell": [12, 5], "time": 10.0, "wave": 0},
		],
	}
	game.sim.gold = 500
	var player: RecordedPlayer = await _play(report)
	assert_eq(player.failed_clicks, [])
	assert_eq(player.pending_actions(), 0)
	assert_eq(game.sim.unit_at(Vector2i(12, 5)).kind, "monk")
	assert_eq(game.sim.unit_at(Vector2i(12, 5)).level, 2)
	assert_eq(game.sim.unit_at(Vector2i(12, 2)).kind, "rogue")
