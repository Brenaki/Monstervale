extends Node2D
## Desenha um monstro ou humano a partir do estado da simulação.

const FLASH_SHADER = preload("res://src/game/flash.gdshader")
const FOOT_OFFSET := Vector2(0, 8)
const SPRITE_OFFSET_Y := -16.0
const BAR_WIDTH := 16
const BAR_Y := -24.0
const BASE_WALK_SPEED := 24.0
const FLASH_SECONDS := 0.12
const FADE_SECONDS := 0.2

var entity
var is_monster := false
var sprite: AnimatedSprite2D

var _base_modulate := Color.WHITE
var _attacking := false
var _dying := false
var _fallen := false


func setup(state, frames: SpriteFrames, monster: bool, tint := Color.WHITE) -> void:
	entity = state
	is_monster = monster
	_base_modulate = tint
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.offset = Vector2(0, SPRITE_OFFSET_Y)
	sprite.modulate = tint
	var material := ShaderMaterial.new()
	material.shader = FLASH_SHADER
	sprite.material = material
	sprite.animation_finished.connect(_on_animation_finished)
	add_child(sprite)
	sprite.play(_base_animation())
	sync(0.0)


func sync(_delta: float, time_scale := 1.0) -> void:
	sprite.speed_scale = time_scale * _cadence()
	if _dying:
		return
	if is_monster:
		position = entity.position() + FOOT_OFFSET
	else:
		position = entity.position + FOOT_OFFSET
	sprite.flip_h = entity.facing < 0
	_update_fall()
	_update_base_animation()
	queue_redraw()


func current_animation() -> String:
	return sprite.animation


func is_animating() -> bool:
	return sprite.is_playing()


func flash() -> void:
	var material: ShaderMaterial = sprite.material
	material.set_shader_parameter("flash", 1.0)
	create_tween().tween_property(material, "shader_parameter/flash", 0.0, FLASH_SECONDS)


func play_attack() -> void:
	if _dying or _fallen:
		return
	_attacking = true
	sprite.speed_scale = 1.0
	sprite.play("attack")


func play_death() -> void:
	_dying = true
	_attacking = false
	sprite.speed_scale = 1.0
	sprite.play("death")
	queue_redraw()


func _cadence() -> float:
	if is_monster and not _dying and not _attacking:
		return entity.speed / BASE_WALK_SPEED
	return 1.0


func _base_animation() -> String:
	return "walk" if is_monster else "idle"


func _update_fall() -> void:
	if is_monster:
		return
	var down: bool = entity.is_down()
	if down and not _fallen:
		_fallen = true
		_attacking = false
		sprite.play("fall")
	elif not down and _fallen:
		_fallen = false
		sprite.play("idle")


func _update_base_animation() -> void:
	if _attacking or _fallen:
		return
	if is_monster and entity.blocker != null:
		if sprite.is_playing() or sprite.animation != &"walk":
			sprite.animation = &"walk"
			sprite.frame = 0
			sprite.stop()
		return
	if not sprite.is_playing() or sprite.animation != _base_animation():
		sprite.play(_base_animation())


func _on_animation_finished() -> void:
	if _dying:
		var tween := create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, FADE_SECONDS)
		tween.tween_callback(queue_free)
	elif _attacking:
		_attacking = false
		sprite.play(_base_animation())


func _draw() -> void:
	if _dying:
		return
	draw_set_transform(Vector2(0, 0), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 10.0, Color(0.1, 0.08, 0.15, 0.35))
	draw_set_transform(Vector2.ZERO)
	var max_hp := _max_hp()
	if max_hp > 0 and entity.hp < max_hp:
		var left := Vector2(-BAR_WIDTH / 2.0, BAR_Y)
		draw_rect(Rect2(left, Vector2(BAR_WIDTH, 2)), Color("1b1626"))
		var fill := BAR_WIDTH * float(entity.hp) / max_hp
		draw_rect(Rect2(left, Vector2(fill, 2)), Color("d9534a") if is_monster else Color("7fbb4e"))
	if not is_monster:
		for i in entity.level:
			draw_rect(Rect2(Vector2(-6 + i * 4, 3), Vector2(2, 2)), Color("f6e05e"))


func _max_hp() -> int:
	if is_monster:
		return entity.max_hp
	return int(entity.stats().get("hp", 0))
