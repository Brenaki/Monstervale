extends GutTest
## Protege contra erros grosseiros na Fase 5. A dificuldade é avaliada com as partidas reais.

const GameData = preload("res://src/core/game_data.gd")
const LevelReader = preload("res://src/game/level_reader.gd")
const Simulation = preload("res://src/core/simulation.gd")

const STEP := 1.0 / 20.0
const MAX_SECONDS := 1800.0
const CALL_AFTER_CLEAR := 6.0
const THREE_STAR_LIVES := 18
const TWO_STAR_LIVES := 10
const MERGE := Vector2i(12, 5)
const MERGE_2 := Vector2i(14, 4)
const MIDDLE := Vector2i(10, 5)
const FIELD := Vector2i(8, 7)
const LEFT := Vector2i(5, 4)
const TRUNK := Vector2i(12, 3)
const CROSSING := Vector2i(8, 5)
const ENTRANCE := Vector2i(3, 6)
const SUPPORT := Vector2i(12, 2)
const SUPPORT_2 := Vector2i(14, 6)
const SUPPORT_3 := Vector2i(10, 3)
const SUPPORT_4 := Vector2i(12, 7)
const SUPPORT_5 := Vector2i(10, 7)
const SUPPORT_6 := Vector2i(14, 2)

var scene: Node
var _boss_fell_at := -1.0

func before_each() -> void:
	scene = load("res://src/game/levels/level_05.tscn").instantiate()
	add_child_autofree(scene)

func _level() -> Dictionary:
	return LevelReader.read(scene, GameData.load_level("level_05"))

func _place(kind: String, cell: Vector2i) -> Array:
	return ["place", kind, cell]

func _up(cell: Vector2i) -> Array:
	return ["upgrade", cell]

## Defende o caminho inteiro: o Rei Slime não para em ninguém e precisa apanhar desde a entrada.
func _spread_plan() -> Array:
	return [
		_place("monk", MERGE), _place("archer", MIDDLE), _up(MERGE), _up(MIDDLE), _place("mage", FIELD), _up(MIDDLE),
		_up(FIELD), _place("monk", MERGE_2), _up(MERGE_2), _place("mage", LEFT), _up(FIELD), _up(LEFT), _up(MERGE),
		_up(MERGE_2), _up(LEFT), _place("archer", TRUNK), _up(TRUNK), _up(TRUNK), _place("druid", CROSSING),
		_up(CROSSING), _up(CROSSING), _place("archer", ENTRANCE), _up(ENTRANCE), _up(ENTRANCE),
	]

## Mistura as classes, mas só onde os caminhos se juntam.
func _merge_only_plan() -> Array:
	return [
		_place("monk", MERGE), _place("archer", SUPPORT), _up(MERGE), _up(SUPPORT), _up(SUPPORT),
		_place("monk", MIDDLE), _up(MIDDLE), _place("mage", SUPPORT_2), _up(MERGE), _up(SUPPORT_2), _up(MIDDLE),
		_up(SUPPORT_2), _place("monk", MERGE_2), _up(MERGE_2), _place("mage", SUPPORT_3), _up(SUPPORT_3),
		_up(MERGE_2), _up(SUPPORT_3), _place("archer", SUPPORT_4), _up(SUPPORT_4), _up(SUPPORT_4),
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
	_boss_fell_at = -1.0
	while sim.state == "playing" and elapsed < MAX_SECONDS:
		while step < plan.size() and _try(sim, plan[step]):
			step += 1
		clear_for = clear_for + STEP if sim.monsters.is_empty() else 0.0
		if clear_for >= CALL_AFTER_CLEAR and sim.can_call_next_wave():
			sim.call_next_wave()
			clear_for = 0.0
		sim.tick(STEP)
		for event: Dictionary in sim.drain_events():
			if event.type == "monster_killed" and event.monster.boss:
				_boss_fell_at = event.monster.distance / event.monster.route_length()
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
	for cell: Vector2i in [MERGE, MERGE_2, MIDDLE, FIELD, LEFT, TRUNK, CROSSING, ENTRANCE, SUPPORT, SUPPORT_2,
			SUPPORT_3, SUPPORT_4, SUPPORT_5, SUPPORT_6]:
		assert_true(level.buildable.has(cell), str(cell))

func test_defending_the_whole_route_can_earn_three_stars() -> void:
	var sim: Simulation = _played(_spread_plan())[0]
	assert_eq(sim.state, "won")
	assert_gte(sim.lives, THREE_STAR_LIVES)

## Mesmo na defesa boa, o rei só cai depois de andar mais da metade do caminho: o fim não é calmo.
func test_the_slime_king_walks_most_of_its_route_before_falling() -> void:
	_played(_spread_plan())
	assert_gt(_boss_fell_at, 0.5)

func test_defending_only_where_the_routes_merge_does_not_earn_two_stars() -> void:
	var sim: Simulation = _played(_merge_only_plan())[0]
	assert_lt(sim.lives, TWO_STAR_LIVES)

func test_monks_alone_do_not_earn_two_stars() -> void:
	var cells := [MERGE, MIDDLE, MERGE_2, TRUNK, SUPPORT_5, SUPPORT_2]
	var sim: Simulation = _played(_one_class_plan("monk", cells))[0]
	assert_lt(sim.lives, TWO_STAR_LIVES)

func test_archers_alone_do_not_earn_two_stars() -> void:
	var cells := [SUPPORT, SUPPORT_2, SUPPORT_3, SUPPORT_4, SUPPORT_5, SUPPORT_6]
	var sim: Simulation = _played(_one_class_plan("archer", cells))[0]
	assert_lt(sim.lives, TWO_STAR_LIVES)

func test_last_wave_is_the_biggest_so_the_end_is_not_calm() -> void:
	var waves: Array = GameData.load_level("level_05").waves
	var last := _wave_size(waves[-1])
	for wave: Dictionary in waves.slice(0, -1):
		assert_gt(last, _wave_size(wave))

func test_level_lasts_between_ten_and_fifteen_minutes_calling_after_each_clear() -> void:
	assert_between(_played(_spread_plan())[1], 600.0, 900.0)
