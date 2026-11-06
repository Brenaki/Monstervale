extends GutTest

const SAVE_PATH := "user://test_progress.json"
const FREE_CELL := Vector2i(7, 5)

var game

func before_each() -> void:
	DirAccess.remove_absolute(SAVE_PATH)
	game = load("res://src/game/main.tscn").instantiate()
	game.progress_path = SAVE_PATH
	add_child_autofree(game)

func after_all() -> void:
	DirAccess.remove_absolute(SAVE_PATH)

func _advance(seconds: float) -> void:
	game.advance(seconds)

func test_starts_with_level_gold() -> void:
	assert_eq(game.sim.gold, 150)

func test_selecting_a_class_then_clicking_places_a_unit() -> void:
	game.select_class("archer")
	game.cell_clicked(FREE_CELL)
	assert_eq(game.sim.units.size(), 1)
	assert_eq(game.selected_class, "", "volta ao modo normal depois de posicionar")

func test_selecting_the_same_class_cancels() -> void:
	game.select_class("archer")
	game.select_class("archer")
	assert_eq(game.selected_class, "")

func test_clicking_a_blocked_cell_keeps_the_class_selected() -> void:
	game.select_class("archer")
	game.cell_clicked(Vector2i(8, 5))
	assert_eq(game.sim.units.size(), 0)
	assert_eq(game.selected_class, "archer")

func test_clicking_a_unit_selects_it() -> void:
	game.select_class("archer")
	game.cell_clicked(FREE_CELL)
	game.cell_clicked(FREE_CELL)
	assert_eq(game.selected_unit, game.sim.units[0])

func test_clicking_empty_ground_clears_selection() -> void:
	game.select_class("archer")
	game.cell_clicked(FREE_CELL)
	game.cell_clicked(FREE_CELL)
	game.cell_clicked(Vector2i(2, 3))
	assert_null(game.selected_unit)

func test_upgrade_and_dismiss_act_on_the_selected_unit() -> void:
	game.select_class("archer")
	game.cell_clicked(FREE_CELL)
	game.cell_clicked(FREE_CELL)
	game.upgrade_selected()
	assert_eq(game.sim.units[0].level, 2)
	assert_eq(game.sim.gold, 60)
	game.dismiss_selected()
	assert_eq(game.sim.units.size(), 0)
	assert_null(game.selected_unit)
	assert_eq(game.sim.gold, 105)

func test_priority_button_changes_selected_unit() -> void:
	game.select_class("archer")
	game.cell_clicked(FREE_CELL)
	game.cell_clicked(FREE_CELL)
	game.cycle_priority()
	assert_eq(game.selected_unit.priority, "last")

func test_pause_stops_the_simulation() -> void:
	game.toggle_pause()
	var countdown: float = game.sim.next_wave_countdown
	_advance(1.0)
	assert_eq(game.sim.next_wave_countdown, countdown)
	game.toggle_pause()
	_advance(1.0)
	assert_lt(game.sim.next_wave_countdown, countdown)

func test_speed_doubles_simulated_time() -> void:
	var countdown: float = game.sim.next_wave_countdown
	game.toggle_speed()
	_advance(1.0)
	assert_almost_eq(countdown - game.sim.next_wave_countdown, 2.0, 0.05)
	game.toggle_speed()
	assert_eq(game.speed, 1)

func test_restart_resets_everything_without_penalty() -> void:
	game.select_class("archer")
	game.cell_clicked(FREE_CELL)
	game.call_wave()
	_advance(2.0)
	game.restart()
	assert_eq(game.sim.gold, 150)
	assert_eq(game.sim.units.size(), 0)
	assert_eq(game.sim.monsters.size(), 0)
	assert_eq(game.view_count(), 0)

func test_spawned_monster_gets_a_view_and_killed_loses_it() -> void:
	game.call_wave()
	_advance(0.1)
	assert_eq(game.view_count(), 1)
	game.sim.monsters[0].hp = 0
	game.sim.monsters.clear()
	game.restart()
	assert_eq(game.view_count(), 0)

func test_winning_saves_stars() -> void:
	game.finish_level("won", 2)
	var saved := FileAccess.get_file_as_string(SAVE_PATH)
	assert_string_contains(saved, "stars")
	var reopened = load("res://src/game/main.tscn").instantiate()
	reopened.progress_path = SAVE_PATH
	add_child_autofree(reopened)
	assert_eq(reopened.progress.stars_for(0), 2)
	assert_true(reopened.progress.is_unlocked(1))

func test_losing_saves_nothing() -> void:
	game.finish_level("lost", 0)
	assert_false(FileAccess.file_exists(SAVE_PATH))

func test_result_panel_appears_at_the_end_and_clears_on_restart() -> void:
	assert_false(game.hud.result_panel.visible)
	game.finish_level("won", 3)
	assert_true(game.hud.result_panel.visible)
	game.restart()
	assert_false(game.hud.result_panel.visible)

func test_hud_buttons_call_the_game() -> void:
	game.hud.pause_button.pressed.emit()
	assert_true(game.paused)
	game.hud.speed_button.pressed.emit()
	assert_eq(game.speed, 2)
	game.hud.class_buttons["warrior"].pressed.emit()
	assert_eq(game.selected_class, "warrior")

func test_every_level_class_has_a_button() -> void:
	for kind: String in game.sim.available_classes():
		assert_true(game.hud.class_buttons.has(kind), kind)

func test_language_toggle_switches_between_portuguese_and_english() -> void:
	TranslationServer.set_locale("pt_BR")
	assert_eq(tr("BTN_RESTART"), "Reiniciar")
	game.toggle_language()
	assert_eq(TranslationServer.get_locale(), "en")
	assert_eq(tr("BTN_RESTART"), "Restart")
	game.toggle_language()
	assert_eq(TranslationServer.get_locale(), "pt_BR")

func test_clicks_on_the_hud_rows_do_not_reach_the_map() -> void:
	var cell: Vector2i = game.world_to_cell(Vector2(100, 340))
	assert_eq(cell, Vector2i(3, 10))
	game.select_class("archer")
	game.cell_clicked(cell)
	assert_eq(game.sim.units.size(), 0)

func test_button_text_fits_in_both_languages() -> void:
	game.select_class("archer")
	game.cell_clicked(FREE_CELL)
	game.cell_clicked(FREE_CELL)
	for locale: String in ["pt_BR", "en"]:
		TranslationServer.set_locale(locale)
		game.hud.refresh(game)
		for button: Button in game.hud.all_buttons():
			button.clip_text = false
			var needed: float = button.get_combined_minimum_size().x
			assert_lte(needed, button.size.x, "%s: '%s'" % [locale, button.text.replace("\n", " ")])
