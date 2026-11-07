extends Node2D
## A vila do fim da estrada, montada em peças: a cada quarto das vidas perdido, uma construção
## treme, afunda numa nuvem de poeira e deixa escombros.

signal collapsed(part: String)

const SHEET_PATH := "res://assets/sprites/village_parts.png"
const PARTS_PATH := "res://assets/sprites/village_parts.json"
## Cada construção cai quando as vidas chegam a esta fração das iniciais: com 20, em 15, 10, 5 e 0.
const FALLS := [["well", 0.75], ["red_house", 0.5], ["brown_house", 0.25], ["yellow_house", 0.0]]
const SHAKE_TIME := 0.3
const SHAKE_STEPS := 6
const SINK_TIME := 0.5
## Intervalo entre construções que caem com o mesmo golpe.
const STAGGER := 0.35
const DUST_FPS := 10.0
const DUST_PUFFS := 3
const DUST_SINK := 6

var fallen: Array = []
var parts := {}
var rubble := {}

var _regions: Dictionary
var _sheet: Texture2D
var _dust_frames: SpriteFrames
var _dust: Node2D
var _tweens: Array = []


static func fallen_for(lives: int, start_lives: int) -> Array:
	var result := []
	for fall: Array in FALLS:
		if lives <= start_lives * float(fall[1]):
			result.append(fall[0])
	return result


func _ready() -> void:
	_sheet = load(SHEET_PATH)
	_regions = JSON.parse_string(FileAccess.get_file_as_string(PARTS_PATH))
	_sprite("base")
	for fall: Array in FALLS:
		rubble[fall[0]] = _sprite(fall[0] + "_rubble")
		rubble[fall[0]].visible = false
	for fall: Array in FALLS:
		parts[fall[0]] = _sprite(fall[0])
	_dust = Node2D.new()
	add_child(_dust)
	_dust_frames = _build_dust_frames()


## Derruba o que as vidas pedem. Vidas de volta (recomeço) reconstroem tudo antes.
func show_lives(lives: int, start_lives: int, animate := true) -> void:
	var should := fallen_for(lives, start_lives)
	if should.size() < fallen.size():
		rebuild()
	var delay := 0.0
	for part: String in should:
		if part in fallen:
			continue
		fallen.append(part)
		if animate:
			_collapse(part, delay)
			delay += STAGGER
		else:
			parts[part].visible = false
			rubble[part].visible = true
			rubble[part].modulate.a = 1.0


func rebuild() -> void:
	for tween: Tween in _tweens:
		tween.kill()
	_tweens.clear()
	fallen.clear()
	for part: String in parts:
		var sprite: Sprite2D = parts[part]
		sprite.visible = true
		sprite.region_rect = _rect(part)
		sprite.position = _home(part)
		rubble[part].visible = false
	for puff in _dust.get_children():
		puff.queue_free()


func dust_count() -> int:
	return _dust.get_child_count()


func _collapse(part: String, delay: float) -> void:
	var sprite: Sprite2D = parts[part]
	var piece: Sprite2D = rubble[part]
	var home := _home(part)
	var height: float = _rect(part).size.y
	var tween := create_tween()
	_tweens.append(tween)
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_callback(func(): collapsed.emit(part))
	for i in SHAKE_STEPS:
		var side := 1.0 if i % 2 == 0 else -1.0
		tween.tween_property(sprite, "position", home + Vector2(side, 0), SHAKE_TIME / SHAKE_STEPS)
	tween.tween_callback(func():
		sprite.position = home
		piece.visible = true
		piece.modulate.a = 0.0
		_puff(part))
	tween.tween_method(func(sunk: float): _sink(part, floorf(sunk)), 0.0, height, SINK_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(piece, "modulate:a", 1.0, SINK_TIME)
	tween.tween_callback(func(): sprite.visible = false)


## A construção afunda no chão: desce e perde a parte de baixo, que fica escondida.
func _sink(part: String, sunk: float) -> void:
	var rect := _rect(part)
	parts[part].region_rect = Rect2(rect.position, Vector2(rect.size.x, maxf(1.0, rect.size.y - sunk)))
	parts[part].position = _home(part) + Vector2(0, sunk)


func _puff(part: String) -> void:
	var rect := _rect(part)
	var home := _home(part)
	var dust: Dictionary = _regions.dust
	for i in DUST_PUFFS:
		var puff := AnimatedSprite2D.new()
		puff.sprite_frames = _dust_frames
		puff.centered = false
		var x: float = home.x + (rect.size.x - dust.w) * (i + 0.5) / DUST_PUFFS
		puff.position = Vector2(roundf(x), home.y + rect.size.y - dust.h + DUST_SINK)
		puff.animation_finished.connect(puff.queue_free)
		_dust.add_child(puff)
		puff.play()


func _build_dust_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.set_animation_loop("default", false)
	frames.set_animation_speed("default", DUST_FPS)
	var dust: Dictionary = _regions.dust
	for i in int(dust.frames):
		var atlas := AtlasTexture.new()
		atlas.atlas = _sheet
		atlas.region = Rect2(dust.x + i * dust.w, dust.y, dust.w, dust.h)
		frames.add_frame("default", atlas)
	return frames


func _sprite(name: String) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = name
	sprite.texture = _sheet
	sprite.centered = false
	sprite.region_enabled = true
	sprite.region_rect = _rect(name)
	sprite.position = _home(name)
	add_child(sprite)
	return sprite


func _rect(name: String) -> Rect2:
	var r: Dictionary = _regions[name]
	return Rect2(r.x, r.y, r.w, r.h)


func _home(name: String) -> Vector2:
	var at: Array = _regions[name].at
	return Vector2(at[0], at[1])
