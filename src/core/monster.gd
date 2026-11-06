extends RefCounted
## Estado de um monstro em campo.

var kind: String
var hp: int
var max_hp: int
var speed: float
var gold: int
var damage: int
var attack_cooldown: float
var lives: int
var resist: Dictionary
var distance: float = 0.0
var facing: int = 1
var cooldown: float = 0.0
var blocker = null
var wave = null

var _route


func _init(monster_kind: String, data: Dictionary, route) -> void:
	kind = monster_kind
	hp = data.hp
	max_hp = data.hp
	speed = data.speed
	gold = data.gold
	damage = data.damage
	attack_cooldown = data.attack_cooldown
	lives = data.lives
	resist = data.resist
	_route = route


func position() -> Vector2:
	return _route.position_at(distance)


func damage_from(amount: int, damage_type: String) -> int:
	return maxi(1, roundi(amount * float(resist.get(damage_type, 1.0))))
