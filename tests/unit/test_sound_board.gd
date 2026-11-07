extends GutTest

const SoundBoard = preload("res://src/game/sound_board.gd")

var board

func before_each() -> void:
	board = SoundBoard.new()
	add_child_autofree(board)

func test_every_sound_and_song_in_the_data_was_built() -> void:
	for data_path: String in ["res://data/sounds.json", "res://data/music.json"]:
		var folder := "sounds" if data_path.ends_with("sounds.json") else "music"
		var entries: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(data_path))
		for name: String in entries:
			assert_true(ResourceLoader.exists("res://assets/%s/%s.wav" % [folder, name]), name)

func test_effects_play_on_the_effects_bus_and_music_on_the_music_bus() -> void:
	board.play("click")
	board.play_music("title")
	assert_eq(board.voice_for("click").bus, &"Sfx")
	assert_eq(board.music_player.bus, &"Music")

func test_the_same_effect_waits_a_moment_before_playing_again() -> void:
	board.play("arrow")
	board.play("arrow")
	assert_eq(board.played.count("arrow"), 1)
	board.play("sword")
	assert_eq(board.played.count("sword"), 1, "outro som não espera")

func test_unknown_effects_are_ignored() -> void:
	board.play("nao_existe")
	assert_eq(board.played, [])

func test_music_loops_and_does_not_restart_when_asked_again() -> void:
	board.play_music("battle")
	var stream: AudioStreamWAV = board.music_player.stream
	assert_eq(stream.loop_mode, AudioStreamWAV.LOOP_FORWARD)
	assert_gt(stream.loop_end, 0)
	board.play_music("battle")
	assert_eq(board.music_changes, 1)
	board.play_music("")
	assert_eq(board.music_track, "")
	assert_false(board.music_player.playing)
