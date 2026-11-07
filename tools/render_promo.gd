extends SceneTree
## Gera as imagens da página do jogo a partir do jogo de verdade: os prints repetem as partidas
## aprovadas, a tela de abertura é o título sem o menu e a capa recorta a luta contra o Rei Slime.
## Precisa de janela (sem --headless), porque captura o que foi desenhado:
##   godot --path . -s tools/render_promo.gd -- [locale]

const RecordedPlayer = preload("res://tests/e2e/recorded_player.gd")
const UiKit = preload("res://src/game/ui_kit.gd")
const TitleScreen = preload("res://src/game/title_screen.gd")

const MATCHES_DIR := "res://tests/fixtures/partidas/"
const SAVE_PATH := "user://promo_progress.json"
const SETTINGS_PATH := "user://promo_settings.json"
const LOG_DIR := "user://promo_partidas"
const PRINTS_DIR := "res://promo/%s"
const SPLASH_PATH := "res://assets/branding/splash.png"
const COVER_PATH := "res://promo/capa.png"
const SCREEN := Vector2i(640, 360)
const SCALE := 2
const TITLE_SECONDS := 9.0
## Os efeitos somem por tween, em tempo real: o último segundo antes do print roda em tempo real,
## senão os efeitos de minutos de partida avançada de uma vez ficariam todos na tela.
const LIVE_SECONDS := 1.0
## Partida, momento (segundos de jogo) e nome de cada print.
const SHOTS := [
	["partida_2026-11-06_13-21-26_level_01.json", 240.0, "02_fase_1"],
	["partida_2026-11-06_17-02-07_level_02.json", 260.0, "03_fase_2"],
	["partida_2026-11-06_21-21-02_level_03.json", 400.0, "04_fase_3"],
	["partida_2026-11-07_09-55-49_level_04.json", 430.0, "05_fase_4"],
	["partida_2026-11-07_12-12-05_level_05.json", 630.0, "06_rei_slime"],
]
const COVER_SHOT := "06_rei_slime"
## A capa tem 630x500: um recorte da cena sem HUD, ampliado 2x, com o logo por cima.
const COVER_CROP := Rect2i(80, 50, 315, 250)
const COVER_LOGO_Y := 10.0
const COVER_BAND := Color(0.106, 0.086, 0.149, 0.7)
const COVER_BAND_HEIGHT := 60.0
## O mapa tem 352 px de altura; na tela de abertura a faixa de baixo repete a grama de cima.
const MAP_HEIGHT := 352
const TILE := 16

var game
var _view: SubViewport
var _prints_dir: String


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var locale: String = args[0] if args.size() > 0 else "pt_BR"
	_prints_dir = PRINTS_DIR % locale
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_prints_dir))
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
	# Um viewport do tamanho do jogo: a imagem não depende do tamanho da janela.
	_view = _viewport(SCREEN)
	_view.add_child(game)
	_run.call_deferred()


func _run() -> void:
	# Título com os monstros já andando pela estrada.
	for i in int(TITLE_SECONDS / game.STEP):
		game.title._process(game.STEP)
	game._process(0.0)
	_save(await _grab(_view), "%s/01_titulo.png" % _prints_dir)
	# A tela de abertura vale para qualquer idioma: só o logo e a estrada.
	game.title._menu.visible = false
	game.title.subtitle.visible = false
	var splash := await _grab(_view)
	var strip := SCREEN.y - MAP_HEIGHT
	splash.blit_rect(splash, Rect2i(0, MAP_HEIGHT - TILE, SCREEN.x, strip), Vector2i(0, MAP_HEIGHT))
	_save(splash, SPLASH_PATH)
	game.title._menu.visible = true
	game.title.subtitle.visible = true
	for shot: Array in SHOTS:
		var report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MATCHES_DIR + shot[0]))
		game.start_level(game.LEVEL_IDS.find(report.level))
		var player := RecordedPlayer.new(game, report)
		while game.sim.state == "playing" and game.sim.elapsed < shot[1] - LIVE_SECONDS:
			player.step()
		_clear_leftovers()
		while game.sim.state == "playing" and game.sim.elapsed < shot[1]:
			await process_frame
		_save(await _grab(_view), "%s/%s.png" % [_prints_dir, shot[2]])
		if shot[2] == COVER_SHOT:
			game.hud.visible = false
			var scene := await _grab(_view)
			game.hud.visible = true
			_save(await _cover(scene), COVER_PATH)
	_clean_up()
	quit()


## Efeitos e corpos de monstros mortos somem por tween em tempo real; no avanço rápido ficariam
## todos na tela ao mesmo tempo.
func _clear_leftovers() -> void:
	for effect in game._effects.get_children():
		effect.queue_free()
	var alive: Array = game._views.values()
	for view in game._entities.get_children():
		if view not in alive:
			view.queue_free()


func _cover(scene: Image) -> Image:
	var cover := _viewport(COVER_CROP.size)
	var picture := TextureRect.new()
	picture.texture = ImageTexture.create_from_image(scene.get_region(COVER_CROP))
	cover.add_child(picture)
	var band := ColorRect.new()
	band.color = COVER_BAND
	band.size = Vector2(COVER_CROP.size.x, COVER_BAND_HEIGHT)
	cover.add_child(band)
	var text := Control.new()
	text.theme = UiKit.theme()
	text.size = Vector2(COVER_CROP.size)
	cover.add_child(text)
	var logo := UiKit.label(text, Rect2(0, COVER_LOGO_Y, COVER_CROP.size.x / TitleScreen.LOGO_SCALE, 12))
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.scale = Vector2.ONE * TitleScreen.LOGO_SCALE
	logo.add_theme_color_override("font_color", TitleScreen.LOGO_COLOR)
	logo.text = tr("TITLE_NAME")
	var image := await _grab(cover)
	cover.queue_free()
	return image


func _viewport(size: Vector2i) -> SubViewport:
	var view := SubViewport.new()
	view.size = size
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	return view


func _grab(view: SubViewport) -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return view.get_texture().get_image()


func _save(image: Image, path: String) -> void:
	image.resize(image.get_width() * SCALE, image.get_height() * SCALE, Image.INTERPOLATE_NEAREST)
	image.save_png(path)
	print("imagem: %s" % path)


func _clean_up() -> void:
	DirAccess.remove_absolute(SAVE_PATH)
	DirAccess.remove_absolute(SETTINGS_PATH)
	for file_name in DirAccess.get_files_at(LOG_DIR):
		DirAccess.remove_absolute("%s/%s" % [LOG_DIR, file_name])
	DirAccess.remove_absolute(LOG_DIR)
