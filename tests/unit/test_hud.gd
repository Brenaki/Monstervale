extends GutTest

const UiKit = preload("res://src/game/ui_kit.gd")

const SAVE_PATH := "user://test_hud_progress.json"
const SETTINGS_PATH := "user://test_settings.json"
const LOG_DIR := "user://test_hud_partidas"
const FREE_CELL := Vector2i(7, 5)
const TOP_ROW_CELL := Vector2i(5, 1)

var game

func before_each() -> void:
	DirAccess.remove_absolute(SETTINGS_PATH)
	DirAccess.remove_absolute(SAVE_PATH)
	game = load("res://src/game/main.tscn").instantiate()
	game.progress_path = SAVE_PATH
	game.settings_path = SETTINGS_PATH
	game.start_on_title = false
	game.log_dir = LOG_DIR
	add_child_autofree(game)

func after_all() -> void:
	DirAccess.remove_absolute(SETTINGS_PATH)
	DirAccess.remove_absolute(SAVE_PATH)

func _select_new(kind: String, cell: Vector2i):
	game.sim.gold = 1000
	game.select_class(kind)
	game.cell_clicked(cell)
	game.cell_clicked(cell)
	game.hud.refresh(game)
	return game.selected_unit

func _center(button: Button) -> Vector2:
	return button.get_global_rect().get_center()

func test_ring_appears_only_around_a_selected_unit() -> void:
	game.hud.refresh(game)
	assert_false(game.hud.ring.visible)
	_select_new("archer", FREE_CELL)
	assert_true(game.hud.ring.visible)
	game.clear_selection()
	game.hud.refresh(game)
	assert_false(game.hud.ring.visible)

func test_ring_puts_upgrade_above_dismiss_below_and_target_to_the_side() -> void:
	var unit = _select_new("archer", FREE_CELL)
	assert_lt(_center(game.hud.upgrade_button).y, unit.position.y - 16)
	assert_gt(_center(game.hud.dismiss_button).y, unit.position.y + 16)
	assert_gt(_center(game.hud.priority_button).x, unit.position.x + 16)

func test_ring_stays_out_of_the_bars_next_to_the_top_edge() -> void:
	_select_new("archer", TOP_ROW_CELL)
	var rects := []
	for button: Button in [game.hud.upgrade_button, game.hud.dismiss_button, game.hud.priority_button]:
		var rect := button.get_global_rect()
		assert_gte(rect.position.y, float(game.hud.TOP_HEIGHT))
		assert_lte(rect.end.y, float(game.hud.BOTTOM_TOP))
		for other: Rect2 in rects:
			assert_false(rect.intersects(other), "botões do anel não se sobrepõem")
		rects.append(rect)

func test_ring_shows_the_upgrade_price_and_the_refund() -> void:
	var unit = _select_new("archer", FREE_CELL)
	assert_eq(game.hud.upgrade_label.text, str(unit.upgrade_cost()))
	assert_eq(game.hud.dismiss_label.text, "+%d" % unit.refund())

func test_ring_upgrade_is_disabled_without_gold() -> void:
	_select_new("archer", FREE_CELL)
	game.sim.gold = 0
	game.hud.refresh(game)
	assert_true(game.hud.upgrade_button.disabled)

func test_sheet_shows_the_level_as_stars_and_the_stats() -> void:
	var unit = _select_new("warrior", FREE_CELL)
	game.upgrade_selected()
	game.hud.refresh(game)
	var lit: Array = game.hud.unit_stars.filter(func(star): return star.texture.region == UiKit.icon("star").region)
	assert_eq(lit.size(), 2)
	assert_eq(game.hud.unit_damage_label.text, str(int(unit.stats().damage)))
	assert_eq(game.hud.unit_range_label.text, str(int(unit.stats().range)))
	assert_eq(game.hud.unit_hp_label.text, str(int(unit.stats().hp)))
	assert_string_contains(game.hud.unit_label.text, tr("UNIT_WARRIOR"))

func test_top_panel_shows_lives_gold_and_wave_as_numbers() -> void:
	game.hud.refresh(game)
	assert_eq(game.hud.lives_label.text, "20/20")
	assert_eq(game.hud.gold_label.text, str(game.sim.gold))
	assert_eq(game.hud.wave_label.text, "0/%d" % game.sim.waves_total())

func test_next_wave_preview_shows_one_icon_per_monster_kind() -> void:
	game.hud.refresh(game)
	await wait_process_frames(1)
	var pairs: Array = game.hud._preview.get_children()
	assert_eq(pairs.size(), game.sim.next_wave_preview().size())
	assert_eq(pairs[0].get_child(0).tooltip_text, tr("MONSTER_GOBLIN"))
	assert_eq(pairs[0].get_child(1).text, "x%d" % game.sim.next_wave_preview()["goblin"])

func test_call_wave_button_shows_the_early_bonus() -> void:
	game.hud.refresh(game)
	assert_eq(game.hud.next_wave_button.text, "+%d" % game.sim.early_call_bonus())

func test_call_wave_button_drops_the_bonus_once_it_runs_out() -> void:
	game.sim.next_wave_countdown = 0.0
	game.hud.refresh(game)
	assert_false(game.hud.next_wave_button.disabled)
	assert_eq(game.hud.next_wave_button.text, "")
	assert_eq(game.hud.next_wave_button.tooltip_text, tr("BTN_START_WAVE"))

func test_call_wave_button_asks_for_attention_only_while_the_field_is_empty() -> void:
	game.hud.refresh(game)
	assert_true(game.hud.wave_waiting)
	game.call_wave()
	game.advance(1.0)
	game.hud.refresh(game)
	assert_false(game.hud.wave_waiting)

func test_speed_and_pause_buttons_switch_their_icons() -> void:
	game.hud.refresh(game)
	var pause_icon: Rect2 = game.hud.pause_button.icon.region
	assert_false(game.hud.speed_button.button_pressed)
	game.toggle_pause()
	game.toggle_speed()
	game.hud.refresh(game)
	assert_ne(game.hud.pause_button.icon.region, pause_icon)
	assert_true(game.hud.speed_button.button_pressed, "2x fica aceso")

func test_class_card_shows_the_price_on_a_badge() -> void:
	game.hud.refresh(game)
	assert_eq(game.hud.class_prices["archer"].text, str(game.sim.unit_cost("archer")))

func test_levels_are_chosen_from_the_menu() -> void:
	assert_true(game.hud.menu_panel.is_ancestor_of(game.hud.levels_button))

## Cada ícone fica com o meio na mesma altura do texto ao lado.
func test_icons_and_numbers_share_the_same_middle_line() -> void:
	_select_new("archer", FREE_CELL)
	await wait_process_frames(2)
	for label: Label in [game.hud.lives_label, game.hud.gold_label, game.hud.unit_damage_label, game.hud.unit_hp_label]:
		var icon: Control = label.get_parent().get_child(0)
		assert_almost_eq(label.get_global_rect().get_center().y, icon.get_global_rect().get_center().y, 0.5, label.text)

func test_labels_use_the_pixel_font_at_its_own_size() -> void:
	game.hud.refresh(game)
	var label: Label = game.hud.gold_label
	assert_eq(label.get_theme_font_size("font_size"), UiKit.FONT_SIZE)
	assert_eq(label.get_theme_font("font"), UiKit.font())
	assert_eq(game.hud.next_wave_button.get_theme_font_size("font_size"), UiKit.FONT_SIZE)

func test_labels_keep_the_height_they_were_given() -> void:
	game.hud.refresh(game)
	var price: Label = game.hud.class_prices["archer"]
	assert_eq(price.size.y, 12.0)
