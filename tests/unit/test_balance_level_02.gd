extends GutTest
## Protege a lição da Fase 2: dano em área contra a divisão dos slimes.

const GameData = preload("res://src/core/game_data.gd")
const LevelReader = preload("res://src/game/level_reader.gd")
const Simulation = preload("res://src/core/simulation.gd")

const STEP := 1.0 / 20.0
const MAX_SECONDS := 1800.0
const INNER := [
	Vector2i(6, 6), Vector2i(10, 6), Vector2i(8, 6), Vector2i(9, 6), Vector2i(6, 5), Vector2i(10, 5),
	Vector2i(9, 5), Vector2i(7, 5), Vector2i(6, 4), Vector2i(8, 4), Vector2i(9, 4), Vector2i(7, 4),
]
const MELEE := [
	Vector2i(5, 7), Vector2i(8, 7), Vector2i(11, 6), Vector2i(5, 4), Vector2i(10, 7), Vector2i(6, 7),
]

var scene: Node

func before_each() -> void:
	scene = load("res://src/game/levels/level_02.tscn").instantiate()
	add_child_autofree(scene)

## Em cada rodada compra e melhora uma vez cada classe, assim que há ouro.
func _plan(kinds: Array) -> Array:
	var plan := []
	var inner := 0
	var melee := 0
	for round_number in 4:
		for kind: String in kinds:
			var cell: Vector2i
			if kind == "warrior":
				cell = MELEE[melee]
				melee += 1
			else:
				cell = INNER[inner]
				inner += 1
			plan.append(["place", kind, cell])
			plan.append(["upgrade", cell])
	return plan

func _played(plan: Array) -> Array:
	var sim := Simulation.new(GameData.load_catalog(), LevelReader.read(scene, GameData.load_level("level_02")))
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

func test_strategy_cells_are_buildable() -> void:
	var level := LevelReader.read(scene, GameData.load_level("level_02"))
	for cell: Vector2i in INNER + MELEE:
		assert_true(level.buildable.has(cell), str(cell))

func test_a_defense_without_mages_does_not_win() -> void:
	assert_eq(_played(_plan(["warrior", "archer", "archer"]))[0].state, "lost")

func test_a_mixed_defense_with_one_mage_per_round_wins() -> void:
	assert_eq(_played(_plan(["warrior", "mage", "archer"]))[0].state, "won")

func test_a_defense_with_many_mages_wins() -> void:
	assert_eq(_played(_plan(["warrior", "mage", "mage"]))[0].state, "won")

func test_level_lasts_between_ten_and_fifteen_minutes_without_early_calls() -> void:
	assert_between(_played(_plan(["warrior", "mage", "mage"]))[1], 600.0, 900.0)
