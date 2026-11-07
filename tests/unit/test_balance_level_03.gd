extends GutTest
## Protege contra erros grosseiros na Fase 3. A dificuldade é avaliada com as partidas reais.

const GameData = preload("res://src/core/game_data.gd")
const LevelReader = preload("res://src/game/level_reader.gd")
const Simulation = preload("res://src/core/simulation.gd")

const STEP := 1.0 / 20.0
const MAX_SECONDS := 1800.0
const FRONT := Vector2i(12, 5)
const FRONT_2 := Vector2i(10, 5)
const FRONT_3 := Vector2i(14, 5)
const SUPPORT := Vector2i(11, 5)
const SUPPORT_2 := Vector2i(9, 5)
const SUPPORT_3 := Vector2i(12, 7)
const SUPPORT_4 := Vector2i(12, 3)

var scene: Node

func before_each() -> void:
	scene = load("res://src/game/levels/level_03.tscn").instantiate()
	add_child_autofree(scene)

## Abre com dois humanos e evolui cedo, como nas partidas reais, sem chamar ondas.
func _plan(front: String, support: String, support_2: String, extra: String) -> Array:
	return [
		["place", front, FRONT], ["place", support, SUPPORT], ["upgrade", FRONT], ["upgrade", SUPPORT],
		["upgrade", FRONT], ["place", front, FRONT_2], ["upgrade", FRONT_2], ["upgrade", SUPPORT],
		["upgrade", FRONT_2], ["place", support_2, SUPPORT_2], ["upgrade", SUPPORT_2], ["upgrade", SUPPORT_2],
		["place", extra, SUPPORT_4], ["upgrade", SUPPORT_4], ["place", "archer", SUPPORT_3],
		["upgrade", SUPPORT_3], ["upgrade", SUPPORT_3], ["upgrade", SUPPORT_4],
	]

func _played(plan: Array) -> Array:
	var sim := Simulation.new(GameData.load_catalog(), LevelReader.read(scene, GameData.load_level("level_03")))
	var step := 0
	var elapsed := 0.0
	while sim.state == "playing" and elapsed < MAX_SECONDS:
		while step < plan.size() and _try(sim, plan[step]):
			step += 1
		sim.tick(STEP)
		sim.drain_events()
		elapsed += STEP
	return [sim, elapsed]

func _try(sim: Simulation, action: Array) -> bool:
	if action[0] == "place":
		return sim.place_unit(action[1], action[2]) != null
	var unit = sim.unit_at(action[1])
	return unit != null and sim.upgrade_unit(unit)

func test_plan_cells_are_buildable() -> void:
	var level := LevelReader.read(scene, GameData.load_level("level_03"))
	for cell: Vector2i in [FRONT, FRONT_2, FRONT_3, SUPPORT, SUPPORT_2, SUPPORT_3, SUPPORT_4]:
		assert_true(level.buildable.has(cell), str(cell))

func test_a_defense_with_spearmen_and_druids_wins() -> void:
	assert_eq(_played(_plan("spearman", "druid", "mage", "spearman"))[0].state, "won")

func test_winning_is_not_flawless() -> void:
	var sim: Simulation = _played(_plan("spearman", "druid", "mage", "spearman"))[0]
	assert_lt(sim.lives, 20)

func test_level_lasts_between_ten_and_fifteen_minutes_without_early_calls() -> void:
	assert_between(_played(_plan("spearman", "druid", "mage", "spearman"))[1], 600.0, 900.0)
