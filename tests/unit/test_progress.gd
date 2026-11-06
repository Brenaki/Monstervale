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
