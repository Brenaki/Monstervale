extends GutTest
## As partidas reais, jogadas de novo pela interface do jogo como a pessoa jogou.
## Toda partida em tests/fixtures/partidas entra sozinha na repetição geral.

const RecordedPlayer = preload("res://tests/e2e/recorded_player.gd")

const MATCHES_DIR := "res://tests/fixtures/partidas/"
const SAVE_PATH := "user://e2e_progress.json"
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
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"stars": {"0": 3}}))
	file.close()
	game = load("res://src/game/main.tscn").instantiate()
	game.progress_path = SAVE_PATH
	game.log_dir = LOG_DIR
	add_child_autofree(game)
	game.set_process(false)

func after_all() -> void:
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
