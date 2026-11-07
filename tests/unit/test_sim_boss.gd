extends GutTest

const Fixtures = preload("res://tests/unit/fixtures.gd")
const GameData = preload("res://src/core/game_data.gd")

var sim

func before_each() -> void:
	sim = Fixtures.simulation()
	sim.gold = 1000

func _king(distance := 50.0):
	var king = sim.spawn_monster("king")
	king.distance = distance
	return king

func _kinds() -> Array:
	return sim.monsters.map(func(m): return m.kind)

func test_king_sheds_slimes_each_time_it_loses_a_quarter_of_its_life() -> void:
	var king = _king()
	sim._damage(king, 10, "magic", "test")
	assert_eq(sim.monsters.size(), 1, "ainda não perdeu um quarto")
	sim._damage(king, 20, "magic", "test")
	assert_eq(_kinds().count("slime"), 2)
	sim._damage(king, 50, "magic", "test")
	assert_eq(_kinds().count("slime"), 6, "um golpe que cruza dois quartos solta duas vezes")

func test_shed_slimes_appear_where_the_king_is() -> void:
	var king = _king(80.0)
	sim._damage(king, 30, "magic", "test")
	for monster in sim.monsters:
		assert_almost_eq(monster.distance, 80.0, 10.0)
		assert_eq(monster.route_index, king.route_index)

func test_shedding_emits_an_event_for_the_split_animation() -> void:
	var king = _king()
	sim.drain_events()
	sim._damage(king, 30, "magic", "test")
	var splits: Array = sim.drain_events().filter(func(e): return e.type == "monster_split")
	assert_eq(splits.size(), 1)
	assert_eq(splits[0].monster, king)

func test_king_cannot_be_rooted_or_stunned_but_can_be_slowed() -> void:
	var king = _king()
	king.apply_root(2.0)
	king.apply_stun(2.0)
	king.apply_slow(0.5, 2.0)
	assert_false(king.is_rooted())
	assert_false(king.is_stunned())
	assert_true(king.is_slowed())

func test_king_cannot_be_blocked_and_crushes_humans_in_passing() -> void:
	var warrior = sim.place_unit("warrior", Vector2i(2, 1))
	var king = _king(80.0)
	sim.tick(0.1)
	assert_null(king.blocker)
	assert_gt(king.distance, 80.0)
	assert_lt(warrior.hp, int(warrior.stats().hp))

func test_shed_slimes_belong_to_the_same_wave() -> void:
	sim = Fixtures.simulation([Fixtures.wave([Fixtures.group("king")])])
	sim.call_next_wave()
	sim.tick(0.01)
	var king = sim.monsters[0]
	sim._damage(king, 30, "magic", "test")
	for monster in sim.monsters:
		assert_eq(monster.wave, king.wave)
	assert_eq(king.wave.alive, sim.monsters.size())

func test_sim_knows_the_boss_on_the_field() -> void:
	assert_null(sim.boss())
	sim.spawn_monster("goblin")
	var king = _king()
	assert_eq(sim.boss(), king)

## Deixar o rei passar custa metade da vila: perde as 3 estrelas, mas a partida continua.
func test_real_king_takes_half_the_village_if_it_gets_through() -> void:
	var data: Dictionary = GameData.load_catalog().monsters.slime_king
	assert_true(data.boss)
	assert_eq(int(data.lives), int(GameData.load_level("level_05").lives) / 2)
	assert_has(data.immune, "root")
	assert_has(data.immune, "stun")
	assert_has(data.immune, "block")
