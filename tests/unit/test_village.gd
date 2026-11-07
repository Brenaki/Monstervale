extends GutTest

const VillageView = preload("res://src/game/village_view.gd")

var village

func before_each() -> void:
	village = VillageView.new()
	add_child_autofree(village)

func test_buildings_fall_at_fifteen_ten_five_and_zero_lives() -> void:
	var expected := {
		20: [], 16: [], 15: ["well"], 11: ["well"], 10: ["well", "red_house"],
		6: ["well", "red_house"], 5: ["well", "red_house", "brown_house"], 1: ["well", "red_house", "brown_house"],
		0: ["well", "red_house", "brown_house", "yellow_house"],
	}
	for lives: int in expected:
		assert_eq(VillageView.fallen_for(lives, 20), expected[lives], "%d vidas" % lives)

func test_other_starting_lives_fall_at_the_same_fractions() -> void:
	assert_eq(VillageView.fallen_for(9, 12), ["well"])
	assert_eq(VillageView.fallen_for(10, 12), [])

func test_a_fallen_building_leaves_rubble() -> void:
	village.show_lives(15, 20, false)
	assert_eq(village.fallen, ["well"])
	assert_false(village.parts["well"].visible)
	assert_true(village.rubble["well"].visible)
	assert_true(village.parts["red_house"].visible)
	assert_false(village.rubble["red_house"].visible)

func test_a_big_hit_brings_down_several_buildings() -> void:
	village.show_lives(20, 20, false)
	village.show_lives(4, 20, false)
	assert_eq(village.fallen, ["well", "red_house", "brown_house"])

func test_the_collapse_shakes_sinks_and_raises_dust() -> void:
	watch_signals(village)
	village.show_lives(15, 20)
	await wait_seconds(0.05)
	assert_signal_emitted_with_parameters(village, "collapsed", ["well"])
	assert_true(village.parts["well"].visible, "primeiro treme")
	await wait_seconds(VillageView.SHAKE_TIME + 0.05)
	assert_true(village.rubble["well"].visible)
	assert_gt(village.dust_count(), 0)
	await wait_seconds(VillageView.SINK_TIME)
	assert_false(village.parts["well"].visible)

func test_restarting_rebuilds_the_village() -> void:
	village.show_lives(5, 20, false)
	village.show_lives(20, 20, false)
	assert_eq(village.fallen, [])
	for part: String in village.parts:
		assert_true(village.parts[part].visible, part)
		assert_false(village.rubble[part].visible, part)
