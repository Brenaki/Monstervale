extends GutTest

const Settings = preload("res://src/core/settings.gd")

func test_defaults_leave_music_a_bit_lower_than_the_effects() -> void:
	var settings = Settings.new()
	assert_lt(settings.music_volume, settings.sfx_volume)
	assert_false(settings.fullscreen)
	assert_eq(settings.locale, "")

func test_round_trip_keeps_every_choice() -> void:
	var settings = Settings.new()
	settings.music_volume = 0.3
	settings.sfx_volume = 1.0
	settings.fullscreen = true
	settings.locale = "en"
	var copy = Settings.from_dict(JSON.parse_string(JSON.stringify(settings.to_dict())))
	assert_almost_eq(copy.music_volume, 0.3, 0.001)
	assert_almost_eq(copy.sfx_volume, 1.0, 0.001)
	assert_true(copy.fullscreen)
	assert_eq(copy.locale, "en")

func test_broken_values_fall_back_to_the_defaults() -> void:
	var copy = Settings.from_dict({"music_volume": "alto", "sfx_volume": 7, "fullscreen": "sim", "locale": 3})
	var defaults = Settings.new()
	assert_eq(copy.music_volume, defaults.music_volume)
	assert_eq(copy.sfx_volume, 1.0, "acima do máximo fica no máximo")
	assert_false(copy.fullscreen)
	assert_eq(copy.locale, "")

func test_volume_moves_in_tenths_and_stays_between_zero_and_one() -> void:
	var settings = Settings.new()
	settings.music_volume = 0.9
	settings.step_volume("music", 1)
	settings.step_volume("music", 1)
	assert_almost_eq(settings.music_volume, 1.0, 0.001)
	for i in 12:
		settings.step_volume("sfx", -1)
	assert_almost_eq(settings.sfx_volume, 0.0, 0.001)

func test_zero_volume_is_silence() -> void:
	assert_eq(Settings.volume_db(0.0), -80.0)
	assert_almost_eq(Settings.volume_db(1.0), 0.0, 0.001)
	assert_lt(Settings.volume_db(0.5), 0.0)

func test_dev_mode_starts_off_and_records_once_turned_on() -> void:
	var settings = Settings.new()
	assert_false(settings.dev_mode)
	assert_false(settings.dev_invincible)
	assert_false(settings.dev_infinite_gold)
	assert_true(settings.dev_record)

func test_dev_switches_are_saved() -> void:
	var settings = Settings.new()
	settings.dev_mode = true
	settings.dev_invincible = true
	settings.dev_record = false
	var copy = Settings.from_dict(JSON.parse_string(JSON.stringify(settings.to_dict())))
	assert_true(copy.dev_mode)
	assert_true(copy.dev_invincible)
	assert_false(copy.dev_infinite_gold)
	assert_false(copy.dev_record)
