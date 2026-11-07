extends "res://tests/unit/two_entrance_level.gd"

const Overlay = preload("res://src/game/overlay.gd")
const HUD_TOP_HEIGHT := 24.0

func _level_id() -> String:
	return "level_05"

func test_outskirts_use_their_own_tiles() -> void:
	var ground: TileMapLayer = scene.get_node("Ground")
	assert_string_contains(ground.tile_set.resource_path, "outskirts")

func test_second_entrance_comes_from_the_top_of_the_map() -> void:
	assert_eq(level.routes.size(), 2)
	assert_lt(level.routes[1][0].y, 0.0)
	assert_eq(level.routes[0][-1], level.routes[1][-1])

func test_entry_arrow_of_the_top_entrance_shows_below_the_hud() -> void:
	var tip: Vector2 = Overlay.entry_tip(_routes()[1])
	assert_gt(tip.y, HUD_TOP_HEIGHT + Overlay.ENTRY_ARROW_LENGTH)

func test_the_slime_king_comes_only_in_the_last_wave() -> void:
	for i in level.waves.size():
		var kinds: Array = level.waves[i].groups.map(func(group): return group.monster)
		assert_eq("slime_king" in kinds, i == level.waves.size() - 1, "onda %d" % (i + 1))

func test_outskirts_offer_all_seven_classes() -> void:
	assert_eq(level.classes.size(), 7)
