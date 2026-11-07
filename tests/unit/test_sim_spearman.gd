extends GutTest

const Fixtures = preload("res://tests/unit/fixtures.gd")
const Simulation = preload("res://src/core/simulation.gd")

var sim

## O caminho passa pelo centro da célula do lanceiro, em (48, 48).
func before_each() -> void:
	var level := Fixtures.level()
	level["route"] = [Vector2(0, 48), Vector2(300, 48)]
	sim = Simulation.new(Fixtures.catalog(), level)
	sim.gold = 1000

func _standing(distance: float):
	var monster = sim.spawn_monster("goblin")
	monster.distance = distance
	monster.speed = 0.0
	return monster

func _spearman(level: int):
	var unit = sim.place_unit("spearman", Vector2i(1, 1))
	for i in level - 1:
		sim.upgrade_unit(unit)
	return unit

func test_reaches_farther_than_it_blocks() -> void:
	var far = _standing(100.0)
	_spearman(1)
	sim.tick(0.01)
	assert_lt(far.hp, far.max_hp, "a lança alcança")
	assert_null(far.blocker, "mas não segura de longe")

func test_blocks_monsters_that_come_close() -> void:
	var near = _standing(60.0)
	var unit = _spearman(1)
	sim.tick(0.01)
	assert_eq(near.blocker, unit)

func test_levels_one_and_two_hit_only_the_target() -> void:
	var target = _standing(100.0)
	var behind = _standing(90.0)
	_spearman(2)
	sim.tick(0.01)
	assert_lt(target.hp, target.max_hp)
	assert_eq(behind.hp, behind.max_hp)

func test_level_three_hits_everyone_in_line() -> void:
	var target = _standing(110.0)
	var behind = _standing(100.0)
	var other_side = _standing(5.0)
	_spearman(3)
	sim.tick(0.01)
	assert_lt(target.hp, target.max_hp)
	assert_eq(behind.hp, target.hp, "os dois estão na mesma linha")
	assert_eq(other_side.hp, other_side.max_hp, "só na direção do golpe")

func test_line_stops_at_the_reach_of_the_spear() -> void:
	var target = _standing(100.0)
	var beyond = _standing(135.0)
	_spearman(3)
	sim.tick(0.01)
	assert_lt(target.hp, target.max_hp)
	assert_eq(beyond.hp, beyond.max_hp)
