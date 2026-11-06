extends GutTest

const GameData = preload("res://src/core/game_data.gd")
const Fixtures = preload("res://tests/unit/fixtures.gd")

func _level() -> Dictionary:
	return {
		"id": "x", "start_gold": 10, "lives": 5, "classes": ["archer"], "wave_interval": 5.0,
		"early_call_gold_per_second": 1.0,
		"waves": [{"bonus": 1, "groups": [{"monster": "goblin", "count": 2, "interval": 1.0, "delay": 0.0}]}],
	}

func test_valid_catalog_has_no_errors() -> void:
	assert_eq(GameData.validate_catalog(Fixtures.catalog()), [])

func test_unit_needs_three_levels() -> void:
	var catalog := Fixtures.catalog()
	catalog.units.archer.levels.pop_back()
	assert_eq(GameData.validate_catalog(catalog), ["unidade archer: precisa de 3 níveis"])

func test_melee_level_needs_hp_block_and_respawn() -> void:
	var catalog := Fixtures.catalog()
	catalog.units.warrior.levels[0].erase("block")
	assert_eq(GameData.validate_catalog(catalog), ["unidade warrior nível 1: falta block"])

func test_every_class_needs_hp_and_respawn_because_all_can_fall() -> void:
	var catalog := Fixtures.catalog()
	catalog.units.archer.levels[0].erase("hp")
	catalog.units.archer.levels[1].erase("respawn")
	assert_eq(GameData.validate_catalog(catalog), ["unidade archer nível 1: falta hp", "unidade archer nível 2: falta respawn"])

func test_unit_level_needs_positive_cost() -> void:
	var catalog := Fixtures.catalog()
	catalog.units.archer.levels[1].cost = 0
	assert_eq(GameData.validate_catalog(catalog), ["unidade archer nível 2: cost deve ser positivo"])

func test_monster_needs_all_fields() -> void:
	var catalog := Fixtures.catalog()
	catalog.monsters.goblin.erase("speed")
	assert_eq(GameData.validate_catalog(catalog), ["monstro goblin: falta speed"])

func test_monster_resist_covers_every_damage_type() -> void:
	var catalog := Fixtures.catalog()
	catalog.monsters.goblin.resist.erase("magic")
	assert_eq(GameData.validate_catalog(catalog), ["monstro goblin: resist sem magic"])

func test_valid_level_has_no_errors() -> void:
	assert_eq(GameData.validate_level(_level(), Fixtures.catalog()), [])

func test_level_rejects_unknown_class() -> void:
	var level := _level()
	level.classes = ["bard"]
	assert_eq(GameData.validate_level(level, Fixtures.catalog()), ["fase x: classe desconhecida bard"])

func test_level_rejects_unknown_monster() -> void:
	var level := _level()
	level.waves[0].groups[0].monster = "dragon"
	assert_eq(GameData.validate_level(level, Fixtures.catalog()), ["fase x onda 1: monstro desconhecido dragon"])

func test_level_needs_a_wave() -> void:
	var level := _level()
	level.waves = []
	assert_eq(GameData.validate_level(level, Fixtures.catalog()), ["fase x: sem ondas"])

func test_group_needs_positive_count() -> void:
	var level := _level()
	level.waves[0].groups[0].count = 0
	assert_eq(GameData.validate_level(level, Fixtures.catalog()), ["fase x onda 1: count deve ser positivo"])

func test_parse_reports_invalid_json() -> void:
	assert_eq(GameData.parse_json("{nope"), {})

func test_shipped_catalog_is_valid() -> void:
	assert_eq(GameData.validate_catalog(GameData.load_catalog()), [])

func test_shipped_level_is_valid() -> void:
	var catalog := GameData.load_catalog()
	assert_eq(GameData.validate_level(GameData.load_level("level_01"), catalog), [])
