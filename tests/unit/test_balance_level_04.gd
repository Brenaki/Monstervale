extends GutTest
## Protege contra erros grosseiros na Fase 4. A dificuldade é avaliada com as partidas reais.

const GameData = preload("res://src/core/game_data.gd")
const LevelReader = preload("res://src/game/level_reader.gd")
const Simulation = preload("res://src/core/simulation.gd")
const Fixtures = preload("res://tests/unit/fixtures.gd")

const STEP := 1.0 / 20.0
const MAX_SECONDS := 1800.0
const CALL_AFTER_CLEAR := 6.0
const THREE_STAR_LIVES := 18
const TWO_STAR_LIVES := 10
const FRONT := Vector2i(12, 5)
const FRONT_2 := Vector2i(11, 5)
const FRONT_3 := Vector2i(14, 5)
const SUPPORT := Vector2i(12, 2)
const SUPPORT_2 := Vector2i(14, 7)
const SUPPORT_3 := Vector2i(15, 6)
const SUPPORT_4 := Vector2i(11, 2)
const SUPPORT_5 := Vector2i(10, 7)
const SUPPORT_6 := Vector2i(12, 7)

var scene: Node

func before_each() -> void:
	scene = load("res://src/game/levels/level_04.tscn").instantiate()
	add_child_autofree(scene)

func _level() -> Dictionary:
	return LevelReader.read(scene, GameData.load_level("level_04"))

func _place(kind: String, cell: Vector2i) -> Array:
	return ["place", kind, cell]

func _up(cell: Vector2i) -> Array:
	return ["upgrade", cell]

## Quem mistura as respostas aos tipos de dano: impacto, perfurante e magia.
func _mixed_plan() -> Array:
	return [
		_place("monk", FRONT), _place("archer", SUPPORT), _up(FRONT), _up(SUPPORT), _up(SUPPORT),
		_place("monk", FRONT_2), _up(FRONT_2), _place("mage", SUPPORT_2), _up(FRONT), _up(SUPPORT_2), _up(FRONT_2),
		_up(SUPPORT_2), _place("monk", FRONT_3), _up(FRONT_3), _place("mage", SUPPORT_3), _up(SUPPORT_3),
		_up(FRONT_3), _up(SUPPORT_3),
	]

func _one_class_plan(kind: String, cells: Array) -> Array:
	var plan := []
	for cell: Vector2i in cells:
		plan.append_array([_place(kind, cell), _up(cell), _up(cell)])
	return plan

## Chama a próxima onda pouco depois de limpar o campo, como nas partidas reais.
func _played(plan: Array) -> Array:
	var sim := Simulation.new(GameData.load_catalog(), _level())
	var step := 0
	var elapsed := 0.0
	var clear_for := 0.0
	while sim.state == "playing" and elapsed < MAX_SECONDS:
		while step < plan.size() and _try(sim, plan[step]):
			step += 1
		clear_for = clear_for + STEP if sim.monsters.is_empty() else 0.0
		if clear_for >= CALL_AFTER_CLEAR and sim.can_call_next_wave():
			sim.call_next_wave()
			clear_for = 0.0
		Fixtures.call_when_due(sim, STEP)
		sim.tick(STEP)
		sim.drain_events()
		elapsed += STEP
	return [sim, elapsed]

func _try(sim: Simulation, action: Array) -> bool:
	if action[0] == "place":
		return sim.place_unit(action[1], action[2]) != null
	var unit = sim.unit_at(action[1])
	return unit != null and sim.upgrade_unit(unit)

func _wave_size(wave: Dictionary) -> int:
	var total := 0
	for group: Dictionary in wave.groups:
		total += int(group.count)
	return total

func test_plan_cells_are_buildable() -> void:
	var level := _level()
	for cell: Vector2i in [FRONT, FRONT_2, FRONT_3, SUPPORT, SUPPORT_2, SUPPORT_3, SUPPORT_4, SUPPORT_5, SUPPORT_6]:
		assert_true(level.buildable.has(cell), str(cell))

func test_mixing_damage_types_can_earn_three_stars() -> void:
	var sim: Simulation = _played(_mixed_plan())[0]
	assert_eq(sim.state, "won")
	assert_gte(sim.lives, THREE_STAR_LIVES)

func test_archers_alone_do_not_earn_two_stars() -> void:
	var cells := [SUPPORT, SUPPORT_2, SUPPORT_3, SUPPORT_4, SUPPORT_5, SUPPORT_6]
	var sim: Simulation = _played(_one_class_plan("archer", cells))[0]
	assert_lt(sim.lives, TWO_STAR_LIVES)

func test_warriors_alone_do_not_earn_two_stars() -> void:
	var cells := [FRONT, FRONT_2, FRONT_3, Vector2i(12, 3), Vector2i(10, 5), Vector2i(14, 4)]
	var sim: Simulation = _played(_one_class_plan("warrior", cells))[0]
	assert_lt(sim.lives, TWO_STAR_LIVES)

func test_last_wave_is_the_biggest_so_the_end_is_not_calm() -> void:
	var waves: Array = GameData.load_level("level_04").waves
	var last := _wave_size(waves[-1])
	for wave: Dictionary in waves.slice(0, -1):
		assert_gt(last, _wave_size(wave))

func test_level_lasts_between_ten_and_fifteen_minutes_calling_after_each_clear() -> void:
	assert_between(_played(_mixed_plan())[1], 600.0, 900.0)
