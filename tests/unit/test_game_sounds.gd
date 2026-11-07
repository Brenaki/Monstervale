extends GutTest

const SAVE_PATH := "user://test_sounds_progress.json"
const SETTINGS_PATH := "user://test_sounds_settings.json"
const LOG_DIR := "user://test_sounds_partidas"
const FREE_CELL := Vector2i(7, 5)

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
	for file_name in DirAccess.get_files_at(LOG_DIR):
		DirAccess.remove_absolute("%s/%s" % [LOG_DIR, file_name])
	DirAccess.remove_absolute(LOG_DIR)

func _start() -> void:
	game.title.play_button.pressed.emit()
	game._process(0.0)

func test_title_plays_its_own_music_and_a_level_plays_the_battle_music() -> void:
	game._process(0.0)
	assert_eq(game.sounds.music_track, "title")
	_start()
	assert_eq(game.sounds.music_track, "battle")

func test_the_boss_brings_its_own_music_and_a_roar() -> void:
	_start()
	game.sim.spawn_monster("slime_king")
	game.advance(game.STEP)
	game._process(0.0)
	assert_eq(game.sounds.music_track, "boss")
	assert_has(game.sounds.played, "boss_roar")

func test_placing_and_upgrading_sound_different() -> void:
	_start()
	game.sim.gold = 1000
	game.select_class("archer")
	game.cell_clicked(FREE_CELL)
	game.cell_clicked(FREE_CELL)
	game.upgrade_selected()
	assert_has(game.sounds.played, "place")
	assert_has(game.sounds.played, "upgrade")

func test_each_class_attacks_with_its_own_sound() -> void:
	_start()
	assert_eq(game.ATTACK_SOUNDS.size(), game.catalog.units.size())
	for kind: String in game.catalog.units:
		assert_true(ResourceLoader.exists("res://assets/sounds/%s.wav" % game.ATTACK_SOUNDS[kind]), kind)

func test_a_dying_monster_sounds_like_its_family() -> void:
	assert_eq(game.death_sound("slime_medium"), "death_slime")
	assert_eq(game.death_sound("slime_king"), "death_slime")
	assert_eq(game.death_sound("skeleton_knight"), "death_bones")
	assert_eq(game.death_sound("wolf"), "death_beast")

func test_an_escaped_monster_sounds_a_warning() -> void:
	_start()
	var monster = game.sim.spawn_monster("goblin")
	monster.distance = game.sim.route.length
	game.advance(game.STEP)
	assert_has(game.sounds.played, "escaped")

func test_the_end_of_a_level_stops_the_music_and_plays_a_jingle() -> void:
	_start()
	game.finish_level("won", 3)
	game._process(0.0)
	assert_eq(game.sounds.music_track, "")
	assert_has(game.sounds.played, "won")

func test_buttons_click() -> void:
	game.title.options_button.pressed.emit()
	assert_has(game.sounds.played, "click")
