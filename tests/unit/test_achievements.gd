extends GutTest

const Achievements = preload("res://src/core/achievements.gd")
const Progress = preload("res://src/core/progress.gd")
const LEVELS := 5

func _won(progress, level: int, stars: int = 3) -> Array:
	progress.record(level, stars)
	return Achievements.after_win(progress, level, LEVELS)

func test_each_level_won_has_its_achievement() -> void:
	var progress = Progress.new()
	assert_eq(_won(progress, 0, 1), ["level_1"])
	assert_eq(_won(progress, 0, 3), [], "vencer de novo não repete")
	assert_eq(_won(progress, 3, 2), ["level_4"])

func test_three_stars_everywhere_makes_the_hero_of_heroes() -> void:
	var progress = Progress.new()
	for level in LEVELS - 1:
		_won(progress, level)
	_won(progress, LEVELS - 1, 2)
	assert_false(progress.has_achievement("hero_of_heroes"))
	assert_has(_won(progress, LEVELS - 1, 3), "hero_of_heroes")

func test_speedrunner_needs_three_stars_everywhere_within_the_time() -> void:
	var progress = Progress.new()
	progress.add_campaign_time(Achievements.SPEEDRUN_SECONDS)
	for level in LEVELS - 1:
		assert_false(_won(progress, level).has("speedrunner"), "faltam fases")
	assert_false(_won(progress, LEVELS - 1, 2).has("speedrunner"), "a Fase 5 com 2 estrelas não basta")
	assert_has(_won(progress, LEVELS - 1, 3), "speedrunner", "tempo igual ao limite vale")

func test_speedrunner_counts_when_an_earlier_level_is_improved_in_time() -> void:
	var progress = Progress.new()
	progress.add_campaign_time(Achievements.SPEEDRUN_SECONDS - 100.0)
	_won(progress, 0, 2)
	for level in range(1, LEVELS):
		_won(progress, level)
	assert_false(progress.has_achievement("speedrunner"))
	assert_has(_won(progress, 0, 3), "speedrunner", "voltar e tirar 3 estrelas ainda dentro do tempo vale")

func test_speedrunner_misses_by_a_second() -> void:
	var progress = Progress.new()
	progress.add_campaign_time(Achievements.SPEEDRUN_SECONDS + 1.0)
	for level in LEVELS:
		assert_false(_won(progress, level).has("speedrunner"))

func test_an_untimed_campaign_is_never_a_speedrun() -> void:
	var progress = Progress.new()
	progress.void_campaign()
	for level in LEVELS:
		assert_false(_won(progress, level).has("speedrunner"))

func test_every_achievement_has_a_name_and_description() -> void:
	for id: String in Achievements.IDS:
		for locale: String in ["pt_BR", "en"]:
			TranslationServer.set_locale(locale)
			var key := "ACH_%s" % id.to_upper()
			assert_ne(tr(key), key, "%s %s" % [locale, key])
			assert_ne(tr(key + "_DESC"), key + "_DESC", "%s %s" % [locale, key])
	TranslationServer.set_locale("pt_BR")

func test_clock_reads_minutes_and_seconds() -> void:
	assert_eq(Achievements.clock(2347.0), "39:07")
	assert_eq(Achievements.clock(65.9), "1:05")

func test_stars_from_before_the_achievements_count() -> void:
	var progress = Progress.from_dict({"stars": {"0": 3, "1": 3, "2": 3, "3": 3, "4": 3}})
	Achievements.from_stars(progress, LEVELS)
	for level in LEVELS:
		assert_true(progress.has_achievement("level_%d" % (level + 1)))
	assert_true(progress.has_achievement("hero_of_heroes"))
	assert_false(progress.has_achievement(Achievements.HERO), "vencer a Fase 5 não prova que o rei caiu")
	assert_false(progress.has_achievement("speedrunner"))

func test_partial_stars_give_only_the_levels_won() -> void:
	var progress = Progress.from_dict({"stars": {"0": 3, "1": 1}})
	Achievements.from_stars(progress, LEVELS)
	assert_true(progress.has_achievement("level_2"))
	assert_false(progress.has_achievement("level_3"))
	assert_false(progress.has_achievement("hero_of_heroes"))
