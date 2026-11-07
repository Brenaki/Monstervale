extends GutTest

const SAVE_PATH := "user://test_tutorial_progress.json"
const SETTINGS_PATH := "user://test_tutorial_settings.json"
const LOG_DIR := "user://test_tutorial_partidas"
const ARCHER_CELL := Vector2i(7, 5)
const WARRIOR_CELL := Vector2i(9, 4)

var game

func before_each() -> void:
	DirAccess.remove_absolute(SAVE_PATH)
	DirAccess.remove_absolute(SETTINGS_PATH)
	game = load("res://src/game/main.tscn").instantiate()
	game.progress_path = SAVE_PATH
	game.settings_path = SETTINGS_PATH
	game.log_dir = LOG_DIR
	add_child_autofree(game)

func after_all() -> void:
	DirAccess.remove_absolute(SAVE_PATH)
	DirAccess.remove_absolute(SETTINGS_PATH)

func _step() -> String:
	return game.tutorial.current().get("text", "")

func _ok() -> void:
	game._process(0.0)
	game.tutorial.ok_button.pressed.emit()

## Deixa os goblins com 1 de vida até a onda acabar, para o arqueiro dar conta rápido.
func _clear_wave() -> void:
	for i in 6000:
		for monster in game.sim.monsters:
			monster.hp = mini(monster.hp, 1)
		game.advance(game.STEP)
		if game.tutorial.current().get("wait", "") != "wave_cleared":
			return

func test_the_first_play_starts_the_guide_in_level_one() -> void:
	game.title.play_button.pressed.emit()
	assert_true(game.tutorial.active())
	assert_eq(_step(), "TUT_WELCOME")

func test_the_guide_walks_through_the_whole_first_level() -> void:
	game.start_level(0)
	_ok()
	_ok()
	assert_eq(_step(), "TUT_PICK_ARCHER")
	game._process(0.0)
	assert_false(game.tutorial.ok_button.visible, "espera o jogador agir")
	game.select_class("archer")
	assert_eq(_step(), "TUT_PLACE_ARCHER")
	game.cell_clicked(ARCHER_CELL)
	assert_eq(_step(), "TUT_PREVIEW")
	_ok()
	assert_eq(_step(), "TUT_CALL_WAVE")
	game.call_wave()
	assert_eq(_step(), "TUT_KILLS")
	_clear_wave()
	assert_eq(_step(), "TUT_PICK_WARRIOR")
	game.select_class("warrior")
	game.cell_clicked(WARRIOR_CELL)
	assert_eq(_step(), "TUT_UPGRADE")
	game.sim.gold = 500
	game.cell_clicked(ARCHER_CELL)
	game.upgrade_selected()
	assert_eq(_step(), "TUT_SPEED")
	_ok()
	assert_false(game.tutorial.active())
	assert_true(game.progress.saw_tutorial("level_01"))

func test_a_seen_guide_does_not_come_back() -> void:
	game.progress.mark_tutorial("level_01")
	game.start_level(0)
	assert_false(game.tutorial.active())

func test_skipping_counts_as_seen() -> void:
	game.start_level(0)
	game.tutorial.skip_button.pressed.emit()
	assert_false(game.tutorial.active())
	assert_true(game.progress.saw_tutorial("level_01"))

func test_each_new_human_is_presented_when_it_first_appears() -> void:
	game.progress.record(0, 3)
	game.start_level(1)
	assert_eq(_step(), "TUT_MAGE")
	game.select_class("mage")
	game.sim.gold = 500
	game.cell_clicked(ARCHER_CELL)
	assert_eq(_step(), "TUT_WEAK")

func test_the_title_can_replay_the_tutorial() -> void:
	game.progress.mark_tutorial("level_01")
	game.progress.mark_tutorial("level_02")
	game.title.tutorial_button.pressed.emit()
	assert_eq(game.level_index, 0)
	assert_eq(_step(), "TUT_WELCOME")
	assert_false(game.progress.saw_tutorial("level_02"), "as outras fases apresentam os humanos de novo")

func test_menus_hide_the_guide_and_restart_begins_it_again() -> void:
	game.start_level(0)
	_ok()
	game.hud.menu_button.pressed.emit()
	game._process(0.0)
	assert_false(game.tutorial.visible)
	game.restart()
	game._process(0.0)
	assert_true(game.tutorial.visible)
	assert_eq(_step(), "TUT_WELCOME")

func test_leaving_for_the_title_stops_the_guide_without_marking_it() -> void:
	game.start_level(0)
	game.show_title()
	assert_false(game.tutorial.active())
	assert_false(game.progress.saw_tutorial("level_01"))

func test_the_box_never_covers_what_it_points_at() -> void:
	for i in game.LEVEL_IDS.size():
		game.progress.record(i, 3)
	for i in game.LEVEL_IDS.size():
		var level_id: String = game.LEVEL_IDS[i]
		game.start_level(i)
		for step: Dictionary in game.tutorial_steps.get(level_id, []):
			game.tutorial.start(level_id, [step])
			game.selected_unit = null
			game._process(0.0)
			var target: Rect2 = game.tutorial_target(step.get("target", ""))
			var box: Rect2 = game.tutorial.box.get_global_rect()
			# Melhorar e prioridade apontam para um humano, que ainda não está em campo aqui.
			if step.target not in ["upgrade:archer", "priority"]:
				assert_true(target.has_area(), "%s aponta para algo" % step.text)
			assert_false(box.intersects(target), "%s %s: caixa %s, alvo %s" % [level_id, step.text, box, target])
			assert_true(Rect2(Vector2.ZERO, Vector2(640, 360)).encloses(box), step.text)

func test_every_step_has_text_in_both_languages() -> void:
	for level_id: String in game.tutorial_steps:
		for step: Dictionary in game.tutorial_steps[level_id]:
			for locale: String in ["pt_BR", "en"]:
				TranslationServer.set_locale(locale)
				assert_ne(tr(step.text), step.text, "%s %s" % [locale, step.text])
	TranslationServer.set_locale("pt_BR")
