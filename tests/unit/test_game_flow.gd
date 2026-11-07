extends GutTest

const GameData = preload("res://src/core/game_data.gd")

const SAVE_PATH := "user://test_progress.json"
const LOG_DIR := "user://test_partidas"
const FREE_CELL := Vector2i(7, 5)
const START_GOLD := 120

var game

func before_each() -> void:
	DirAccess.remove_absolute(SAVE_PATH)
	game = load("res://src/game/main.tscn").instantiate()
	game.progress_path = SAVE_PATH
	game.log_dir = LOG_DIR
	_clear_logs()
	add_child_autofree(game)

func after_all() -> void:
	DirAccess.remove_absolute(SAVE_PATH)
	_clear_logs()
	DirAccess.remove_absolute(LOG_DIR)

func _clear_logs() -> void:
	for file_name in DirAccess.get_files_at(LOG_DIR):
		DirAccess.remove_absolute("%s/%s" % [LOG_DIR, file_name])

func _advance(seconds: float) -> void:
	game.advance(seconds)

func test_starts_with_level_gold() -> void:
	assert_eq(game.sim.gold, START_GOLD)

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
	assert_eq(game.sim.gold, START_GOLD - 105)
	game.dismiss_selected()
	assert_eq(game.sim.units.size(), 0)
	assert_null(game.selected_unit)
	assert_eq(game.sim.gold, START_GOLD - 53)

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
	assert_eq(game.sim.gold, START_GOLD)
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
	reopened.log_dir = LOG_DIR
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

func test_menu_pauses_and_resume_continues() -> void:
	game.hud.menu_button.pressed.emit()
	assert_true(game.paused)
	assert_true(game.hud.menu_panel.visible)
	game.hud.menu_resume.pressed.emit()
	assert_false(game.paused)
	assert_false(game.hud.menu_panel.visible)

func test_menu_gathers_resume_restart_language_and_quit() -> void:
	for button: Button in [game.hud.menu_resume, game.hud.restart_button, game.hud.language_button, game.hud.quit_button]:
		assert_true(game.hud.menu_panel.is_ancestor_of(button), button.name)

func test_restart_from_the_menu_closes_it_and_starts_over() -> void:
	game.select_class("archer")
	game.cell_clicked(FREE_CELL)
	game.hud.menu_button.pressed.emit()
	game.hud.restart_button.pressed.emit()
	assert_false(game.hud.menu_panel.visible)
	assert_false(game.paused)
	assert_eq(game.sim.units.size(), 0)

func test_language_from_the_menu_keeps_it_open() -> void:
	var before := TranslationServer.get_locale()
	game.hud.menu_button.pressed.emit()
	game.hud.language_button.pressed.emit()
	assert_ne(TranslationServer.get_locale(), before)
	assert_true(game.hud.menu_panel.visible)
	TranslationServer.set_locale(before)

func test_quit_saves_the_match_and_leaves() -> void:
	var left := []
	game.quit_action = func(): left.append(true)
	game.select_class("archer")
	game.cell_clicked(FREE_CELL)
	game.hud.menu_button.pressed.emit()
	game.hud.quit_button.pressed.emit()
	assert_eq(left, [true])
	assert_string_contains(FileAccess.get_file_as_string(game.last_log_path), "Jogo fechado")

func _escape_goblin() -> void:
	var monster = game.sim.spawn_monster("goblin")
	monster.distance = game.sim.route.length
	game.advance(game.STEP)
	game.hud.refresh(game)

func test_village_marker_shows_the_lives_left_of_the_total() -> void:
	game.hud.refresh(game)
	assert_string_contains(game.hud.village_label.text, "20/20")
	assert_eq(game.hud.village_fill.size.x, game.hud.village_bar.size.x)
	_escape_goblin()
	assert_string_contains(game.hud.village_label.text, "19/20")
	assert_almost_eq(game.hud.village_fill.size.x, game.hud.village_bar.size.x * 19.0 / 20.0, 0.01)

func test_top_bar_shows_the_lives_left_of_the_total() -> void:
	_escape_goblin()
	assert_string_contains(game.hud.lives_label.text, "19/20")

func test_village_marker_sits_above_the_village() -> void:
	var village: Sprite2D = game._level_node.get_node("Village")
	var bar: Control = game.hud.village_bar
	assert_almost_eq(bar.get_rect().get_center().x, village.position.x, 1.0)
	assert_lte(bar.get_rect().end.y, village.position.y - village.texture.get_height() / 2.0 + 8.0)
	assert_gte(bar.position.y, float(game.hud.TOP_HEIGHT))

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

func _log_files() -> PackedStringArray:
	return DirAccess.get_files_at(game.log_dir) if DirAccess.dir_exists_absolute(game.log_dir) else PackedStringArray()

func test_restart_without_activity_writes_no_log() -> void:
	game.restart()
	assert_eq(_log_files().size(), 0)

func test_restart_after_playing_saves_the_abandoned_match() -> void:
	game.select_class("archer")
	game.cell_clicked(FREE_CELL)
	game.restart()
	assert_eq(_log_files().size(), 2, "um .md e um .json")
	var path: String = game.last_log_path
	assert_string_contains(FileAccess.get_file_as_string(path), "Reiniciada")

func test_finishing_a_level_saves_the_log_once() -> void:
	game.select_class("archer")
	game.cell_clicked(FREE_CELL)
	game.finish_level("lost", 0)
	assert_string_contains(FileAccess.get_file_as_string(game.last_log_path), "Derrota")
	var count := _log_files().size()
	game.restart()
	assert_eq(_log_files().size(), count, "reiniciar depois do fim não duplica")

func test_closing_the_window_saves_the_match() -> void:
	game.select_class("archer")
	game.cell_clicked(FREE_CELL)
	game.notification(NOTIFICATION_WM_CLOSE_REQUEST)
	assert_string_contains(FileAccess.get_file_as_string(game.last_log_path), "Jogo fechado")

func test_result_panel_has_a_log_button() -> void:
	game.finish_level("won", 3)
	assert_true(game.hud.log_button in game.hud.all_buttons())

func test_upgrading_in_game_changes_the_unit_sprite() -> void:
	game.sim.gold = 1000
	game.select_class("warrior")
	game.cell_clicked(FREE_CELL)
	game.cell_clicked(FREE_CELL)
	game.upgrade_selected()
	game.upgrade_selected()
	game.advance(0.0)
	var view = game.view_of(game.selected_unit)
	view.sync(0.0)
	assert_eq(view.sprite.sprite_frames, load("res://assets/sprites/warrior_3.tres"))

func _win() -> void:
	game.finish_level("won", 3)

func _unlock_second_level() -> void:
	game.progress.record(0, 1)

func test_opens_on_the_first_level_without_progress() -> void:
	assert_eq(game.level_index, 0)
	assert_eq(game.level.id, "level_01")

func test_opens_on_the_furthest_unlocked_level() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"stars": {"0": 2}}))
	file.close()
	var other = load("res://src/game/main.tscn").instantiate()
	other.progress_path = SAVE_PATH
	other.log_dir = LOG_DIR
	add_child_autofree(other)
	assert_eq(other.level.id, "level_02")

func test_a_locked_level_does_not_open() -> void:
	game.open_level(1)
	assert_eq(game.level.id, "level_01")

func test_next_level_button_only_appears_after_winning() -> void:
	game.finish_level("lost", 0)
	assert_false(game.hud.next_level_button.visible)
	game.restart()
	_win()
	assert_true(game.hud.next_level_button.visible)

func test_next_level_starts_a_fresh_match_on_the_new_map() -> void:
	game.select_class("archer")
	game.cell_clicked(FREE_CELL)
	_win()
	game.next_level()
	assert_eq(game.level.id, "level_02")
	assert_eq(game.sim.units.size(), 0)
	assert_eq(game.sim.gold, GameData.load_level("level_02").start_gold)
	assert_false(game.hud.result_panel.visible)
	assert_eq(game.get_children().filter(func(c): return c.has_node("Route")).size(), 1, "só um mapa na cena")

func test_new_level_offers_its_own_classes() -> void:
	_win()
	game.next_level()
	await wait_physics_frames(1)
	assert_true(game.hud.class_buttons.has("mage"))
	assert_eq(game.hud.class_buttons.size(), 3)

func test_last_level_has_no_next_level_button() -> void:
	for level_id in game.LEVEL_IDS.slice(1):
		_win()
		game.next_level()
	_win()
	assert_false(game.hud.next_level_button.visible)

func test_all_five_classes_fit_in_the_bar_of_the_forest() -> void:
	game.progress.record(0, 1)
	game.progress.record(1, 1)
	game.open_level(2)
	game.hud.refresh(game)
	assert_eq(game.hud.class_buttons.size(), 5)
	for button: Button in game.hud.class_buttons.values():
		assert_lte(button.get_combined_minimum_size().x, button.size.x, button.tooltip_text)
		assert_lte(button.position.x + button.size.x, float(game.hud.CLASS_BAR_WIDTH))
		assert_ne(button.tooltip_text, "", "o nome da classe aparece ao passar o mouse")

func _open_cemetery() -> void:
	for i in 3:
		game.progress.record(i, 1)
	game.open_level(3)
	game.hud.refresh(game)

func test_all_seven_classes_fit_in_the_bar_of_the_cemetery() -> void:
	_open_cemetery()
	assert_eq(game.hud.class_buttons.size(), 7)
	for button: Button in game.hud.class_buttons.values():
		var needed: Vector2 = button.get_combined_minimum_size()
		assert_lte(needed.x, button.size.x, button.tooltip_text)
		assert_lte(needed.y, button.size.y, button.tooltip_text)
		assert_lte(button.position.x + button.size.x, float(game.hud.CLASS_BAR_WIDTH))
		assert_lte(button.position.y + button.size.y, float(game.hud.SCREEN.y - game.hud.BOTTOM_TOP))
		assert_true(button.text.is_valid_int(), "o botão mostra o preço")

func test_class_icon_dims_when_the_class_is_too_expensive() -> void:
	_open_cemetery()
	game.sim.gold = 0
	game.hud.refresh(game)
	assert_lt(game.hud.class_icons["monk"].modulate.a, 1.0)
	game.sim.gold = 500
	game.hud.refresh(game)
	assert_eq(game.hud.class_icons["monk"].modulate.a, 1.0)

func test_class_tooltip_names_the_class_and_its_damage_type() -> void:
	_open_cemetery()
	var tooltip: String = game.hud.class_buttons["monk"].tooltip_text
	assert_string_contains(tooltip, tr("UNIT_MONK"))
	assert_string_contains(tooltip, tr("DAMAGE_IMPACT"))

func test_next_wave_shows_what_its_monsters_are_weak_to() -> void:
	_open_cemetery()
	assert_string_contains(game.hud.weak_label.text, tr("WEAK_IMPACT"))

func test_selected_unit_shows_its_damage_type() -> void:
	_open_cemetery()
	game.sim.gold = 500
	game.select_class("rogue")
	game.cell_clicked(Vector2i(11, 5))
	game.cell_clicked(Vector2i(11, 5))
	game.hud.refresh(game)
	assert_string_contains(game.hud.unit_label.text, tr("WEAK_PIERCE"))

func test_stars_are_saved_for_the_level_being_played() -> void:
	_win()
	game.next_level()
	game.finish_level("won", 2)
	assert_eq(game.progress.stars_for(1), 2)
	assert_eq(game.progress.stars_for(0), 3)

func test_leaving_a_level_saves_the_abandoned_match() -> void:
	_unlock_second_level()
	game.select_class("archer")
	game.cell_clicked(FREE_CELL)
	game.open_level(1)
	assert_eq(DirAccess.get_files_at(LOG_DIR).size(), 2, "um .md e um .json")

func test_report_of_the_second_level_carries_its_id() -> void:
	_unlock_second_level()
	game.open_level(1)
	game.select_class("archer")
	game.cell_clicked(Vector2i(2, 4))
	game.finish_level("lost", 0)
	assert_true(game.last_log_path.ends_with("level_02.md"), game.last_log_path)

func test_levels_panel_pauses_and_restores() -> void:
	game.toggle_levels()
	assert_true(game.hud.levels_panel.visible)
	assert_true(game.paused)
	game.toggle_levels()
	assert_false(game.hud.levels_panel.visible)
	assert_false(game.paused)

func test_levels_panel_keeps_a_pause_the_player_chose() -> void:
	game.toggle_pause()
	game.toggle_levels()
	game.toggle_levels()
	assert_true(game.paused)

func test_levels_panel_locks_what_was_not_reached() -> void:
	game.toggle_levels()
	game.hud.refresh(game)
	assert_false(game.hud.level_buttons[0].disabled)
	assert_true(game.hud.level_buttons[1].disabled)
	_unlock_second_level()
	game.hud.refresh(game)
	assert_false(game.hud.level_buttons[1].disabled)

func test_choosing_in_the_panel_opens_the_level_and_closes_the_panel() -> void:
	_unlock_second_level()
	game.toggle_levels()
	game.hud.level_buttons[1].pressed.emit()
	assert_eq(game.level.id, "level_02")
	assert_false(game.hud.levels_panel.visible)
	assert_false(game.paused)

