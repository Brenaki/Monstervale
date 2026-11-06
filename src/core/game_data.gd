extends RefCounted
## Carrega e valida os arquivos de balanceamento em data/.

const UNITS_PATH := "res://data/units.json"
const MONSTERS_PATH := "res://data/monsters.json"
const LEVELS_DIR := "res://data/levels/"

const DAMAGE_TYPES := ["pierce", "impact", "magic"]
const UNIT_LEVEL_FIELDS := ["cost", "damage", "cooldown", "range", "hp", "respawn"]
const MELEE_LEVEL_FIELDS := ["block"]
const MONSTER_FIELDS := ["hp", "speed", "gold", "damage", "attack_cooldown", "reach", "lives", "resist"]


static func parse_json(text: String) -> Dictionary:
	var json := JSON.new()
	if json.parse(text) != OK or not json.data is Dictionary:
		return {}
	return json.data


static func load_catalog() -> Dictionary:
	return {
		"units": _read(UNITS_PATH),
		"monsters": _read(MONSTERS_PATH),
	}


static func load_level(level_id: String) -> Dictionary:
	return _read("%s%s.json" % [LEVELS_DIR, level_id])


static func validate_catalog(catalog: Dictionary) -> Array:
	var errors := []
	for kind: String in catalog.units:
		errors.append_array(_validate_unit(kind, catalog.units[kind]))
	for kind: String in catalog.monsters:
		errors.append_array(_validate_monster(kind, catalog.monsters[kind]))
	return errors


static func validate_level(level: Dictionary, catalog: Dictionary) -> Array:
	var errors := []
	var label := "fase %s" % level.id
	for kind: String in level.classes:
		if not catalog.units.has(kind):
			errors.append("%s: classe desconhecida %s" % [label, kind])
	if level.waves.is_empty():
		errors.append("%s: sem ondas" % label)
	for i in level.waves.size():
		for group: Dictionary in level.waves[i].groups:
			if not catalog.monsters.has(group.monster):
				errors.append("%s onda %d: monstro desconhecido %s" % [label, i + 1, group.monster])
			if group.count <= 0:
				errors.append("%s onda %d: count deve ser positivo" % [label, i + 1])
	return errors


static func _read(path: String) -> Dictionary:
	return parse_json(FileAccess.get_file_as_string(path))


static func _validate_unit(kind: String, unit: Dictionary) -> Array:
	var levels: Array = unit.levels
	if levels.size() != 3:
		return ["unidade %s: precisa de 3 níveis" % kind]
	var required := UNIT_LEVEL_FIELDS.duplicate()
	if unit.attack == "melee":
		required.append_array(MELEE_LEVEL_FIELDS)
	var errors := []
	for i in levels.size():
		var label := "unidade %s nível %d" % [kind, i + 1]
		for field: String in required:
			if not levels[i].has(field):
				errors.append("%s: falta %s" % [label, field])
		if levels[i].get("cost", 1) <= 0:
			errors.append("%s: cost deve ser positivo" % label)
	return errors


static func _validate_monster(kind: String, monster: Dictionary) -> Array:
	var errors := []
	for field: String in MONSTER_FIELDS:
		if not monster.has(field):
			errors.append("monstro %s: falta %s" % [kind, field])
	for damage_type: String in DAMAGE_TYPES:
		if not monster.get("resist", {}).has(damage_type):
			errors.append("monstro %s: resist sem %s" % [kind, damage_type])
	return errors
