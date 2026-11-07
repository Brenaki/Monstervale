extends RefCounted

const Simulation = preload("res://src/core/simulation.gd")

const PATH_CELL := Vector2i(0, 0)

static func catalog() -> Dictionary:
	return {
		"units": {
			"archer": {
				"attack": "ranged", "damage_type": "pierce",
				"levels": [
					{"cost": 40, "damage": 5, "cooldown": 1.0, "range": 100.0, "hp": 20, "respawn": 5.0},
					{"cost": 30, "damage": 8, "cooldown": 1.0, "range": 110.0, "hp": 30, "respawn": 5.0},
					{"cost": 50, "damage": 10, "cooldown": 1.0, "range": 120.0, "hp": 40, "respawn": 5.0, "pierce_extra": 1, "pierce_radius": 40.0},
				],
			},
			"warrior": {
				"attack": "melee", "damage_type": "impact",
				"levels": [
					{"cost": 50, "damage": 5, "cooldown": 1.0, "range": 60.0, "hp": 20, "block": 1, "respawn": 5.0},
					{"cost": 40, "damage": 7, "cooldown": 1.0, "range": 60.0, "hp": 30, "block": 1, "respawn": 5.0, "regen": 2.0, "regen_delay": 3.0},
					{"cost": 60, "damage": 9, "cooldown": 1.0, "range": 60.0, "hp": 40, "block": 2, "respawn": 5.0, "damage_taken": 0.5, "regen": 4.0, "regen_delay": 3.0},
				],
			},
			"spearman": {
				"attack": "melee", "damage_type": "pierce",
				"levels": [
					{"cost": 50, "damage": 5, "cooldown": 1.0, "range": 70.0, "block_range": 40.0, "hp": 30, "block": 1, "respawn": 5.0},
					{"cost": 40, "damage": 7, "cooldown": 1.0, "range": 70.0, "block_range": 40.0, "hp": 40, "block": 1, "respawn": 5.0},
					{"cost": 60, "damage": 9, "cooldown": 1.0, "range": 70.0, "block_range": 40.0, "hp": 50, "block": 2, "respawn": 5.0, "line_width": 10.0},
				],
			},
			"druid": {
				"attack": "ranged", "damage_type": "magic",
				"levels": [
					{"cost": 50, "damage": 2, "cooldown": 1.0, "range": 100.0, "hp": 15, "respawn": 5.0, "slow": {"factor": 0.5, "seconds": 2.0}},
					{"cost": 40, "damage": 3, "cooldown": 1.0, "range": 100.0, "hp": 20, "respawn": 5.0, "slow": {"factor": 0.5, "seconds": 2.0}},
					{"cost": 60, "damage": 4, "cooldown": 1.0, "range": 100.0, "hp": 25, "respawn": 5.0, "slow": {"factor": 0.5, "seconds": 2.0}, "root": {"every": 3, "seconds": 1.5}},
				],
			},
			"monk": {
				"attack": "melee", "damage_type": "impact",
				"levels": [
					{"cost": 50, "damage": 3, "cooldown": 0.5, "range": 60.0, "hp": 20, "block": 1, "respawn": 5.0},
					{"cost": 40, "damage": 5, "cooldown": 0.5, "range": 60.0, "hp": 30, "block": 1, "respawn": 5.0},
					{"cost": 60, "damage": 7, "cooldown": 0.5, "range": 60.0, "hp": 40, "block": 2, "respawn": 5.0, "stun": {"every": 3, "seconds": 1.0}},
				],
			},
			"rogue": {
				"attack": "ranged", "damage_type": "pierce",
				"levels": [
					{"cost": 50, "damage": 4, "cooldown": 1.0, "range": 60.0, "hp": 20, "respawn": 5.0, "crit": {"every": 3, "multiplier": 2.5}},
					{"cost": 40, "damage": 6, "cooldown": 1.0, "range": 60.0, "hp": 30, "respawn": 5.0, "crit": {"every": 3, "multiplier": 2.5}},
					{"cost": 60, "damage": 8, "cooldown": 1.0, "range": 60.0, "hp": 40, "respawn": 5.0, "crit": {"every": 3, "multiplier": 2.5}, "kill_gold": 2},
				],
			},
			"mage": {
				"attack": "ranged", "damage_type": "magic",
				"levels": [
					{"cost": 60, "damage": 4, "cooldown": 1.0, "range": 100.0, "hp": 15, "respawn": 5.0, "splash_radius": 30.0, "splash_targets": 5},
					{"cost": 40, "damage": 6, "cooldown": 1.0, "range": 100.0, "hp": 20, "respawn": 5.0, "splash_radius": 30.0, "splash_targets": 5},
					{"cost": 70, "damage": 8, "cooldown": 1.0, "range": 100.0, "hp": 25, "respawn": 5.0, "splash_radius": 30.0, "splash_targets": 5,
						"fire": {"radius": 30.0, "damage": 2, "interval": 0.5, "seconds": 2.0}},
				],
			},
		},
		"monsters": {
			"goblin": {
				"hp": 10, "speed": 10.0, "gold": 3, "damage": 4, "attack_cooldown": 1.0, "reach": 40.0, "lives": 1,
				"resist": {"pierce": 1.0, "impact": 1.0, "magic": 1.0},
			},
			"brute": {
				"hp": 40, "speed": 10.0, "gold": 8, "damage": 4, "attack_cooldown": 1.0, "reach": 40.0, "lives": 3,
				"resist": {"pierce": 0.5, "impact": 2.0, "magic": 1.0},
			},
			"slime": {
				"hp": 10, "speed": 10.0, "gold": 2, "damage": 2, "attack_cooldown": 1.0, "reach": 40.0, "lives": 2,
				"resist": {"pierce": 1.0, "impact": 1.0, "magic": 1.0},
				"split": {"into": "slimelet", "count": 2},
			},
			"slimelet": {
				"hp": 4, "speed": 20.0, "gold": 0, "damage": 1, "attack_cooldown": 1.0, "reach": 40.0, "lives": 1,
				"resist": {"pierce": 1.0, "impact": 1.0, "magic": 1.0},
			},
		},
	}

static func level(waves: Array = []) -> Dictionary:
	return {
		"start_gold": 100,
		"lives": 10,
		"classes": ["archer", "warrior", "mage", "spearman", "druid", "monk", "rogue"],
		"wave_interval": 10.0,
		"early_call_gold_per_second": 1.0,
		"route": [Vector2(0, 0), Vector2(200, 0)],
		"buildable": {Vector2i(2, 2): true, Vector2i(3, 2): true, Vector2i(1, 1): true, Vector2i(2, 1): true},
		"cell_size": 32,
		"waves": waves,
	}

static func simulation(waves: Array = []) -> Simulation:
	return Simulation.new(catalog(), level(waves))

static func group(monster: String, count: int = 1, interval: float = 1.0, delay: float = 0.0) -> Dictionary:
	return {"monster": monster, "count": count, "interval": interval, "delay": delay}

static func wave(groups: Array, bonus: int = 0) -> Dictionary:
	return {"groups": groups, "bonus": bonus}
