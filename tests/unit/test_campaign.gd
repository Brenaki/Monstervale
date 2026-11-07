extends GutTest

const Achievements = preload("res://src/core/achievements.gd")

const SAVE_PATH := "user://test_campaign_progress.json"
const SETTINGS_PATH := "user://test_campaign_settings.json"
const LOG_DIR := "user://test_campaign_partidas"

var game

func before_each() -> void:
	DirAccess.remove_absolute(SAVE_PATH)
	DirAccess.remove_absolute(SETTINGS_PATH)
	game = _new_game()

func after_all() -> void:
	DirAccess.remove_absolute(SAVE_PATH)
	DirAccess.remove_absolute(SETTINGS_PATH)

func _new_game():
	var scene = load("res://src/game/main.tscn").instantiate()
	scene.progress_path = SAVE_PATH
	scene.settings_path = SETTINGS_PATH
	scene.log_dir = LOG_DIR
	scene.tutorials_enabled = false
	add_child_autofree(scene)
	return scene

func _saved() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))

func test_without_a_save_the_title_offers_only_a_new_game() -> void:
	game._process(0.0)
	assert_eq(game.title.play_button.text, tr("BTN_NEW_GAME"))
	assert_false(game.title.new_game_button.visible)

func test_with_a_save_the_title_offers_continue_and_new_game() -> void:
	game.progress.record(0, 1)
	game._process(0.0)
	assert_eq(game.title.play_button.text, tr("BTN_RESUME"))
	assert_true(game.title.new_game_button.visible)

func test_new_game_asks_first_then_starts_over_from_level_one() -> void:
	game.progress.record(0, 3)
	game.progress.record(1, 2)
	game.progress.unlock("level_1")
	game.title.new_game_button.pressed.emit()
	assert_true(game.title.confirm_panel.visible)
	assert_eq(game.progress.stars_for(0), 3, "ainda não apagou")
	game.title.confirm_button.pressed.emit()
	assert_false(game.title.visible)
	assert_eq(game.level.id, "level_01")
	assert_false(game.progress.has_save())
	assert_false(game.progress.is_unlocked(1), "a fase 2 volta a esperar a fase 1")
	assert_true(game.progress.has_achievement("level_1"), "as conquistas ficam")
	assert_eq(_saved().stars, {})

func test_giving_up_on_a_new_game_keeps_everything() -> void:
	game.progress.record(0, 3)
	game.title.new_game_button.pressed.emit()
	game.title.confirm_back.pressed.emit()
	assert_false(game.title.confirm_panel.visible)
	assert_eq(game.progress.stars_for(0), 3)

func test_winning_a_level_unlocks_its_achievement_and_announces_it() -> void:
	game.start_level(0)
	game.finish_level("won", 2)
	assert_true(game.progress.has_achievement("level_1"))
	assert_has(game.hud.announced, tr("ACH_LEVEL_1"))
	assert_has(game.sounds.played, "achievement")
	assert_has(_saved().achievements, "level_1")

func test_help_from_dev_mode_earns_no_achievement() -> void:
	game.set_dev("dev_mode", true)
	game.set_dev("dev_infinite_gold", true)
	game.start_level(0)
	game.finish_level("won", 3)
	assert_false(game.progress.has_achievement("level_1"))

func test_slaying_the_slime_king_makes_a_hero() -> void:
	game.start_level(0)
	var king = game.sim.spawn_monster("slime_king")
	game.advance(game.STEP)
	king.hp = 1
	game.sim._damage(king, 10, "magic", "mage")
	game.advance(game.STEP)
	assert_true(game.progress.has_achievement(Achievements.HERO))

func test_the_campaign_clock_counts_every_match_since_the_new_game() -> void:
	game.title.play_button.pressed.emit()
	game.advance(30.0)
	game.restart()
	game.advance(20.0)
	game.finish_level("lost", 0)
	game.restart()
	assert_almost_eq(game.progress.campaign_seconds, 50.0, 0.1, "derrota e reinício contam, uma vez cada")
	assert_almost_eq(float(_saved().campaign_seconds), 50.0, 0.1)

func test_leaving_for_the_title_also_counts() -> void:
	game.title.play_button.pressed.emit()
	game.advance(12.0)
	game.show_title()
	assert_almost_eq(game.progress.campaign_seconds, 12.0, 0.1)

func test_turning_on_help_stops_the_clock_for_good() -> void:
	game.title.play_button.pressed.emit()
	game.set_dev("dev_mode", true)
	game.set_dev("dev_invincible", true)
	assert_false(game.progress.campaign_timed())

func test_a_fast_campaign_earns_the_speedrunner() -> void:
	for i in 4:
		game.progress.record(i, 3)
	game.progress.add_campaign_time(Achievements.SPEEDRUN_SECONDS - 60.0)
	game.start_level(4)
	game.advance(30.0)
	game.finish_level("won", 3)
	assert_true(game.progress.has_achievement("speedrunner"))

func test_a_slow_campaign_does_not() -> void:
	for i in 4:
		game.progress.record(i, 3)
	game.progress.add_campaign_time(Achievements.SPEEDRUN_SECONDS - 10.0)
	game.start_level(4)
	game.advance(30.0)
	game.finish_level("won", 3)
	assert_false(game.progress.has_achievement("speedrunner"))

func test_a_fast_campaign_without_all_the_stars_does_not() -> void:
	for i in 4:
		game.progress.record(i, 3)
	game.progress.add_campaign_time(Achievements.SPEEDRUN_SECONDS - 60.0)
	game.start_level(4)
	game.advance(30.0)
	game.finish_level("won", 2)
	assert_false(game.progress.has_achievement("speedrunner"))

func test_the_achievements_panel_lists_them_all() -> void:
	game.progress.unlock("hero")
	game.title.achievements_button.pressed.emit()
	game._process(0.0)
	assert_true(game.title.achievements_panel.visible)
	var hero: int = Achievements.IDS.find("hero")
	assert_eq(game.title.achievement_names.size(), Achievements.IDS.size())
	assert_eq(game.title.achievement_icons[hero].texture.region, game.title.UiKit.icon("trophy").region)
	assert_eq(game.title.achievement_icons[0].texture.region, game.title.UiKit.icon("lock").region)
	var speedrun: int = Achievements.IDS.find("speedrunner")
	assert_string_contains(game.title.achievement_descs[speedrun].text, "39:07")

func test_the_title_menu_fits_under_the_subtitle() -> void:
	game.progress.record(0, 1)
	game._process(0.0)
	var box: Control = game.title.play_button.get_parent()
	assert_gt(box.position.y, game.title.subtitle.position.y + game.title.subtitle.size.y)
	assert_lte(box.position.y + box.size.y, 356.0)
	var last: Button = game.title.quit_button
	assert_lte(last.position.y + last.size.y, box.size.y - 4.0)

func test_achievement_texts_fit_in_both_languages() -> void:
	game.progress.unlock("hero")
	for locale: String in ["pt_BR", "en"]:
		TranslationServer.set_locale(locale)
		game._process(0.0)
		var labels: Array = game.title.achievement_names + game.title.achievement_descs
		labels.append(game.title.campaign_label)
		for label: Label in labels:
			assert_lte(label.get_combined_minimum_size().x, label.size.x, "%s: '%s'" % [locale, label.text])
	TranslationServer.set_locale("pt_BR")

func test_an_old_save_shows_its_finished_levels_as_achievements() -> void:
	game.free()
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"stars": {"0": 3, "1": 3, "2": 3, "3": 3, "4": 3}}))
	file.close()
	game = _new_game()
	assert_true(game.progress.has_achievement("level_5"))
	assert_true(game.progress.has_achievement("hero_of_heroes"))
	assert_false(game.progress.campaign_timed(), "o tempo só conta depois de um Novo jogo")
