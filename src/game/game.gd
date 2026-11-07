extends Node2D
## Liga a simulação às cenas: avança o tempo, responde aos botões e desenha eventos.

const GameData = preload("res://src/core/game_data.gd")
const Simulation = preload("res://src/core/simulation.gd")
const Progress = preload("res://src/core/progress.gd")
const MatchLog = preload("res://src/core/match_log.gd")
const LevelReader = preload("res://src/game/level_reader.gd")
const EntityView = preload("res://src/game/entity_view.gd")
const Overlay = preload("res://src/game/overlay.gd")
const Hud = preload("res://src/game/hud.gd")

const LEVEL_IDS := ["level_01", "level_02", "level_03", "level_04"]
const LEVEL_SCENE := "res://src/game/levels/%s.tscn"
const STEP := 1.0 / 60.0
const MAX_SPEED := 2
const VILLAGE_TINTS := [Color.WHITE, Color(0.8, 0.7, 0.65), Color(0.5, 0.42, 0.42)]
const BURST_PIECES := 5
const BURST_SECONDS := 0.35
const ARROW_SECONDS := 0.12
const TRAIL_SECONDS := 0.3
const EXPLOSION_SECONDS := 0.25
const EXPLOSION_POINTS := 12
const SPELL_COLOR := Color("8fe0f0")
const FIRE_SPELL_COLOR := Color("e8913a")
const THRUST_COLOR := Color("f6e05e")
const CRIT_COLOR := Color("f6e05e")
const HIT_COLORS := {"weak": Color("f6e05e"), "resisted": Color("6b7385"), "normal": Color.WHITE}
const COIN_COLOR := Color("f6e05e")
const COIN_RISE := 14.0
const COIN_SECONDS := 0.5
const NO_CELL := Vector2i(-1, -1)

var progress_path := "user://progress.json"
var log_dir := "user://partidas"
var last_log_path := ""
var catalog: Dictionary
var level: Dictionary
var level_index := 0
var sim
var progress
var hud
var speed := 1
var paused := false
var selected_class := ""
var selected_unit = null
var hover_cell := NO_CELL
var quit_action := func(): get_tree().quit()

var _level_node: Node
var _entities: Node2D
var _effects: Node2D
var _views := {}
var _frame_cache := {}
var _accumulator := 0.0
var _match_log
var _log_saved := false
var _paused_before_levels := false


func _ready() -> void:
	catalog = GameData.load_catalog()
	progress = _load_progress()
	level_index = progress.furthest_unlocked(LEVEL_IDS.size())
	_load_level_scene()

	var overlay := Overlay.new()
	overlay.game = self
	add_child(overlay)
	_entities = Node2D.new()
	_entities.y_sort_enabled = true
	add_child(_entities)
	_effects = Node2D.new()
	add_child(_effects)

	hud = Hud.new()
	add_child(hud)
	hud.class_pressed.connect(select_class)
	hud.next_wave_pressed.connect(call_wave)
	hud.pause_pressed.connect(toggle_pause)
	hud.speed_pressed.connect(toggle_speed)
	hud.restart_pressed.connect(restart)
	hud.language_pressed.connect(toggle_language)
	hud.upgrade_pressed.connect(upgrade_selected)
	hud.dismiss_pressed.connect(dismiss_selected)
	hud.priority_pressed.connect(cycle_priority)
	hud.close_pressed.connect(clear_selection)
	hud.log_pressed.connect(open_last_log)
	hud.next_level_pressed.connect(next_level)
	hud.levels_pressed.connect(toggle_levels)
	hud.level_pressed.connect(_choose_level)
	hud.menu_pressed.connect(open_menu)
	hud.resume_pressed.connect(resume_game)
	hud.quit_pressed.connect(quit_game)
	hud.quit_button.visible = not OS.has_feature("web")
	hud.set_levels(LEVEL_IDS.size())

	_choose_initial_language()
	restart()


func _process(delta: float) -> void:
	advance(delta)
	var time_scale := 0.0 if paused or sim.state != "playing" else float(speed)
	for state in _views:
		_views[state].sync(delta, time_scale)
	hud.refresh(self)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_unfinished_match("closed")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		hover_cell = world_to_cell(make_input_local(event).position)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			cell_clicked(world_to_cell(make_input_local(event).position))
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			clear_selection()


func advance(delta: float) -> void:
	if paused or sim.state != "playing":
		_handle_events()
		return
	_accumulator += delta * speed
	while _accumulator >= STEP:
		_accumulator -= STEP
		sim.tick(STEP)
	_handle_events()


func world_to_cell(point: Vector2) -> Vector2i:
	var size := float(level.cell_size)
	return Vector2i(floori(point.x / size), floori(point.y / size))


func select_class(kind: String) -> void:
	selected_unit = null
	selected_class = "" if selected_class == kind else kind


func clear_selection() -> void:
	selected_class = ""
	selected_unit = null


func cell_clicked(cell: Vector2i) -> void:
	if sim.state != "playing":
		return
	if selected_class != "":
		if sim.place_unit(selected_class, cell) != null:
			selected_class = ""
			_handle_events()
		return
	selected_unit = sim.unit_at(cell)


func upgrade_selected() -> void:
	if selected_unit != null:
		sim.upgrade_unit(selected_unit)
		_handle_events()


func dismiss_selected() -> void:
	if selected_unit != null:
		sim.dismiss_unit(selected_unit)
		selected_unit = null
		_handle_events()


func cycle_priority() -> void:
	if selected_unit != null:
		selected_unit.cycle_priority()


func call_wave() -> void:
	sim.call_next_wave()
	_handle_events()


func toggle_pause() -> void:
	paused = not paused


func toggle_speed() -> void:
	speed = speed % MAX_SPEED + 1


func toggle_language() -> void:
	TranslationServer.set_locale("en" if TranslationServer.get_locale().begins_with("pt") else "pt_BR")


func open_menu() -> void:
	paused = true
	hud.menu_panel.visible = true


func resume_game() -> void:
	hud.menu_panel.visible = false
	paused = false


## No navegador o botão fica escondido, porque a aba não pode ser fechada pelo jogo.
func quit_game() -> void:
	_save_unfinished_match("closed")
	quit_action.call()


func restart() -> void:
	_save_unfinished_match("restarted")
	_views.clear()
	for child in _entities.get_children():
		child.queue_free()
	for child in _effects.get_children():
		child.queue_free()
	sim = Simulation.new(catalog, level)
	_match_log = MatchLog.new(level.id, Time.get_datetime_string_from_system(false, true))
	_log_saved = false
	paused = false
	speed = 1
	clear_selection()
	_accumulator = 0.0
	hud.set_classes(sim.available_classes(), _frames_for_unit)
	hud.hide_result()
	hud.menu_panel.visible = false
	_place_village_marker()
	_update_village()


func has_next_level() -> bool:
	return level_index + 1 < LEVEL_IDS.size()


func open_level(index: int) -> void:
	if index < 0 or index >= LEVEL_IDS.size() or not progress.is_unlocked(index):
		return
	_save_unfinished_match("restarted")
	level_index = index
	_level_node.queue_free()
	remove_child(_level_node)
	_load_level_scene()
	restart()


func next_level() -> void:
	open_level(level_index + 1)


## O painel de fases pausa o jogo e devolve a pausa que o jogador tinha escolhido.
func toggle_levels() -> void:
	if hud.levels_panel.visible:
		hud.levels_panel.visible = false
		paused = _paused_before_levels
	else:
		_paused_before_levels = paused
		paused = true
		hud.levels_panel.visible = true


func view_count() -> int:
	return _views.size()


func view_of(state):
	return _views.get(state)


func finish_level(state: String, stars: int) -> void:
	var won := state == "won"
	if won:
		progress.record(level_index, stars)
		_save_progress()
	_save_log(state)
	hud.show_result(won, stars, won and has_next_level())


## No navegador baixa o relatório; no desktop abre a pasta com ele selecionado.
func open_last_log() -> void:
	if last_log_path == "":
		return
	if OS.has_feature("web"):
		var data := FileAccess.get_file_as_bytes(last_log_path)
		JavaScriptBridge.download_buffer(data, last_log_path.get_file(), "text/markdown")
	else:
		OS.shell_show_in_file_manager(ProjectSettings.globalize_path(last_log_path))


func _choose_level(index: int) -> void:
	hud.levels_panel.visible = false
	paused = _paused_before_levels
	open_level(index)


func _load_level_scene() -> void:
	_level_node = load(LEVEL_SCENE % LEVEL_IDS[level_index]).instantiate()
	add_child(_level_node)
	move_child(_level_node, 0)
	level = LevelReader.read(_level_node, GameData.load_level(LEVEL_IDS[level_index]))


func _save_unfinished_match(result: String) -> void:
	if _match_log != null and not _log_saved and _match_log.has_activity():
		_save_log(result)


func _save_log(result: String) -> void:
	_match_log.finish(result, sim)
	DirAccess.make_dir_recursive_absolute(log_dir)
	var stem: String = "%s/%s" % [log_dir, _match_log.file_stem()]
	var markdown := FileAccess.open(stem + ".md", FileAccess.WRITE)
	var json := FileAccess.open(stem + ".json", FileAccess.WRITE)
	if markdown == null or json == null:
		push_warning("Não foi possível salvar o log em %s" % log_dir)
		return
	markdown.store_string(_match_log.to_markdown())
	json.store_string(JSON.stringify(_match_log.to_dict(), "  "))
	last_log_path = stem + ".md"
	_log_saved = true
	print("Log da partida: ", ProjectSettings.globalize_path(last_log_path))


func _handle_events() -> void:
	var events: Array = sim.drain_events()
	_match_log.consume(events, sim)
	for event: Dictionary in events:
		match event.type:
			"monster_spawned":
				_add_monster_view(event.monster)
			"monster_killed":
				_burst(event.position, event.monster.kind)
				if event.bonus_gold > 0:
					_show_coin(event.position)
				_kill_view(event.monster)
			"monster_escaped":
				_remove_view(event.monster)
				_update_village()
			"monster_hit":
				_flash(event.monster, HIT_COLORS[event.effect])
			"unit_placed":
				_add_unit_view(event.unit)
			"unit_dismissed":
				_remove_view(event.unit)
			"unit_hit":
				_flash(event.unit)
				_play_attack(event.monster)
			"attack":
				_show_attack(event.unit, event.position, event.crit)
			"level_won":
				finish_level("won", event.stars)
			"level_lost":
				finish_level("lost", 0)


func _add_monster_view(monster) -> void:
	var data: Dictionary = catalog.monsters[monster.kind]
	var view := EntityView.new()
	view.setup(monster, _frames(data.sprite), true)
	view.shadow_radius = float(data.get("shadow", view.shadow_radius))
	_entities.add_child(view)
	_views[monster] = view


func _add_unit_view(unit) -> void:
	var view := EntityView.new()
	var level_frames := [_frames(unit.kind), _frames("%s_2" % unit.kind), _frames("%s_3" % unit.kind)]
	view.setup(unit, level_frames[0], false, level_frames)
	_entities.add_child(view)
	_views[unit] = view


func _remove_view(state) -> void:
	if _views.has(state):
		_views[state].queue_free()
		_views.erase(state)


func _flash(state, color := Color.WHITE) -> void:
	if _views.has(state):
		_views[state].flash(color)


func _play_attack(state) -> void:
	if _views.has(state):
		_views[state].play_attack()


func _kill_view(state) -> void:
	if _views.has(state):
		_views[state].play_death()
		_views.erase(state)


func _show_attack(unit, target_position: Vector2, critical := false) -> void:
	_play_attack(unit)
	if unit.stats().has("line_width"):
		_show_thrust(unit, target_position)
		return
	if unit.is_melee():
		return
	if unit.stats().has("splash_radius"):
		_show_spell(unit, target_position)
		return
	var strong: bool = unit.stats().has("pierce_extra") or critical
	var arrow := Line2D.new()
	arrow.width = 2.0 if strong else 1.0
	arrow.default_color = CRIT_COLOR if strong else Color("f4f1de")
	arrow.points = PackedVector2Array([unit.position, target_position])
	_effects.add_child(arrow)
	_fade_out(arrow, TRAIL_SECONDS if strong else ARROW_SECONDS)


func _show_thrust(unit, target_position: Vector2) -> void:
	var thrust := Line2D.new()
	thrust.width = 2.0
	thrust.default_color = THRUST_COLOR
	var reach: float = float(unit.stats().range)
	thrust.points = PackedVector2Array([unit.position, unit.position + unit.position.direction_to(target_position) * reach])
	_effects.add_child(thrust)
	_fade_out(thrust, TRAIL_SECONDS)


func _show_spell(unit, target_position: Vector2) -> void:
	var stats: Dictionary = unit.stats()
	var color: Color = FIRE_SPELL_COLOR if stats.has("fire") else SPELL_COLOR
	var bolt := Line2D.new()
	bolt.width = 1.0
	bolt.default_color = color
	bolt.points = PackedVector2Array([unit.position, target_position])
	_effects.add_child(bolt)
	_fade_out(bolt, ARROW_SECONDS)
	var ring := Line2D.new()
	ring.width = 1.0
	ring.default_color = color
	ring.closed = true
	var points := PackedVector2Array()
	for i in EXPLOSION_POINTS:
		var angle := TAU * i / EXPLOSION_POINTS
		points.append(Vector2(cos(angle), sin(angle)) * float(stats.splash_radius))
	ring.points = points
	ring.position = target_position
	_effects.add_child(ring)
	_fade_out(ring, EXPLOSION_SECONDS)


func _fade_out(node: CanvasItem, seconds: float) -> void:
	var tween := node.create_tween()
	tween.tween_property(node, "modulate:a", 0.0, seconds)
	tween.tween_callback(node.queue_free)


func _burst(at: Vector2, kind: String) -> void:
	var color := Color(catalog.monsters[kind].get("burst", "#ffffff"))
	for i in BURST_PIECES:
		var piece := ColorRect.new()
		piece.size = Vector2(2, 2)
		piece.color = color
		piece.position = at
		_effects.add_child(piece)
		var angle := TAU * i / BURST_PIECES
		var tween := piece.create_tween()
		tween.set_parallel(true)
		tween.tween_property(piece, "position", at + Vector2(cos(angle), sin(angle)) * 9.0, BURST_SECONDS)
		tween.tween_property(piece, "modulate:a", 0.0, BURST_SECONDS)
		tween.chain().tween_callback(piece.queue_free)


## Uma moeda sobe do monstro quando o abate rende ouro extra.
func _show_coin(at: Vector2) -> void:
	var coin := ColorRect.new()
	coin.size = Vector2(3, 3)
	coin.color = COIN_COLOR
	coin.position = at
	_effects.add_child(coin)
	var tween := coin.create_tween()
	tween.set_parallel(true)
	tween.tween_property(coin, "position:y", at.y - COIN_RISE, COIN_SECONDS)
	tween.tween_property(coin, "modulate:a", 0.0, COIN_SECONDS)
	tween.chain().tween_callback(coin.queue_free)


func _place_village_marker() -> void:
	var village: Sprite2D = _level_node.get_node("Village")
	hud.place_village_marker(village.position.x, village.position.y - village.texture.get_height() / 2.0)


func _update_village() -> void:
	_level_node.get_node("Village").modulate = VILLAGE_TINTS[sim.village_stage()]


func _frames(sprite: String) -> SpriteFrames:
	if not _frame_cache.has(sprite):
		_frame_cache[sprite] = load("res://assets/sprites/%s.tres" % sprite)
	return _frame_cache[sprite]


func _frames_for_unit(kind: String) -> SpriteFrames:
	return _frames(kind)


func _choose_initial_language() -> void:
	var system := OS.get_locale_language()
	TranslationServer.set_locale("pt_BR" if system == "pt" else "en")


func _load_progress():
	if not FileAccess.file_exists(progress_path):
		return Progress.new()
	var data = JSON.parse_string(FileAccess.get_file_as_string(progress_path))
	return Progress.from_dict(data) if data is Dictionary else Progress.new()


func _save_progress() -> void:
	var file := FileAccess.open(progress_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(progress.to_dict()))
