extends GutTest
## Protege contra erros grosseiros. A sensação de dificuldade é avaliada jogando.

const GameData = preload("res://src/core/game_data.gd")
const LevelReader = preload("res://src/game/level_reader.gd")
const Simulation = preload("res://src/core/simulation.gd")

const STEP := 1.0 / 20.0
const MAX_SECONDS := 1800.0

const PLAN := [
	["place", "archer", Vector2i(7, 5)],
	["place", "warrior", Vector2i(9, 4)],
	["place", "archer", Vector2i(7, 6)],
	["place", "archer", Vector2i(9, 5)],
	["upgrade", Vector2i(7, 5)],
	["upgrade", Vector2i(9, 4)],
	["place", "archer", Vector2i(7, 4)],
	["place", "archer", Vector2i(9, 6)],
	["upgrade", Vector2i(7, 6)],
	["upgrade", Vector2i(9, 5)],
	["place", "warrior", Vector2i(12, 4)],
	["place", "archer", Vector2i(10, 4)],
	["upgrade", Vector2i(7, 5)],
	["upgrade", Vector2i(7, 4)],
	["upgrade", Vector2i(9, 6)],
	["upgrade", Vector2i(10, 4)],
	["upgrade", Vector2i(9, 4)],
	["place", "archer", Vector2i(11, 4)],
	["upgrade", Vector2i(7, 6)],
	["upgrade", Vector2i(9, 5)],
	["upgrade", Vector2i(11, 4)],
]

var scene: Node

func before_each() -> void:
	scene = load("res://src/game/levels/level_01.tscn").instantiate()
	add_child_autofree(scene)

func _simulation() -> Simulation:
	return Simulation.new(GameData.load_catalog(), LevelReader.read(scene, GameData.load_level("level_01")))

func _play(sim: Simulation, plan: Array) -> float:
	var step := 0
	var elapsed := 0.0
	while sim.state == "playing" and elapsed < MAX_SECONDS:
		if step < plan.size() and _try(sim, plan[step]):
			step += 1
		sim.tick(STEP)
		sim.drain_events()
		elapsed += STEP
	return elapsed

func _try(sim: Simulation, action: Array) -> bool:
	if action[0] == "place":
		return sim.place_unit(action[1], action[2]) != null
	var unit = sim.unit_at(action[1])
	return unit != null and sim.upgrade_unit(unit)

func test_plan_uses_buildable_cells() -> void:
	var level := LevelReader.read(scene, GameData.load_level("level_01"))
	for action: Array in PLAN:
		if action[0] == "place":
			assert_true(level.buildable.has(action[2]), str(action[2]))

func test_no_defense_loses() -> void:
	var sim := _simulation()
	_play(sim, [])
	assert_eq(sim.state, "lost")

func test_a_single_archer_is_not_enough() -> void:
	var sim := _simulation()
	_play(sim, [["place", "archer", Vector2i(7, 5)]])
	assert_eq(sim.state, "lost")

func test_a_reasonable_defense_wins() -> void:
	var sim := _simulation()
	_play(sim, PLAN)
	assert_eq(sim.state, "won")

func test_level_lasts_between_ten_and_fifteen_minutes_without_early_calls() -> void:
	var sim := _simulation()
	var elapsed := _play(sim, PLAN)
	assert_between(elapsed, 600.0, 900.0)
