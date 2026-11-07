extends GutTest

const Progress = preload("res://src/core/progress.gd")

func test_first_level_starts_unlocked() -> void:
	assert_true(Progress.new().is_unlocked(0))
	assert_false(Progress.new().is_unlocked(1))

func test_one_star_unlocks_next_level() -> void:
	var progress := Progress.new()
	progress.record(0, 1)
	assert_true(progress.is_unlocked(1))
	assert_false(progress.is_unlocked(2))

func test_keeps_best_stars() -> void:
	var progress := Progress.new()
	progress.record(0, 3)
	progress.record(0, 1)
	assert_eq(progress.stars_for(0), 3)

func test_round_trip_through_dictionary() -> void:
	var progress := Progress.new()
	progress.record(2, 2)
	var restored = Progress.from_dict(JSON.parse_string(JSON.stringify(progress.to_dict())))
	assert_eq(restored.stars_for(2), 2)

func test_corrupt_save_starts_empty() -> void:
	assert_eq(Progress.from_dict({"stars": "lixo"}).stars_for(0), 0)
	assert_eq(Progress.from_dict({"stars": {"0": 99, "x": 2}}).stars_for(0), 3)

func test_furthest_unlocked_starts_at_the_first_level() -> void:
	assert_eq(Progress.new().furthest_unlocked(5), 0)

func test_furthest_unlocked_follows_the_stars() -> void:
	var progress = Progress.new()
	progress.record(0, 1)
	progress.record(1, 2)
	assert_eq(progress.furthest_unlocked(5), 2)

func test_furthest_unlocked_never_passes_the_last_level() -> void:
	var progress = Progress.new()
	progress.record(0, 3)
	progress.record(1, 3)
	assert_eq(progress.furthest_unlocked(2), 1)

func test_seen_tutorials_are_saved() -> void:
	var progress = Progress.new()
	assert_false(progress.saw_tutorial("level_01"))
	progress.mark_tutorial("level_01")
	var restored = Progress.from_dict(JSON.parse_string(JSON.stringify(progress.to_dict())))
	assert_true(restored.saw_tutorial("level_01"))
	assert_false(restored.saw_tutorial("level_02"))

func test_tutorials_can_be_seen_again() -> void:
	var progress = Progress.new()
	progress.record(0, 3)
	progress.mark_tutorial("level_01")
	progress.forget_tutorials()
	assert_false(progress.saw_tutorial("level_01"))
	assert_eq(progress.stars_for(0), 3, "as estrelas ficam")

func test_broken_tutorial_list_is_ignored() -> void:
	assert_false(Progress.from_dict({"tutorials": "lixo"}).saw_tutorial("level_01"))
	assert_true(Progress.from_dict({"tutorials": ["level_01", 3]}).saw_tutorial("level_01"))

func test_a_save_exists_once_a_level_is_finished() -> void:
	var progress = Progress.new()
	assert_false(progress.has_save())
	progress.record(0, 1)
	assert_true(progress.has_save())

func test_new_game_clears_the_stars_but_keeps_achievements_and_tutorials() -> void:
	var progress = Progress.new()
	progress.record(0, 3)
	progress.unlock("level_1")
	progress.mark_tutorial("level_01")
	progress.add_campaign_time(100.0)
	progress.new_game()
	assert_false(progress.has_save())
	assert_false(progress.is_unlocked(1))
	assert_true(progress.has_achievement("level_1"))
	assert_true(progress.saw_tutorial("level_01"))
	assert_eq(progress.campaign_seconds, 0.0)

func test_achievements_unlock_once_and_are_saved() -> void:
	var progress = Progress.new()
	assert_true(progress.unlock("hero"))
	assert_false(progress.unlock("hero"), "a segunda vez não é novidade")
	var restored = Progress.from_dict(JSON.parse_string(JSON.stringify(progress.to_dict())))
	assert_true(restored.has_achievement("hero"))
	assert_false(restored.has_achievement("speedrunner"))

func test_a_fresh_game_times_the_campaign() -> void:
	var progress = Progress.new()
	progress.add_campaign_time(30.5)
	progress.add_campaign_time(10.0)
	var restored = Progress.from_dict(JSON.parse_string(JSON.stringify(progress.to_dict())))
	assert_almost_eq(restored.campaign_seconds, 40.5, 0.001)

func test_an_old_save_without_a_clock_is_not_timed_until_a_new_game() -> void:
	var progress = Progress.from_dict({"stars": {"0": 3}})
	assert_false(progress.campaign_timed())
	progress.add_campaign_time(10.0)
	assert_false(progress.campaign_timed())
	progress.new_game()
	assert_true(progress.campaign_timed())

func test_a_campaign_with_help_loses_its_clock() -> void:
	var progress = Progress.new()
	progress.add_campaign_time(10.0)
	progress.void_campaign()
	assert_false(progress.campaign_timed())
	assert_false(Progress.from_dict(progress.to_dict()).campaign_timed())
