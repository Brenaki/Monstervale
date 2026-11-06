extends RefCounted
## Melhor nota de cada fase. Uma fase abre quando a anterior tem ao menos 1 estrela.

const MAX_STARS := 3

var _stars := {}


static func from_dict(data: Dictionary):
	var progress = new()
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
	return {"stars": saved}


func record(level: int, stars: int) -> void:
	_stars[level] = maxi(stars_for(level), stars)


func stars_for(level: int) -> int:
	return _stars.get(level, 0)


func is_unlocked(level: int) -> bool:
	return level == 0 or stars_for(level - 1) >= 1
