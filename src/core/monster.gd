extends RefCounted
## Estado de um monstro em campo.

var kind: String
var hp: int
var max_hp: int
var speed: float
var gold: int
var damage: int
var attack_cooldown: float
var reach: float
var lives: int
var resist: Dictionary
var distance: float = 0.0
var facing: int = 1
var cooldown: float = 0.0
var blocker = null
var wave = null
var route_index: int = 0
var slow_factor: float = 1.0
var slow_timer: float = 0.0
var root_timer: float = 0.0
var stun_timer: float = 0.0
var boss := false
var immune: Array = []
var sheds := 0

var _route


func _init(monster_kind: String, data: Dictionary, route, index: int = 0) -> void:
	kind = monster_kind
	hp = data.hp
	max_hp = data.hp
	speed = data.speed
	gold = data.gold
	damage = data.damage
	attack_cooldown = data.attack_cooldown
	reach = data.reach
	lives = data.lives
	resist = data.resist
	boss = data.get("boss", false)
	immune = data.get("immune", [])
	_route = route
	route_index = index


func position() -> Vector2:
	return _route.position_at(distance)


func damage_from(amount: int, damage_type: String) -> int:
	return maxi(1, roundi(amount * float(resist.get(damage_type, 1.0))))


func route_length() -> float:
	return _route.length


func horizontal_direction() -> int:
	return _route.horizontal_direction_at(distance)


func current_speed() -> float:
	return 0.0 if is_rooted() or is_stunned() else speed * (slow_factor if is_slowed() else 1.0)


func is_slowed() -> bool:
	return slow_timer > 0.0


func is_rooted() -> bool:
	return root_timer > 0.0


func is_stunned() -> bool:
	return stun_timer > 0.0


## Um efeito mais fraco não substitui um mais forte que ainda está valendo.
func apply_slow(factor: float, seconds: float) -> void:
	if is_slowed() and factor > slow_factor:
		return
	slow_factor = factor
	slow_timer = seconds


func can_be_blocked() -> bool:
	return not "block" in immune


func apply_root(seconds: float) -> void:
	if "root" in immune:
		return
	root_timer = maxf(root_timer, seconds)


func apply_stun(seconds: float) -> void:
	if "stun" in immune:
		return
	stun_timer = maxf(stun_timer, seconds)


func update_effects(delta: float) -> void:
	slow_timer = maxf(0.0, slow_timer - delta)
	root_timer = maxf(0.0, root_timer - delta)
	stun_timer = maxf(0.0, stun_timer - delta)
