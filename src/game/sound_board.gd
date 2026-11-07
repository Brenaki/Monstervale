extends Node
## Toca efeitos e música. Cada efeito tem poucas vozes e espera um instante entre uma vez e
## outra, para que trinta flechas seguidas não virem um ruído só.

const SOUND_PATH := "res://assets/sounds/%s.wav"
const MUSIC_PATH := "res://assets/music/%s.wav"
const VOICES := 3
const MIN_GAP_MS := 50
const PITCH_SPREAD := 0.06
const PLAYED_MEMORY := 64

## Os últimos efeitos tocados, do mais antigo ao mais novo.
var played: Array = []
var music_track := ""
var music_changes := 0
var music_player: AudioStreamPlayer

var _voices := {}
var _last_ms := {}
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = &"Music"
	add_child(music_player)


func play(sound: String) -> void:
	var path := SOUND_PATH % sound
	if not ResourceLoader.exists(path):
		return
	var now := Time.get_ticks_msec()
	if _last_ms.has(sound) and now - _last_ms[sound] < MIN_GAP_MS:
		return
	var voice := _free_voice(sound, path)
	if voice == null:
		return
	_last_ms[sound] = now
	voice.pitch_scale = 1.0 + _rng.randf_range(-PITCH_SPREAD, PITCH_SPREAD)
	voice.play()
	played.append(sound)
	if played.size() > PLAYED_MEMORY:
		played.pop_front()


func voice_for(sound: String) -> AudioStreamPlayer:
	return _voices.get(sound, [null])[0]


## Uma faixa vazia para a música. Pedir a faixa que já toca não a recomeça.
func play_music(track: String) -> void:
	if track == music_track:
		return
	music_track = track
	music_changes += 1
	if track == "":
		music_player.stop()
		return
	var stream: AudioStreamWAV = load(MUSIC_PATH % track)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = int(stream.get_length() * stream.mix_rate)
	music_player.stream = stream
	music_player.play()


func _free_voice(sound: String, path: String) -> AudioStreamPlayer:
	if not _voices.has(sound):
		var pool := []
		var stream: AudioStream = load(path)
		for i in VOICES:
			var voice := AudioStreamPlayer.new()
			voice.stream = stream
			voice.bus = &"Sfx"
			add_child(voice)
			pool.append(voice)
		_voices[sound] = pool
	for voice: AudioStreamPlayer in _voices[sound]:
		if not voice.playing:
			return voice
	return null
