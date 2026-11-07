extends GutTest

const Simulation = preload("res://src/core/simulation.gd")
const Fixtures = preload("res://tests/unit/fixtures.gd")

var sim: Simulation

func before_each() -> void:
	sim = Fixtures.simulation()

func test_starts_with_level_gold_and_lives() -> void:
	assert_eq(sim.gold, 100)
	assert_eq(sim.lives, 10)

func test_place_unit_spends_gold() -> void:
	var unit = sim.place_unit("archer", Vector2i(2, 2))
	assert_not_null(unit)
	assert_eq(sim.gold, 60)
	assert_eq(sim.units.size(), 1)

func test_cannot_place_without_gold() -> void:
	sim.gold = 39
	assert_null(sim.place_unit("archer", Vector2i(2, 2)))
	assert_eq(sim.gold, 39)
	assert_eq(sim.units.size(), 0)

func test_cannot_place_on_non_buildable_cell() -> void:
	assert_null(sim.place_unit("archer", Fixtures.PATH_CELL))
	assert_eq(sim.gold, 100)

func test_cannot_place_on_occupied_cell() -> void:
	sim.place_unit("archer", Vector2i(2, 2))
	assert_null(sim.place_unit("archer", Vector2i(2, 2)))
	assert_eq(sim.units.size(), 1)

func test_cannot_place_class_not_available_in_level() -> void:
	var level := Fixtures.level()
	level.classes = ["archer"]
	var restricted = load("res://src/core/simulation.gd").new(Fixtures.catalog(), level)
	assert_null(restricted.place_unit("warrior", Vector2i(2, 2)))

func test_upgrade_spends_gold_and_raises_level() -> void:
	var unit = sim.place_unit("archer", Vector2i(2, 2))
	assert_true(sim.upgrade_unit(unit))
	assert_eq(unit.level, 2)
	assert_eq(sim.gold, 30)

func test_upgrade_fails_without_gold() -> void:
	var unit = sim.place_unit("archer", Vector2i(2, 2))
	sim.gold = 29
	assert_false(sim.upgrade_unit(unit))
	assert_eq(unit.level, 1)
	assert_eq(sim.gold, 29)

func test_upgrade_stops_at_level_three() -> void:
	sim.gold = 1000
	var unit = sim.place_unit("archer", Vector2i(2, 2))
	assert_true(sim.upgrade_unit(unit))
	assert_true(sim.upgrade_unit(unit))
	assert_false(sim.upgrade_unit(unit))
	assert_eq(unit.level, 3)

func test_dismiss_refunds_half_of_everything_spent() -> void:
	sim.gold = 1000
	var unit = sim.place_unit("archer", Vector2i(2, 2))
	sim.upgrade_unit(unit)
	var before: int = sim.gold
	sim.dismiss_unit(unit)
	assert_eq(sim.gold, before + 35, "metade de 40 + 30")
	assert_eq(sim.units.size(), 0)

func test_dismiss_frees_the_cell() -> void:
	var unit = sim.place_unit("archer", Vector2i(2, 2))
	sim.dismiss_unit(unit)
	assert_not_null(sim.place_unit("archer", Vector2i(2, 2)))

func test_priority_cycles_through_all_options() -> void:
	var unit = sim.place_unit("archer", Vector2i(2, 2))
	assert_eq(unit.priority, "first")
	var seen := []
	for i in 4:
		unit.cycle_priority()
		seen.append(unit.priority)
	assert_eq(seen, ["last", "strongest", "closest", "first"])

func test_an_invincible_village_keeps_its_lives_when_monsters_get_through() -> void:
	sim.invincible = true
	var monster = sim.spawn_monster("goblin")
	monster.distance = sim.route.length
	sim.tick(0.1)
	assert_eq(sim.lives, sim.start_lives())
	assert_eq(sim.monsters.size(), 0, "o monstro sai do mapa do mesmo jeito")
