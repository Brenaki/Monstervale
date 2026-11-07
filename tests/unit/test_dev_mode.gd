extends GutTest

const SAVE_PATH := "user://test_dev_progress.json"
const SETTINGS_PATH := "user://test_dev_settings.json"
const LOG_DIR := "user://test_dev_partidas"
const FREE_CELL := Vector2i(7, 5)

var game

func before_each() -> void:
	DirAccess.remove_absolute(SAVE_PATH)
	DirAccess.remove_absolute(SETTINGS_PATH)
	_clear_logs()

func after_all() -> void:
	DirAccess.remove_absolute(SAVE_PATH)
	DirAccess.remove_absolute(SETTINGS_PATH)
	_clear_logs()
	DirAccess.remove_absolute(LOG_DIR)

func _clear_logs() -> void:
	for file_name in DirAccess.get_files_at(LOG_DIR):
		DirAccess.remove_absolute("%s/%s" % [LOG_DIR, file_name])

func _logs() -> int:
	return DirAccess.get_files_at(LOG_DIR).size() if DirAccess.dir_exists_absolute(LOG_DIR) else 0

func _new_game(dev_build: bool):
	game = load("res://src/game/main.tscn").instantiate()
	game.progress_path = SAVE_PATH
	game.settings_path = SETTINGS_PATH
	game.log_dir = LOG_DIR
	game.start_on_title = false
	game.dev_build = dev_build
	add_child_autofree(game)
	return game

func _escape_goblin() -> void:
	var monster = game.sim.spawn_monster("goblin")
	monster.distance = game.sim.route.length
	game.advance(game.STEP)

func _play_a_little() -> void:
	game.select_class("archer")
	game.cell_clicked(FREE_CELL)

func test_players_never_see_dev_switches_nor_record_matches() -> void:
	_new_game(false)
	game.settings.dev_mode = true
	game.open_options()
	assert_eq(game.options.dev_switches(), [])
	assert_false(game.dev_active())
	_play_a_little()
	game.finish_level("lost", 0)
	assert_false(game.hud.log_button.visible)
	assert_eq(_logs(), 0)

func test_without_dev_mode_nothing_is_recorded_even_in_development() -> void:
	_new_game(true)
	_play_a_little()
	game.finish_level("lost", 0)
	assert_false(game.hud.log_button.visible)
	assert_eq(_logs(), 0)

func test_dev_mode_shows_its_other_switches_only_when_on() -> void:
	_new_game(true)
	game.open_options()
	assert_eq(game.options.dev_switches(), [game.options.dev_button])
	game.options.dev_button.pressed.emit()
	assert_true(game.dev_active())
	assert_true(game.hud.dev_badge.visible)
	assert_eq(game.options.dev_switches().size(), 4)
	for button: Button in game.options.dev_switches():
		assert_true(button.visible, button.name)

func test_dev_mode_records_matches_and_shows_the_report() -> void:
	_new_game(true)
	game.set_dev("dev_mode", true)
	_play_a_little()
	game.finish_level("lost", 0)
	assert_true(game.hud.log_button.visible)
	assert_eq(_logs(), 2, "um .md e um .json")

func test_recording_can_be_switched_off() -> void:
	_new_game(true)
	game.set_dev("dev_mode", true)
	game.open_options()
	game.options.record_button.pressed.emit()
	_play_a_little()
	game.finish_level("lost", 0)
	assert_eq(_logs(), 0)

func test_immortal_village_is_its_own_switch() -> void:
	_new_game(true)
	game.set_dev("dev_mode", true)
	_escape_goblin()
	assert_eq(game.sim.lives, game.sim.start_lives() - 1, "sem a chave a vila perde vida")
	game.open_options()
	game.options.invincible_button.pressed.emit()
	_escape_goblin()
	assert_eq(game.sim.lives, game.sim.start_lives() - 1)

func test_infinite_gold_is_its_own_switch() -> void:
	_new_game(true)
	game.set_dev("dev_mode", true)
	game.sim.gold = 0
	game._process(0.0)
	assert_eq(game.sim.gold, 0)
	game.set_dev("dev_infinite_gold", true)
	game._process(0.0)
	assert_eq(game.sim.gold, game.DEV_GOLD)

func test_switches_do_nothing_with_dev_mode_off() -> void:
	_new_game(true)
	game.set_dev("dev_invincible", true)
	game.set_dev("dev_infinite_gold", true)
	_escape_goblin()
	assert_lt(game.sim.lives, game.sim.start_lives())
	game.sim.gold = 0
	game._process(0.0)
	assert_eq(game.sim.gold, 0)

func test_switches_survive_a_restart_of_the_game() -> void:
	_new_game(true)
	game.set_dev("dev_mode", true)
	game.set_dev("dev_invincible", true)
	game.free()
	_new_game(true)
	assert_true(game.dev_active())
	assert_true(game.sim.invincible)

func test_a_win_with_help_gives_no_stars() -> void:
	_new_game(true)
	game.set_dev("dev_mode", true)
	game.set_dev("dev_infinite_gold", true)
	game.finish_level("won", 3)
	assert_eq(game.progress.stars_for(0), 0)

func test_a_fair_win_in_dev_mode_still_gives_stars() -> void:
	_new_game(true)
	game.set_dev("dev_mode", true)
	game.finish_level("won", 2)
	assert_eq(game.progress.stars_for(0), 2)

func test_result_buttons_stay_centered_without_the_report() -> void:
	_new_game(false)
	game.finish_level("won", 3)
	var panel: Control = game.hud.result_panel
	var left: float = game.hud.result_restart.position.x
	var right: float = panel.size.x - (game.hud.next_level_button.position.x + game.hud.next_level_button.size.x)
	assert_almost_eq(left, right, 1.0)

func test_options_panel_fits_every_dev_switch_on_screen() -> void:
	_new_game(true)
	game.set_dev("dev_mode", true)
	game.open_options()
	var box: Control = game.options.back_button.get_parent()
	assert_gte(box.position.y, 0.0)
	assert_lte(box.position.y + box.size.y, 360.0)
	assert_lte(game.options.back_button.position.y + game.options.back_button.size.y, box.size.y)
