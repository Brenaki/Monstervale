extends GutTest

const EntityView = preload("res://src/game/entity_view.gd")
const Fixtures = preload("res://tests/unit/fixtures.gd")

var sim
var goblin_frames: SpriteFrames
var warrior_frames: SpriteFrames
var archer_frames: SpriteFrames

func before_each() -> void:
	sim = Fixtures.simulation()
	sim.gold = 1000
	goblin_frames = load("res://assets/sprites/goblin.tres")
	warrior_frames = load("res://assets/sprites/warrior.tres")
	archer_frames = load("res://assets/sprites/archer.tres")

func _monster_view():
	var monster = sim.spawn_monster("goblin")
	var view := EntityView.new()
	view.setup(monster, goblin_frames, true)
	add_child_autofree(view)
	return view

func _unit_view(kind: String, frames: SpriteFrames, cell := Vector2i(1, 1)):
	var unit = sim.place_unit(kind, cell)
	var view := EntityView.new()
	view.setup(unit, frames, false)
	add_child_autofree(view)
	return view

func test_walking_monster_plays_walk() -> void:
	var view = _monster_view()
	view.sync(0.0)
	assert_eq(view.current_animation(), "walk")
	assert_true(view.is_animating())

func test_blocked_monster_stands_still() -> void:
	var view = _monster_view()
	view.entity.blocker = sim.place_unit("warrior", Vector2i(1, 1))
	view.sync(0.0)
	assert_false(view.is_animating())

func test_released_monster_walks_again() -> void:
	var view = _monster_view()
	view.entity.blocker = sim.place_unit("warrior", Vector2i(1, 1))
	view.sync(0.0)
	view.entity.blocker = null
	view.sync(0.0)
	assert_true(view.is_animating())

func test_monster_attack_returns_to_base_animation() -> void:
	var view = _monster_view()
	view.play_attack()
	view.sync(0.0)
	assert_eq(view.current_animation(), "attack")
	await wait_seconds(0.6)
	view.sync(0.0)
	assert_eq(view.current_animation(), "walk")

func test_unit_idles_and_attacks() -> void:
	var view = _unit_view("archer", archer_frames)
	view.sync(0.0)
	assert_eq(view.current_animation(), "idle")
	view.play_attack()
	assert_eq(view.current_animation(), "attack")
	await wait_seconds(0.6)
	view.sync(0.0)
	assert_eq(view.current_animation(), "idle")

func test_fallen_melee_plays_fall_and_stays_down() -> void:
	var view = _unit_view("warrior", warrior_frames)
	view.entity.down_timer = 5.0
	view.sync(0.0)
	assert_eq(view.current_animation(), "fall")
	await wait_seconds(0.6)
	view.sync(0.0)
	assert_eq(view.current_animation(), "fall")
	assert_false(view.is_animating())

func test_attack_does_not_interrupt_a_fall() -> void:
	var view = _unit_view("warrior", warrior_frames)
	view.entity.down_timer = 5.0
	view.sync(0.0)
	view.play_attack()
	assert_eq(view.current_animation(), "fall")

func test_unit_returns_to_idle_after_getting_up() -> void:
	var view = _unit_view("warrior", warrior_frames)
	view.entity.down_timer = 5.0
	view.sync(0.0)
	view.entity.down_timer = 0.0
	view.sync(0.0)
	assert_eq(view.current_animation(), "idle")

func test_time_scale_follows_game_speed_and_pause() -> void:
	var view = _unit_view("archer", archer_frames)
	view.sync(0.0, 2.0)
	assert_eq(view.sprite.speed_scale, 2.0)
	view.sync(0.0, 0.0)
	assert_eq(view.sprite.speed_scale, 0.0)

func test_faster_monsters_walk_with_a_faster_cadence() -> void:
	var view = _monster_view()
	view.entity.speed = EntityView.BASE_WALK_SPEED * 2.0
	view.sync(0.0, 1.0)
	assert_almost_eq(view.sprite.speed_scale, 2.0, 0.01)

func test_facing_mirrors_the_sprite() -> void:
	var view = _monster_view()
	view.entity.facing = -1
	view.sync(0.0)
	assert_true(view.sprite.flip_h)

func test_death_plays_and_then_frees_the_view() -> void:
	var monster = sim.spawn_monster("goblin")
	var view := EntityView.new()
	view.setup(monster, goblin_frames, true)
	add_child(view)
	view.play_death()
	assert_eq(view.current_animation(), "death")
	await wait_seconds(1.2)
	assert_false(is_instance_valid(view))

func test_dying_monster_ignores_later_sync() -> void:
	var view = _monster_view()
	view.play_death()
	view.sync(0.0)
	assert_eq(view.current_animation(), "death")

func _level_frames(kind: String) -> Array:
	return [
		load("res://assets/sprites/%s.tres" % kind),
		load("res://assets/sprites/%s_2.tres" % kind),
		load("res://assets/sprites/%s_3.tres" % kind),
	]

func test_upgrade_swaps_the_sprite_sheet() -> void:
	var frames := _level_frames("archer")
	var unit = sim.place_unit("archer", Vector2i(1, 1))
	var view := EntityView.new()
	view.setup(unit, frames[0], false, frames)
	add_child_autofree(view)
	assert_eq(view.sprite.sprite_frames, frames[0])
	sim.upgrade_unit(unit)
	view.sync(0.0)
	assert_eq(view.sprite.sprite_frames, frames[1])
	sim.upgrade_unit(unit)
	view.sync(0.0)
	assert_eq(view.sprite.sprite_frames, frames[2])

func test_upgrade_keeps_the_current_animation() -> void:
	var frames := _level_frames("warrior")
	var unit = sim.place_unit("warrior", Vector2i(1, 1))
	var view := EntityView.new()
	view.setup(unit, frames[0], false, frames)
	add_child_autofree(view)
	view.play_attack()
	sim.upgrade_unit(unit)
	view.sync(0.0)
	assert_eq(view.current_animation(), "attack")
	assert_true(view.is_animating())

func test_fallen_archer_plays_fall() -> void:
	var view = _unit_view("archer", archer_frames)
	view.entity.down_timer = 5.0
	view.sync(0.0)
	assert_eq(view.current_animation(), "fall")
