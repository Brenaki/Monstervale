extends SceneTree
## Tira os prints da página do jogo repetindo as partidas aprovadas no jogo de verdade.
## Precisa de janela (sem --headless), porque captura o que foi desenhado:
##   godot --path . -s tools/render_promo.gd -- [pasta de saída] [locale]

const RecordedPlayer = preload("res://tests/e2e/recorded_player.gd")

const MATCHES_DIR := "res://tests/fixtures/partidas/"
const SAVE_PATH := "user://promo_progress.json"
const SETTINGS_PATH := "user://promo_settings.json"
const LOG_DIR := "user://promo_partidas"
const SCALE := 2
const TITLE_SECONDS := 9.0
## Partida e momentos (segundos de jogo) de cada print.
const SHOTS := [
	["partida_2026-11-06_13-21-26_level_01.json", [60.0, 160.0, 240.0]],
	["partida_2026-11-06_17-02-07_level_02.json", [120.0, 260.0, 340.0]],
	["partida_2026-11-06_21-21-02_level_03.json", [215.0, 400.0, 490.0]],
	["partida_2026-11-07_09-55-49_level_04.json", [240.0, 430.0, 560.0]],
	["partida_2026-11-07_12-12-05_level_05.json", [480.0, 610.0, 630.0, 650.0]],
]

var game
var _view: SubViewport
var out_dir := "res://promo/candidatos"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	var locale: String = args[1] if args.size() > 1 else "pt_BR"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var settings := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	settings.store_string(JSON.stringify({"music_volume": 0.0, "sfx_volume": 0.0, "locale": locale}))
	settings.close()
	# Fases liberadas, para cada partida abrir na fase dela.
	var save := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	save.store_string(JSON.stringify({"stars": {"0": 3, "1": 3, "2": 3, "3": 3}}))
	save.close()
	game = load("res://src/game/main.tscn").instantiate()
	game.progress_path = SAVE_PATH
	game.settings_path = SETTINGS_PATH
	game.log_dir = LOG_DIR
	game.tutorials_enabled = false
	# Um viewport do tamanho do jogo: o print não depende do tamanho da janela.
	_view = SubViewport.new()
	_view.size = Vector2i(640, 360)
	_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_view)
	_view.add_child(game)
	_run.call_deferred()


func _run() -> void:
	# Título com os monstros já andando pela estrada.
	for i in int(TITLE_SECONDS / game.STEP):
		game.title._process(game.STEP)
	game._process(0.0)
	await _capture("00_titulo")
	for shot: Array in SHOTS:
		var report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MATCHES_DIR + shot[0]))
		game.start_level(game.LEVEL_IDS.find(report.level))
		var player := RecordedPlayer.new(game, report)
		for moment: float in shot[1]:
			while game.sim.state == "playing" and game.sim.elapsed < moment:
				player.step()
			await _capture("%s_%03d" % [report.level, int(moment)])
	_clean_up()
	quit()


func _capture(file_name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := _view.get_texture().get_image()
	image.resize(image.get_width() * SCALE, image.get_height() * SCALE, Image.INTERPOLATE_NEAREST)
	image.save_png("%s/%s.png" % [out_dir, file_name])
	print("print: %s/%s.png" % [out_dir, file_name])


func _clean_up() -> void:
	DirAccess.remove_absolute(SAVE_PATH)
	DirAccess.remove_absolute(SETTINGS_PATH)
	for file_name in DirAccess.get_files_at(LOG_DIR):
		DirAccess.remove_absolute("%s/%s" % [LOG_DIR, file_name])
	DirAccess.remove_absolute(LOG_DIR)
