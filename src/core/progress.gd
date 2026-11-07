extends RefCounted
## Melhor nota de cada fase, tutoriais vistos, conquistas e o relógio da campanha.
## Uma fase abre quando a anterior tem ao menos 1 estrela.

const MAX_STARS := 3
## Relógio parado: save antigo, sem o tempo desde o começo, ou campanha jogada com ajuda do modo dev.
const UNTIMED := -1.0

var _stars := {}
var _tutorials: Array = []
var _achievements: Array = []
## Tempo de jogo desde o Novo jogo, com derrotas e reinícios; UNTIMED quando não vale.
var campaign_seconds := 0.0


static func from_dict(data: Dictionary):
	var progress = new()
	progress._tutorials = _strings(data.get("tutorials", []))
	progress._achievements = _strings(data.get("achievements", []))
	var clock = data.get("campaign_seconds")
	if clock is float or clock is int:
		progress.campaign_seconds = maxf(UNTIMED, float(clock))
	elif data.has("stars"):
		progress.campaign_seconds = UNTIMED
	var saved = data.get("stars", {})
	if not saved is Dictionary:
		return progress
	for key: String in saved:
		if key.is_valid_int() and saved[key] is float:
			progress._stars[key.to_int()] = clampi(int(saved[key]), 0, MAX_STARS)
		elif key.is_valid_int() and saved[key] is int:
			progress._stars[key.to_int()] = clampi(saved[key], 0, MAX_STARS)
	return progress


func to_dict() -> Dictionary:
	var saved := {}
	for level: int in _stars:
		saved[str(level)] = _stars[level]
	return {
		"stars": saved,
		"tutorials": _tutorials.duplicate(),
		"achievements": _achievements.duplicate(),
		"campaign_seconds": campaign_seconds,
	}


static func _strings(list) -> Array:
	var result := []
	if list is Array:
		for item in list:
			if item is String:
				result.append(item)
	return result


func record(level: int, stars: int) -> void:
	_stars[level] = maxi(stars_for(level), stars)


func stars_for(level: int) -> int:
	return _stars.get(level, 0)


func is_unlocked(level: int) -> bool:
	return level == 0 or stars_for(level - 1) >= 1


func furthest_unlocked(level_count: int) -> int:
	var level := 0
	while level + 1 < level_count and is_unlocked(level + 1):
		level += 1
	return level


func saw_tutorial(level_id: String) -> bool:
	return level_id in _tutorials


func mark_tutorial(level_id: String) -> void:
	if not saw_tutorial(level_id):
		_tutorials.append(level_id)


func forget_tutorials() -> void:
	_tutorials.clear()


## Já terminou ao menos uma fase: o título oferece Continuar.
func has_save() -> bool:
	return not _stars.is_empty()


## Começa tudo de novo: estrelas apagadas e relógio zerado; conquistas e tutoriais ficam.
func new_game() -> void:
	_stars.clear()
	campaign_seconds = 0.0


func campaign_timed() -> bool:
	return campaign_seconds >= 0.0


func add_campaign_time(seconds: float) -> void:
	if campaign_timed():
		campaign_seconds += seconds


func void_campaign() -> void:
	campaign_seconds = UNTIMED


## Devolve true só quando a conquista é nova.
func unlock(id: String) -> bool:
	if has_achievement(id):
		return false
	_achievements.append(id)
	return true


func has_achievement(id: String) -> bool:
	return id in _achievements
