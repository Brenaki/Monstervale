extends RefCounted
## Sintetizador de efeitos e músicas no estilo dos consoles de 8 bits.
## Os sons são descritos em data/sounds.json e as músicas em data/music.json;
## tools/build_audio.gd grava o resultado em arquivos WAV.

const RATE := 22050
const ATTACK := 0.005
const RELEASE := 0.03
const STEPS_PER_BAR := 8
const HEADROOM := 0.9
const NOTE_NAMES := {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
const LEAD_VOLUME := 0.22
const BASS_VOLUME := 0.3
const ARP_VOLUME := 0.08
const DRUM_VOLUME := 0.35
const DRUMS := {
	"k": {"wave": "sine", "freq": 130, "freq_end": 45, "duration": 0.14, "volume": 1.0},
	"s": {"wave": "noise", "freq": 6000, "duration": 0.12, "volume": 0.6, "lowpass": 0.5},
	"h": {"wave": "noise", "freq": 11000, "duration": 0.03, "volume": 0.3},
}


## Um efeito: uma camada ou várias ("layers") somadas, sem passar do volume máximo.
static func render_sound(sound: Dictionary) -> PackedFloat32Array:
	var layers: Array = sound.get("layers", [sound])
	var mixed := PackedFloat32Array()
	for layer: Dictionary in layers:
		var start := int(float(layer.get("start", 0.0)) * RATE)
		var samples := render_layer(layer)
		if mixed.size() < start + samples.size():
			mixed.resize(start + samples.size())
		for i in samples.size():
			mixed[start + i] += samples[i]
	return _limited(mixed, 1.0)


## Uma voz: forma de onda, altura que pode deslizar, arpejo, vibrato e envelope.
static func render_layer(layer: Dictionary) -> PackedFloat32Array:
	var duration := float(layer.duration)
	var count := int(duration * RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var wave: String = layer.get("wave", "square")
	var freq := _frequency(layer.freq)
	var freq_end := _frequency(layer.get("freq_end", freq))
	var volume := float(layer.get("volume", 0.8))
	var duty := float(layer.get("duty", 0.5))
	var notes: Array = layer.get("notes", [0])
	var note_time := float(layer.get("note_time", duration))
	var vibrato_depth := float(layer.get("vibrato_depth", 0.0))
	var vibrato_rate := float(layer.get("vibrato_rate", 6.0))
	var lowpass := float(layer.get("lowpass", 1.0))
	var held: bool = layer.get("envelope", "pluck") == "hold"
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	var phase := 0.0
	var noise_value := rng.randf_range(-1.0, 1.0)
	var filtered := 0.0
	for i in count:
		var t := float(i) / RATE
		var along := t / duration
		var hz := freq * pow(freq_end / freq, along)
		var note: int = notes[mini(int(t / note_time), notes.size() - 1)]
		hz *= pow(2.0, (note + vibrato_depth * sin(TAU * vibrato_rate * t)) / 12.0)
		phase += hz / RATE
		if phase >= 1.0:
			phase -= floorf(phase)
			noise_value = rng.randf_range(-1.0, 1.0)
		var value := 0.0
		match wave:
			"square":
				value = 1.0 if phase < duty else -1.0
			"triangle":
				value = 4.0 * absf(phase - 0.5) - 1.0
			"saw":
				value = 2.0 * phase - 1.0
			"sine":
				value = sin(TAU * phase)
			"noise":
				value = noise_value
		filtered += (value - filtered) * lowpass
		samples[i] = filtered * volume * _envelope(t, duration, held)
	return samples


## Pluck cai até o silêncio; hold segura a nota e solta só no fim.
static func _envelope(t: float, duration: float, held: bool) -> float:
	var level := minf(1.0, t / ATTACK)
	if held:
		return level * clampf((duration - t) / RELEASE, 0.0, 1.0)
	return level * pow(1.0 - t / duration, 2.0)


static func _frequency(value) -> float:
	return note_frequency(value) if value is String else float(value)


static func note_frequency(name: String) -> float:
	return 440.0 * pow(2.0, (note_number(name) - 69) / 12.0)


## Número MIDI de um nome como "C4", "F#3" ou "Bb2".
static func note_number(name: String) -> int:
	var pitch: int = NOTE_NAMES[name[0]]
	var rest := name.substr(1)
	if rest.begins_with("#"):
		pitch += 1
		rest = rest.substr(1)
	elif rest.begins_with("b"):
		pitch -= 1
		rest = rest.substr(1)
	return (int(rest) + 1) * 12 + pitch


## Fundamental, terça e quinta, com a fundamental na terceira oitava.
static func chord_notes(chord: String) -> Array:
	var minor := chord.ends_with("m")
	var root_name := chord.trim_suffix("m")
	var root := note_number(root_name + "3")
	return [root, root + (3 if minor else 4), root + 7]


static func midi_frequency(midi: int) -> float:
	return 440.0 * pow(2.0, (midi - 69) / 12.0)


## Uma música em compassos de oito colcheias: melodia escrita, baixo e arpejo tirados dos
## acordes, e bateria. Na melodia, "-" segura a nota anterior e "." é pausa.
static func render_song(song: Dictionary) -> PackedFloat32Array:
	var chords: Array = song.chords
	var step := 60.0 / float(song.bpm) / 2.0
	var total := int(chords.size() * STEPS_PER_BAR * step * RATE)
	var mixed := PackedFloat32Array()
	mixed.resize(total)
	for event: Dictionary in _melody_events(song.get("melody", []), chords.size()):
		_add_note(mixed, event.start * step, event.length * step, {
			"wave": "square", "duty": song.get("lead_duty", 0.25), "freq": midi_frequency(event.midi),
			"volume": LEAD_VOLUME, "envelope": "hold", "vibrato_depth": 0.15, "vibrato_rate": 5.5,
		})
	for bar in chords.size():
		var notes := chord_notes(chords[bar])
		for i in STEPS_PER_BAR:
			var bass_note: int = notes[0] - 12 + (12 if i % 4 == 2 else 0)
			_add_note(mixed, (bar * STEPS_PER_BAR + i) * step, step, {
				"wave": "triangle", "freq": midi_frequency(bass_note), "volume": BASS_VOLUME, "envelope": "hold",
			})
			for half in 2:
				var arp_note: int = notes[(i * 2 + half) % notes.size()] + 12
				_add_note(mixed, (bar * STEPS_PER_BAR + i + half * 0.5) * step, step * 0.5, {
					"wave": "square", "duty": 0.5, "freq": midi_frequency(arp_note), "volume": ARP_VOLUME,
				})
	var drums: Array = song.get("drums", [])
	for bar in chords.size():
		if drums.is_empty():
			break
		var tokens: PackedStringArray = drums[bar % drums.size()].split(" ", false)
		for i in tokens.size():
			for hit in tokens[i]:
				if DRUMS.has(hit):
					var drum: Dictionary = DRUMS[hit].duplicate()
					drum.volume = drum.volume * DRUM_VOLUME
					_add_note(mixed, (bar * STEPS_PER_BAR + i) * step, drum.duration, drum)
	return _limited(mixed, HEADROOM)


static func _melody_events(bars: Array, bar_count: int) -> Array:
	var events := []
	if bars.is_empty():
		return events
	var current = null
	for bar in bar_count:
		var tokens: PackedStringArray = bars[bar % bars.size()].split(" ", false)
		for i in tokens.size():
			var token := tokens[i]
			var at := bar * STEPS_PER_BAR + i
			if token == "-" and current != null:
				current.length += 1
				continue
			current = null
			if token != "." and token != "-":
				current = {"start": at, "length": 1, "midi": note_number(token)}
				events.append(current)
	return events


static func _add_note(mixed: PackedFloat32Array, start: float, duration: float, layer: Dictionary) -> void:
	layer.duration = duration
	var samples := render_layer(layer)
	var offset := int(start * RATE)
	for i in mini(samples.size(), mixed.size() - offset):
		mixed[offset + i] += samples[i]


## Abaixa tudo por igual se algum ponto passar do teto.
static func _limited(samples: PackedFloat32Array, ceiling: float) -> PackedFloat32Array:
	var peak := 0.0
	for sample in samples:
		peak = maxf(peak, absf(sample))
	if peak > ceiling:
		var gain := ceiling / peak
		for i in samples.size():
			samples[i] *= gain
	return samples


static func to_wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = data
	return stream
