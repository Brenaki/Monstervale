extends RefCounted
## Estado de um humano posicionado.

const MAX_LEVEL := 3
const PRIORITIES := ["first", "last", "strongest", "closest"]

var kind: String
var cell: Vector2i
var position: Vector2
var level: int = 1
var spent: int = 0
var priority: String = "first"
var cooldown: float = 0.0
var hp: int = 0
var down_timer: float = 0.0
var blocked: Array = []
var facing: int = 1
var time_since_hit: float = 0.0

var _data: Dictionary
var _recovering: float = 0.0


func _init(unit_kind: String, data: Dictionary, unit_cell: Vector2i, center: Vector2) -> void:
	kind = unit_kind
	cell = unit_cell
	position = center
	_data = data
	spent = stats().cost
	hp = stats().get("hp", 0)


func stats() -> Dictionary:
	return _data.levels[level - 1]


func is_melee() -> bool:
	return _data.attack == "melee"


func damage_type() -> String:
	return _data.damage_type


func is_down() -> bool:
	return down_timer > 0.0


func can_upgrade() -> bool:
	return level < MAX_LEVEL


func upgrade_cost() -> int:
	return _data.levels[level].cost if can_upgrade() else 0


func refund() -> int:
	return spent / 2


func has_block_room() -> bool:
	return is_melee() and not is_down() and blocked.size() < int(stats().get("block", 0))


func raise_level() -> void:
	spent += upgrade_cost()
	var previous_hp: int = stats().get("hp", 0)
	level += 1
	hp += int(stats().get("hp", 0)) - previous_hp


## Recupera vida depois de um tempo sem levar dano, nos níveis que têm regen.
func recover(delta: float) -> void:
	time_since_hit += delta
	var rate: float = stats().get("regen", 0.0)
	if rate <= 0.0 or time_since_hit < float(stats().get("regen_delay", 0.0)):
		return
	_recovering += rate * delta
	var gained := int(_recovering)
	_recovering -= gained
	hp = mini(hp + gained, int(stats().hp))


func cycle_priority() -> void:
	priority = PRIORITIES[(PRIORITIES.find(priority) + 1) % PRIORITIES.size()]
