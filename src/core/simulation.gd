extends RefCounted
## Regras do jogo, sem depender de cenas. A interface chama tick() e lê o estado.

const Route = preload("res://src/core/route.gd")
const Monster = preload("res://src/core/monster.gd")
const Unit = preload("res://src/core/unit.gd")

const DEFAULT_STAR_THRESHOLDS := [0.5, 0.9]

var gold: int
var lives: int
var state: String = "playing"
var units: Array = []
var monsters: Array = []
var route
var next_wave_countdown: float
var elapsed: float = 0.0

var _catalog: Dictionary
var _level: Dictionary
var _start_lives: int
var _next_wave: int = 0
var _active_waves: Array = []
var _events: Array = []


func _init(catalog: Dictionary, level: Dictionary) -> void:
	_catalog = catalog
	_level = level
	gold = level.start_gold
	lives = level.lives
	_start_lives = level.lives
	route = Route.new(level.route)
	next_wave_countdown = level.wave_interval


func available_classes() -> Array:
	return _level.classes


func unit_cost(kind: String) -> int:
	return _catalog.units[kind].levels[0].cost


func can_place(kind: String, cell: Vector2i) -> bool:
	return (
		kind in _level.classes
		and _level.buildable.has(cell)
		and unit_at(cell) == null
		and gold >= unit_cost(kind)
	)


func unit_at(cell: Vector2i):
	for unit in units:
		if unit.cell == cell:
			return unit
	return null


func cell_center(cell: Vector2i) -> Vector2:
	var size: int = _level.cell_size
	return Vector2((cell.x + 0.5) * size, (cell.y + 0.5) * size)


func place_unit(kind: String, cell: Vector2i):
	if not can_place(kind, cell):
		return null
	var unit = Unit.new(kind, _catalog.units[kind], cell, cell_center(cell))
	gold -= unit.spent
	units.append(unit)
	_emit({"type": "unit_placed", "unit": unit})
	return unit


func upgrade_unit(unit) -> bool:
	if not unit.can_upgrade() or gold < unit.upgrade_cost():
		return false
	gold -= unit.upgrade_cost()
	unit.raise_level()
	_emit({"type": "unit_upgraded", "unit": unit})
	return true


func dismiss_unit(unit) -> void:
	_release_blocked(unit)
	gold += unit.refund()
	units.erase(unit)
	_emit({"type": "unit_dismissed", "unit": unit})


func spawn_monster(kind: String):
	var monster = Monster.new(kind, _catalog.monsters[kind], route)
	monsters.append(monster)
	_emit({"type": "monster_spawned", "monster": monster})
	return monster


func waves_started() -> int:
	return _next_wave


func waves_total() -> int:
	return _level.waves.size()


func can_call_next_wave() -> bool:
	return state == "playing" and _next_wave < waves_total() and not _is_spawning()


func call_next_wave() -> bool:
	if not can_call_next_wave():
		return false
	var bonus := early_call_bonus()
	gold += bonus
	_start_next_wave(bonus, true)
	return true


func early_call_bonus() -> int:
	return roundi(next_wave_countdown * float(_level.early_call_gold_per_second))


func next_wave_preview() -> Dictionary:
	var preview := {}
	if _next_wave >= waves_total():
		return preview
	for group: Dictionary in _level.waves[_next_wave].groups:
		preview[group.monster] = preview.get(group.monster, 0) + int(group.count)
	return preview


func stars() -> int:
	var thresholds: Array = _level.get("stars", DEFAULT_STAR_THRESHOLDS)
	var ratio := float(lives) / _start_lives
	if ratio >= thresholds[1]:
		return 3
	if ratio >= thresholds[0]:
		return 2
	return 1


## Estágio visual de dano do vilarejo: 0 inteiro, 1 danificado, 2 em ruínas.
func village_stage() -> int:
	var ratio := float(lives) / _start_lives
	if ratio > 2.0 / 3.0:
		return 0
	if ratio > 1.0 / 3.0:
		return 1
	return 2


func drain_events() -> Array:
	var drained := _events
	_events = []
	return drained


func tick(delta: float) -> void:
	if state != "playing":
		return
	elapsed += delta
	_update_wave_timer(delta)
	_update_spawners(delta)
	_update_monsters(delta)
	_update_units(delta)
	_update_waves_cleared()
	_update_end_state()


func _emit(event: Dictionary) -> void:
	event["time"] = elapsed
	event["gold"] = gold
	event["lives"] = lives
	event["waves_started"] = _next_wave
	_events.append(event)


func _is_spawning() -> bool:
	for wave in _active_waves:
		if not wave.spawners.is_empty():
			return true
	return false


func _start_next_wave(early_bonus: int = 0, called_early: bool = false) -> void:
	var definition: Dictionary = _level.waves[_next_wave]
	var spawners := []
	for group: Dictionary in definition.groups:
		spawners.append({
			"monster": group.monster,
			"remaining": int(group.count),
			"interval": float(group.interval),
			"timer": float(group.delay),
		})
	_next_wave += 1
	_active_waves.append({"number": _next_wave, "spawners": spawners, "alive": 0, "bonus": int(definition.bonus)})
	next_wave_countdown = float(_level.wave_interval)
	_emit({"type": "wave_started", "number": _next_wave, "early_bonus": early_bonus, "called_early": called_early})


func _update_wave_timer(delta: float) -> void:
	if _next_wave >= waves_total() or _is_spawning():
		return
	next_wave_countdown -= delta
	if next_wave_countdown <= 0.0:
		_start_next_wave()


func _update_spawners(delta: float) -> void:
	for wave in _active_waves:
		for spawner in wave.spawners:
			spawner.timer -= delta
			while spawner.timer <= 0.0 and spawner.remaining > 0:
				var monster = spawn_monster(spawner.monster)
				monster.wave = wave
				wave.alive += 1
				spawner.remaining -= 1
				spawner.timer += spawner.interval
		wave.spawners = wave.spawners.filter(func(s): return s.remaining > 0)


func _update_monsters(delta: float) -> void:
	for monster in monsters.duplicate():
		if monster.blocker == null:
			_try_block(monster)
		if monster.blocker != null:
			_attack_blocker(monster, delta)
		else:
			_walk(monster, delta)
			if monster in monsters:
				_attack_in_passing(monster, delta)


func _try_block(monster) -> void:
	for unit in units:
		if unit.has_block_room() and unit.position.distance_to(monster.position()) <= float(unit.stats().range):
			monster.blocker = unit
			unit.blocked.append(monster)
			monster.cooldown = 0.0
			return


func _attack_blocker(monster, delta: float) -> void:
	monster.cooldown -= delta
	if monster.cooldown <= 0.0:
		_strike(monster, monster.blocker)


## Quem não está bloqueado segue andando e bate no humano mais próximo ao alcance.
func _attack_in_passing(monster, delta: float) -> void:
	monster.cooldown -= delta
	if monster.cooldown > 0.0:
		return
	var nearest = null
	var nearest_gap: float = monster.reach
	for unit in units:
		if unit.is_down():
			continue
		var gap: float = unit.position.distance_to(monster.position())
		if gap <= nearest_gap:
			nearest_gap = gap
			nearest = unit
	if nearest != null:
		_strike(monster, nearest)


func _strike(monster, unit) -> void:
	monster.cooldown = monster.attack_cooldown
	var taken := maxi(1, roundi(monster.damage * float(unit.stats().get("damage_taken", 1.0))))
	unit.hp -= taken
	unit.time_since_hit = 0.0
	_emit({"type": "unit_hit", "unit": unit, "monster": monster, "damage": taken})
	if unit.hp <= 0:
		_fell(unit)


func _fell(unit) -> void:
	unit.hp = 0
	unit.down_timer = float(unit.stats().respawn)
	_release_blocked(unit)
	_emit({"type": "unit_down", "unit": unit})


func _release_blocked(unit) -> void:
	for monster in unit.blocked:
		monster.blocker = null
	unit.blocked.clear()


func _walk(monster, delta: float) -> void:
	monster.distance += monster.speed * delta
	var direction: int = route.horizontal_direction_at(monster.distance)
	if direction != 0:
		monster.facing = direction
	if monster.distance >= route.length:
		_escape(monster)


func _escape(monster) -> void:
	lives = maxi(0, lives - monster.lives)
	_remove(monster)
	_emit({"type": "monster_escaped", "monster": monster})


func _remove(monster) -> void:
	monsters.erase(monster)
	if monster.blocker != null:
		monster.blocker.blocked.erase(monster)
		monster.blocker = null
	if monster.wave != null:
		monster.wave.alive -= 1


func _update_units(delta: float) -> void:
	for unit in units:
		if unit.is_down():
			unit.down_timer -= delta
			if not unit.is_down():
				unit.hp = unit.stats().hp
				_emit({"type": "unit_up", "unit": unit})
			continue
		unit.recover(delta)
		unit.cooldown -= delta
		if unit.cooldown > 0.0:
			continue
		var target = _pick_target(unit)
		if target != null:
			unit.cooldown = float(unit.stats().cooldown)
			_attack(unit, target)


func _pick_target(unit):
	if not unit.blocked.is_empty():
		return unit.blocked[0]
	var best = null
	var best_score := -INF
	for monster in monsters:
		var gap: float = unit.position.distance_to(monster.position())
		if gap > float(unit.stats().range):
			continue
		var score := _target_score(unit.priority, monster, gap)
		if score > best_score:
			best_score = score
			best = monster
	return best


func _target_score(priority: String, monster, gap: float) -> float:
	match priority:
		"last":
			return -monster.distance
		"strongest":
			return float(monster.hp)
		"closest":
			return -gap
	return monster.distance


func _attack(unit, target) -> void:
	var hits := [target]
	var stats: Dictionary = unit.stats()
	if stats.has("pierce_extra"):
		hits.append_array(_nearby(target, float(stats.pierce_radius), int(stats.pierce_extra)))
	var target_x: float = target.position().x
	if target_x != unit.position.x:
		unit.facing = 1 if target_x > unit.position.x else -1
	_emit({"type": "attack", "unit": unit, "target": target, "position": target.position()})
	for monster in hits:
		_damage(monster, monster.damage_from(int(stats.damage), unit.damage_type()), unit.kind)


func _nearby(target, radius: float, count: int) -> Array:
	var near := monsters.filter(func(m): return m != target and m.position().distance_to(target.position()) <= radius)
	near.sort_custom(func(a, b): return a.position().distance_to(target.position()) < b.position().distance_to(target.position()))
	return near.slice(0, count)


func _damage(monster, amount: int, source: String) -> void:
	monster.hp -= amount
	_emit({"type": "monster_hit", "monster": monster, "damage": amount, "source": source})
	if monster.hp <= 0:
		gold += monster.gold
		_remove(monster)
		_emit({"type": "monster_killed", "monster": monster, "position": monster.position()})


func _update_waves_cleared() -> void:
	for wave in _active_waves.duplicate():
		if wave.spawners.is_empty() and wave.alive <= 0:
			gold += wave.bonus
			_active_waves.erase(wave)
			_emit({"type": "wave_cleared", "number": wave.number, "bonus": wave.bonus})


func _update_end_state() -> void:
	if lives <= 0:
		state = "lost"
		_emit({"type": "level_lost"})
	elif _next_wave >= waves_total() and _active_waves.is_empty() and monsters.is_empty() and waves_total() > 0:
		state = "won"
		_emit({"type": "level_won", "stars": stars()})
