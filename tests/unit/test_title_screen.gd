extends GutTest

const Settings = preload("res://src/core/settings.gd")
const UiKit = preload("res://src/game/ui_kit.gd")

const SAVE_PATH := "user://test_title_progress.json"
const SETTINGS_PATH := "user://test_title_settings.json"
const LOG_DIR := "user://test_title_partidas"

var game
var _locale: String

func before_each() -> void:
	_locale = TranslationServer.get_locale()
	DirAccess.remove_absolute(SAVE_PATH)
	DirAccess.remove_absolute(SETTINGS_PATH)
	game = _new_game()

func after_each() -> void:
	TranslationServer.set_locale(_locale)

func after_all() -> void:
	DirAccess.remove_absolute(SAVE_PATH)
	DirAccess.remove_absolute(SETTINGS_PATH)
	for file_name in DirAccess.get_files_at(LOG_DIR):
		DirAccess.remove_absolute("%s/%s" % [LOG_DIR, file_name])
	DirAccess.remove_absolute(LOG_DIR)

func _new_game():
	var scene = load("res://src/game/main.tscn").instantiate()
	scene.progress_path = SAVE_PATH
	scene.settings_path = SETTINGS_PATH
	scene.log_dir = LOG_DIR
	add_child_autofree(scene)
	return scene

func _save_progress(stars: Dictionary) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"stars": stars}))
	file.close()

func test_the_game_opens_on_the_title_with_the_match_hidden_and_paused() -> void:
	assert_true(game.title.visible)
	assert_false(game.hud.visible)
	assert_true(game.paused)

func test_monsters_walk_across_the_map_behind_the_title() -> void:
	for i in 120:
		game.title._process(1.0 / 30.0)
	assert_gt(game.title.walker_count(), 0)

func test_play_starts_the_furthest_level() -> void:
	game.free()
	_save_progress({"0": 2})
	game = _new_game()
	game.title.play_button.pressed.emit()
	assert_false(game.title.visible)
	assert_true(game.hud.visible)
	assert_false(game.paused)
	assert_eq(game.level.id, "level_02")
	assert_eq(game.title.walker_count(), 0, "o fundo do título some")

func test_play_reads_continue_once_there_is_progress() -> void:
	game._process(0.0)
	assert_eq(game.title.play_button.text, tr("BTN_NEW_GAME"))
	game.progress.record(0, 1)
	game._process(0.0)
	assert_eq(game.title.play_button.text, tr("BTN_RESUME"))

func test_levels_list_shows_stars_and_locks() -> void:
	game.progress.record(0, 2)
	game._process(0.0)
	assert_false(game.title.level_buttons[1].disabled)
	assert_true(game.title.level_buttons[2].disabled)
	var stars: Array = game.title.level_stars[0]
	var lit := stars.filter(func(star): return star.texture != null and star.texture.region == UiKit.icon("star").region)
	assert_eq(lit.size(), 2)

func test_choosing_a_level_on_the_title_starts_it() -> void:
	game.progress.record(0, 1)
	game.title.levels_button.pressed.emit()
	assert_true(game.title.levels_panel.visible)
	game.title.level_buttons[1].pressed.emit()
	assert_false(game.title.visible)
	assert_eq(game.level.id, "level_02")

func test_map_clicks_do_nothing_while_the_title_is_up() -> void:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = game.sim.cell_center(Vector2i(7, 5))
	game.selected_class = "archer"
	game._unhandled_input(click)
	assert_eq(game.sim.units.size(), 0)

func test_volume_buttons_change_the_bus_and_are_saved() -> void:
	game.title.options_button.pressed.emit()
	assert_true(game.options.visible)
	var before: float = game.settings.music_volume
	game.options.music_down.pressed.emit()
	assert_almost_eq(game.settings.music_volume, before - 0.1, 0.001)
	var bus := AudioServer.get_bus_index("Music")
	assert_almost_eq(AudioServer.get_bus_volume_db(bus), Settings.volume_db(before - 0.1), 0.01)
	var saved = JSON.parse_string(FileAccess.get_file_as_string(SETTINGS_PATH))
	assert_almost_eq(float(saved.music_volume), before - 0.1, 0.001)

func test_effects_volume_has_its_own_bus() -> void:
	game.open_options()
	for i in 10:
		game.options.sfx_down.pressed.emit()
	assert_eq(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Sfx")), Settings.SILENCE_DB)
	assert_gt(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")), Settings.SILENCE_DB)

func test_volume_bar_lights_one_segment_per_tenth() -> void:
	game.settings.music_volume = 0.3
	game.open_options()
	var lit: Array = game.options.music_bar.filter(func(segment): return segment.color == game.options.VOLUME_ON)
	assert_eq(lit.size(), 3)

func test_language_choice_survives_a_restart_of_the_game() -> void:
	TranslationServer.set_locale("pt_BR")
	game.open_options()
	game.options.language_button.pressed.emit()
	assert_eq(TranslationServer.get_locale(), "en")
	TranslationServer.set_locale("pt_BR")
	game.free()
	game = _new_game()
	assert_eq(TranslationServer.get_locale(), "en")

func test_title_and_options_text_fits_in_both_languages() -> void:
	game.open_options()
	for locale: String in ["pt_BR", "en"]:
		TranslationServer.set_locale(locale)
		game._process(0.0)
		game.options.refresh()
		var buttons: Array = game.title.all_buttons()
		buttons.append_array(game.options.all_buttons())
		for button: Button in buttons:
			button.clip_text = false
			assert_lte(button.get_combined_minimum_size().x, button.size.x, "%s: '%s'" % [locale, button.text])

func test_the_game_is_called_monstervale() -> void:
	game._process(0.0)
	assert_eq(game.title.logo.text, "Monstervale")
	assert_eq(ProjectSettings.get_setting("application/config/name"), "Monstervale")
