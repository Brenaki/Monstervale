extends GutTest
## Protege contra erros grosseiros. A sensação de dificuldade é avaliada jogando.

const GameData = preload("res://src/core/game_data.gd")
const LevelReader = preload("res://src/game/level_reader.gd")
const Simulation = preload("res://src/core/simulation.gd")
const Fixtures = preload("res://tests/unit/fixtures.gd")

const STEP := 1.0 / 20.0
const MAX_SECONDS := 1800.0
const EASY_MATCH_PATH := "res://tests/fixtures/partidas/partida_2026-11-06_12-38-53_level_01.json"
const ARCHERS_MATCH_PATH := "res://tests/fixtures/partidas/partida_2026-11-06_12-56-30_level_01.json"
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

const ARCHER_CELLS := [
	Vector2i(3, 5), Vector2i(4, 5), Vector2i(5, 5), Vector2i(6, 5), Vector2i(6, 4), Vector2i(6, 3),
	Vector2i(6, 2), Vector2i(3, 9), Vector2i(4, 9), Vector2i(6, 9), Vector2i(7, 9), Vector2i(8, 9),
	Vector2i(9, 9), Vector2i(10, 6), Vector2i(10, 5), Vector2i(11, 5),
]
const WARRIOR_CELLS := [
	Vector2i(4, 6), Vector2i(5, 8), Vector2i(3, 6), Vector2i(6, 8), Vector2i(5, 6), Vector2i(4, 8),
	Vector2i(7, 6), Vector2i(7, 8), Vector2i(3, 8), Vector2i(9, 6), Vector2i(7, 4), Vector2i(9, 4),
	Vector2i(11, 4), Vector2i(13, 4), Vector2i(10, 2), Vector2i(12, 2),
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
		Fixtures.call_when_due(sim, STEP)
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
		Fixtures.call_when_due(sim, STEP)
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

func test_only_warriors_from_level_two_recover() -> void:
	var units: Dictionary = GameData.load_catalog().units
	assert_false(units.warrior.levels[0].has("regen"))
	assert_gt(float(units.warrior.levels[1].regen), 0.0)
	assert_gt(float(units.warrior.levels[2].regen), float(units.warrior.levels[1].regen))
	for level: Dictionary in units.archer.levels:
		assert_false(level.has("regen"))

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
	assert_lte(most, 5.0)

func test_the_too_easy_match_is_no_longer_flawless() -> void:
	var report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(EASY_MATCH_PATH))
	var sim := _simulation()
	_replay(sim, report)
	assert_false(sim.state == "won" and sim.lives == 20, "terminou %s com %d vidas" % [sim.state, sim.lives])

func test_the_only_archers_match_is_no_longer_flawless() -> void:
	var report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ARCHERS_MATCH_PATH))
	var sim := _simulation()
	_replay(sim, report)
	assert_false(sim.state == "won" and sim.lives == 20, "terminou %s com %d vidas" % [sim.state, sim.lives])

## Estratégias que compram assim que há ouro, sem reagir ao que acontece na tela.
func _only(kind: String, cells: Array) -> Array:
	return cells.map(func(cell): return ["place", kind, cell])

func _only_upgrading(kind: String, cells: Array) -> Array:
	var plan := []
	for i in range(0, cells.size() - 1, 2):
		plan.append(["place", kind, cells[i]])
		plan.append(["place", kind, cells[i + 1]])
		plan.append(["upgrade", cells[i]])
		plan.append(["upgrade", cells[i + 1]])
	return plan

func _mixed_upgrading() -> Array:
	var plan := []
	for i in ARCHER_CELLS.size() / 2:
		plan.append(["place", "warrior", WARRIOR_CELLS[i]])
		plan.append(["place", "archer", ARCHER_CELLS[i * 2]])
		plan.append(["upgrade", WARRIOR_CELLS[i]])
		plan.append(["upgrade", ARCHER_CELLS[i * 2]])
		plan.append(["place", "archer", ARCHER_CELLS[i * 2 + 1]])
		plan.append(["upgrade", ARCHER_CELLS[i * 2 + 1]])
	return plan

func _played(plan: Array) -> Simulation:
	var sim := _simulation()
	_play(sim, plan)
	return sim

func test_strategy_cells_are_buildable() -> void:
	var level := LevelReader.read(scene, GameData.load_level("level_01"))
	for cell: Vector2i in ARCHER_CELLS + WARRIOR_CELLS:
		assert_true(level.buildable.has(cell), str(cell))

func test_level_one_archers_alone_do_not_win() -> void:
	assert_eq(_played(_only("archer", ARCHER_CELLS)).state, "lost")

func test_level_one_warriors_alone_reach_the_last_wave() -> void:
	var sim := _played(_only("warrior", WARRIOR_CELLS))
	assert_eq(sim.waves_started(), sim.waves_total())

func test_upgrading_beats_only_buying_more() -> void:
	for kind: String in ["archer", "warrior"]:
		var cells: Array = ARCHER_CELLS if kind == "archer" else WARRIOR_CELLS
		assert_gt(_played(_only_upgrading(kind, cells)).lives, _played(_only(kind, cells)).lives, kind)

func test_mixing_classes_beats_a_single_class() -> void:
	var mixed := _played(_mixed_upgrading()).lives
	assert_gt(mixed, _played(_only_upgrading("archer", ARCHER_CELLS)).lives, "só arqueiros")
	assert_gt(mixed, _played(_only_upgrading("warrior", WARRIOR_CELLS)).lives, "só guerreiros")
