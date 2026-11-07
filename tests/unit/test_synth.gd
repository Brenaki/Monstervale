extends GutTest

const Synth = preload("res://src/core/synth.gd")

func _peak(samples: PackedFloat32Array) -> float:
	var peak := 0.0
	for sample in samples:
		peak = maxf(peak, absf(sample))
	return peak

func test_a_sound_lasts_its_duration() -> void:
	var samples := Synth.render_sound({"wave": "square", "freq": 440, "duration": 0.25})
	assert_eq(samples.size(), int(0.25 * Synth.RATE))

func test_sounds_never_clip() -> void:
	var loud := {"layers": [
		{"wave": "square", "freq": 200, "duration": 0.3, "volume": 1.0},
		{"wave": "noise", "freq": 1000, "duration": 0.3, "volume": 1.0},
	]}
	var samples := Synth.render_sound(loud)
	assert_lte(_peak(samples), 1.0)
	assert_gt(_peak(samples), 0.5)

func test_noise_repeats_the_same_way_every_build() -> void:
	var noise := {"wave": "noise", "freq": 2000, "duration": 0.1}
	assert_eq(Synth.render_sound(noise), Synth.render_sound(noise))

func test_every_wave_shape_makes_sound() -> void:
	for wave: String in ["square", "triangle", "saw", "sine", "noise"]:
		var samples := Synth.render_sound({"wave": wave, "freq": 330, "duration": 0.1})
		assert_gt(_peak(samples), 0.1, wave)

func test_a_sound_fades_out_by_its_end() -> void:
	var samples := Synth.render_sound({"wave": "square", "freq": 440, "duration": 0.2})
	var tail := samples.slice(samples.size() - 20)
	assert_lt(_peak(tail), 0.05)

func test_arpeggio_changes_pitch_over_time() -> void:
	var flat := Synth.render_sound({"wave": "square", "freq": 440, "duration": 0.3})
	var arp := Synth.render_sound({"wave": "square", "freq": 440, "duration": 0.3, "notes": [0, 12], "note_time": 0.15})
	assert_ne(flat, arp)

func test_note_names_turn_into_frequencies() -> void:
	assert_almost_eq(Synth.note_frequency("A4"), 440.0, 0.01)
	assert_almost_eq(Synth.note_frequency("A5"), 880.0, 0.01)
	assert_almost_eq(Synth.note_frequency("C4"), 261.63, 0.05)
	assert_almost_eq(Synth.note_frequency("F#3"), 185.0, 0.05)

func test_a_song_lasts_its_bars_at_its_tempo() -> void:
	var song := {
		"bpm": 120, "chords": ["Am", "F"],
		"melody": ["A4 - C5 - E5 - . .", "F4 - A4 - C5 - . ."],
		"drums": ["k . h . s . h ."],
	}
	var samples := Synth.render_song(song)
	assert_eq(samples.size(), int(2 * 4 * 60.0 / 120.0 * Synth.RATE))
	assert_lte(_peak(samples), 1.0)
	assert_gt(_peak(samples), 0.3)

func test_chords_know_their_notes() -> void:
	assert_eq(Synth.chord_notes("C"), [48, 52, 55])
	assert_eq(Synth.chord_notes("Am"), [57, 60, 64])
	assert_eq(Synth.chord_notes("Bb"), [58, 62, 65])

func test_wav_keeps_the_samples_as_16_bit_mono() -> void:
	var samples := Synth.render_sound({"wave": "sine", "freq": 440, "duration": 0.1})
	var stream: AudioStreamWAV = Synth.to_wav(samples)
	assert_eq(stream.format, AudioStreamWAV.FORMAT_16_BITS)
	assert_false(stream.stereo)
	assert_eq(stream.mix_rate, Synth.RATE)
	assert_eq(stream.data.size(), samples.size() * 2)
