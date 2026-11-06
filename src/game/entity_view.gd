extends Node2D
## Desenha um monstro ou humano a partir do estado da simulação.

const FLASH_SHADER = preload("res://src/game/flash.gdshader")
const FOOT_OFFSET := Vector2(0, 8)
const SPRITE_OFFSET_Y := -14.0
const BAR_WIDTH := 16
const BOB_RATE := 0.45
const FLASH_SECONDS := 0.12
const LUNGE_PIXELS := 4.0

var entity
var is_monster := false

var _sprite: AnimatedSprite2D
var _base_modulate := Color.WHITE
var _time := 0.0


func setup(state, frames: SpriteFrames, monster: bool, tint := Color.WHITE) -> void:
	entity = state
	is_monster = monster
	_base_modulate = tint
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = frames
	_sprite.animation = &"idle"
	_sprite.offset = Vector2(0, SPRITE_OFFSET_Y)
	_sprite.modulate = tint
	var material := ShaderMaterial.new()
	material.shader = FLASH_SHADER
	_sprite.material = material
	add_child(_sprite)
	sync(0.0)


func sync(delta: float) -> void:
	_time += delta
	if is_monster:
		position = entity.position() + FOOT_OFFSET
		_sprite.flip_h = entity.facing < 0
		var walking: bool = entity.blocker == null
		_sprite.position.y = -abs(sin(_time * entity.speed * BOB_RATE)) * 2.0 if walking else 0.0
	else:
		position = entity.position + FOOT_OFFSET
		_sprite.flip_h = entity.facing < 0
		var down: bool = entity.is_down()
		_sprite.rotation = PI / 2.0 if down else 0.0
		_sprite.modulate = Color(0.5, 0.5, 0.55) if down else _base_modulate
	queue_redraw()


func flash() -> void:
	var material: ShaderMaterial = _sprite.material
	material.set_shader_parameter("flash", 1.0)
	create_tween().tween_property(material, "shader_parameter/flash", 0.0, FLASH_SECONDS)


func lunge(direction: int) -> void:
	var tween := create_tween()
	tween.tween_property(_sprite, "position:x", direction * LUNGE_PIXELS, 0.06)
	tween.tween_property(_sprite, "position:x", 0.0, 0.1)


func _draw() -> void:
	draw_set_transform(Vector2(0, 0), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 10.0, Color(0.1, 0.08, 0.15, 0.35))
	draw_set_transform(Vector2.ZERO)
	var max_hp := _max_hp()
	if max_hp > 0 and entity.hp < max_hp:
		var left := Vector2(-BAR_WIDTH / 2.0, -34)
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
