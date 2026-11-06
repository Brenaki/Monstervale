extends GutTest
## Protege as animações contra sprites sem quadros, quadros iguais e pés fora do chão.

const MONSTER_ANIMATIONS := {"walk": 4, "attack": 3, "death": 2}
const HUMAN_ANIMATIONS := {"idle": 2, "attack": 3, "fall": 2}
const REQUIRED := {
	"goblin": MONSTER_ANIMATIONS,
	"goblin_fast": MONSTER_ANIMATIONS,
	"goblin_shield": MONSTER_ANIMATIONS,
	"archer": HUMAN_ANIMATIONS,
	"archer_2": HUMAN_ANIMATIONS,
	"archer_3": HUMAN_ANIMATIONS,
	"warrior": HUMAN_ANIMATIONS,
	"warrior_2": HUMAN_ANIMATIONS,
	"warrior_3": HUMAN_ANIMATIONS,
}
const GROUNDED := ["walk", "idle", "attack"]

func _frames(sprite: String) -> SpriteFrames:
	return load("res://assets/sprites/%s.tres" % sprite)

func _image(frames: SpriteFrames, animation: String, index: int) -> Image:
	var atlas: AtlasTexture = frames.get_frame_texture(animation, index)
	return atlas.atlas.get_image().get_region(Rect2i(atlas.region))

func test_animations_respect_the_agreed_frame_count() -> void:
	for sprite: String in REQUIRED:
		var frames := _frames(sprite)
		for animation: String in REQUIRED[sprite]:
			assert_true(frames.has_animation(animation), "%s sem %s" % [sprite, animation])
			assert_eq(frames.get_frame_count(animation), REQUIRED[sprite][animation], "%s %s" % [sprite, animation])

func test_consecutive_frames_really_change() -> void:
	for sprite: String in REQUIRED:
		var frames := _frames(sprite)
		for animation: String in REQUIRED[sprite]:
			for i in frames.get_frame_count(animation) - 1:
				var a := _image(frames, animation, i).get_data()
				var b := _image(frames, animation, i + 1).get_data()
				assert_ne(a, b, "%s %s quadro %d igual ao seguinte" % [sprite, animation, i])

func test_feet_stay_on_the_same_ground_line() -> void:
	for sprite: String in REQUIRED:
		var frames := _frames(sprite)
		var ground := -1
		for animation: String in GROUNDED:
			if not frames.has_animation(animation):
				continue
			for i in frames.get_frame_count(animation):
				var bottom := _image(frames, animation, i).get_used_rect().end.y
				if ground == -1:
					ground = bottom
				assert_eq(bottom, ground, "%s %s quadro %d" % [sprite, animation, i])

func test_body_is_centered_so_mirroring_does_not_jump() -> void:
	for sprite: String in REQUIRED:
		var frames := _frames(sprite)
		var animation: String = "walk" if frames.has_animation("walk") else "idle"
		var image := _image(frames, animation, 0)
		var feet_row := image.get_used_rect().end.y - 2
		var left := -1
		var right := -1
		for x in image.get_width():
			if image.get_pixel(x, feet_row).a > 0.0:
				if left == -1:
					left = x
				right = x
		assert_almost_eq((left + right) / 2.0, image.get_width() / 2.0, 3.0, sprite)

func test_nothing_touches_the_canvas_edge() -> void:
	for sprite: String in REQUIRED:
		var frames := _frames(sprite)
		for animation: String in REQUIRED[sprite]:
			for i in frames.get_frame_count(animation):
				var image := _image(frames, animation, i)
				var used := image.get_used_rect()
				assert_gt(used.position.x, 0, "%s %s %d cortado à esquerda" % [sprite, animation, i])
				assert_lt(used.end.x, image.get_width(), "%s %s %d cortado à direita" % [sprite, animation, i])
				assert_gt(used.position.y, 0, "%s %s %d cortado em cima" % [sprite, animation, i])

func test_attacks_are_short_enough_for_the_fastest_cooldown() -> void:
	for sprite: String in REQUIRED:
		var frames := _frames(sprite)
		var total := 0.0
		for i in frames.get_frame_count("attack"):
			total += frames.get_frame_duration("attack", i) / frames.get_animation_speed("attack")
		assert_lt(total, 0.8, sprite)

func _assert_all_different(sprites: Array, animation: String) -> void:
	var seen := {}
	for sprite: String in sprites:
		var data := _image(_frames(sprite), animation, 0).get_data()
		assert_false(seen.has(data), "%s igual a %s" % [sprite, seen.get(data, "")])
		seen[data] = sprite

func test_goblin_variants_look_different_from_each_other() -> void:
	_assert_all_different(["goblin", "goblin_fast", "goblin_shield"], "walk")

func test_every_human_level_has_its_own_look() -> void:
	_assert_all_different(["archer", "archer_2", "archer_3"], "idle")
	_assert_all_different(["warrior", "warrior_2", "warrior_3"], "idle")

func _opaque_pixels(sprite: String, animation: String, index: int) -> int:
	var image := _image(_frames(sprite), animation, index)
	var count := 0
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a > 0.0:
				count += 1
	return count

func test_shield_goblin_carries_more_than_the_base_goblin() -> void:
	assert_gt(_opaque_pixels("goblin_shield", "walk", 0), _opaque_pixels("goblin", "walk", 0))

func test_level_three_warrior_has_a_bigger_silhouette() -> void:
	assert_gt(_opaque_pixels("warrior_3", "idle", 0), _opaque_pixels("warrior", "idle", 0))
