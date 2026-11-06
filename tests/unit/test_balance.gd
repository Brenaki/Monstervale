extends GutTest
## Protege contra erros grosseiros. A sensação de dificuldade é avaliada jogando.

const GameData = preload("res://src/core/game_data.gd")
const LevelReader = preload("res://src/game/level_reader.gd")
const Simulation = preload("res://src/core/simulation.gd")

const STEP := 1.0 / 20.0
const MAX_SECONDS := 1800.0
const EASY_MATCH_PATH := "res://tests/fixtures/partida_facil_demais.json"
const MAX_LEVEL_INCOME := 800

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

## Repete a partida real na ordem e no tempo em que foi jogada. Cada ação espera
## haver ouro, então menos renda significa uma defesa mais fraca, como aconteceria.
func _replay(sim: Simulation, report: Dictionary) -> void:
	var actions: Array = report.actions.duplicate()
	var calls: Array = report.waves.filter(func(w): return w.called_early).map(func(w): return w.started_at)
	var elapsed := 0.0
	while sim.state == "playing" and elapsed < MAX_SECONDS:
		while not actions.is_empty() and actions[0].time <= elapsed and _replay_action(sim, actions[0]):
			actions.pop_front()
		if not calls.is_empty() and calls[0] <= elapsed and sim.call_next_wave():
			calls.pop_front()
		sim.tick(STEP)
		sim.drain_events()
		elapsed += STEP

func _replay_action(sim: Simulation, action: Dictionary) -> bool:
	var cell := Vector2i(int(action.cell[0]), int(action.cell[1]))
	if action.action == "place":
		return sim.place_unit(action.unit, cell) != null
	var unit = sim.unit_at(cell)
	if unit == null:
		return false
	if action.action == "upgrade":
		return sim.upgrade_unit(unit)
	sim.dismiss_unit(unit)
	return true

func _level_income() -> int:
	var data := GameData.load_level("level_01")
	var monsters: Dictionary = GameData.load_catalog().monsters
	var total: int = data.start_gold
	for wave: Dictionary in data.waves:
		total += int(wave.bonus)
		for group: Dictionary in wave.groups:
			total += int(group.count) * int(monsters[group.monster].gold)
	return total

func test_warrior_is_cheaper_to_hire_than_archer() -> void:
	var units: Dictionary = GameData.load_catalog().units
	assert_eq(int(units.warrior.levels[0].cost), 50)
	assert_eq(int(units.archer.levels[0].cost), 65)

func test_level_income_is_limited() -> void:
	assert_lte(_level_income(), MAX_LEVEL_INCOME, "início, abates e bônus, sem contar chamadas")

func test_full_income_cannot_max_out_a_large_defense() -> void:
	var units: Dictionary = GameData.load_catalog().units
	var six_at_max := 0
	for kind: String in ["archer", "archer", "archer", "archer", "warrior", "warrior"]:
		for level: Dictionary in units[kind].levels:
			six_at_max += int(level.cost)
	assert_gt(six_at_max, _level_income())

func test_calling_early_pays_little() -> void:
	var data := GameData.load_level("level_01")
	var most: float = float(data.wave_interval) * float(data.early_call_gold_per_second)
	assert_lte(most, 12.0)

func test_the_too_easy_match_is_no_longer_flawless() -> void:
	var report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(EASY_MATCH_PATH))
	var sim := _simulation()
	_replay(sim, report)
	assert_false(sim.state == "won" and sim.lives == 20, "terminou %s com %d vidas" % [sim.state, sim.lives])
