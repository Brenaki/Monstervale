extends SceneTree
## Grava os efeitos de data/sounds.json e as músicas de data/music.json em WAV.
## Uso: godot --headless --path . -s tools/build_audio.gd
## Depois rode godot --headless --path . --import para o Godot reconhecer os arquivos.

const Synth = preload("res://src/core/synth.gd")

const SOUNDS_DATA := "res://data/sounds.json"
const MUSIC_DATA := "res://data/music.json"
const SOUNDS_DIR := "res://assets/sounds/"
const MUSIC_DIR := "res://assets/music/"


func _initialize() -> void:
	_build(SOUNDS_DATA, SOUNDS_DIR, Synth.render_sound)
	_build(MUSIC_DATA, MUSIC_DIR, Synth.render_song)
	quit()


func _build(data_path: String, out_dir: String, render: Callable) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var entries: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(data_path))
	for name: String in entries:
		var samples: PackedFloat32Array = render.call(entries[name])
		var path := "%s%s.wav" % [out_dir, name]
		Synth.to_wav(samples).save_to_wav(ProjectSettings.globalize_path(path))
		print("%s: %.2f s" % [path, samples.size() / float(Synth.RATE)])
