extends Node2D
## Liga a simulação às cenas: avança o tempo, responde aos botões e desenha eventos.

const GameData = preload("res://src/core/game_data.gd")
const Simulation = preload("res://src/core/simulation.gd")
const Progress = preload("res://src/core/progress.gd")
const LevelReader = preload("res://src/game/level_reader.gd")
const EntityView = preload("res://src/game/entity_view.gd")
const Overlay = preload("res://src/game/overlay.gd")
const Hud = preload("res://src/game/hud.gd")

const LEVEL_INDEX := 0
const LEVEL_ID := "level_01"
const LEVEL_SCENE := "res://src/game/levels/level_01.tscn"
const STEP := 1.0 / 60.0
const MAX_SPEED := 2
const VILLAGE_TINTS := [Color.WHITE, Color(0.8, 0.7, 0.65), Color(0.5, 0.42, 0.42)]
const BURST_PIECES := 5
const BURST_SECONDS := 0.35
const ARROW_SECONDS := 0.12
const NO_CELL := Vector2i(-1, -1)

var progress_path := "user://progress.json"
var catalog: Dictionary
var level: Dictionary
var sim
var progress
var hud
var speed := 1
var paused := false
var selected_class := ""
var selected_unit = null
var hover_cell := NO_CELL

var _level_node: Node
var _entities: Node2D
var _effects: Node2D
var _views := {}
var _frame_cache := {}
var _accumulator := 0.0


func _ready() -> void:
	catalog = GameData.load_catalog()
	progress = _load_progress()
	_level_node = load(LEVEL_SCENE).instantiate()
	add_child(_level_node)
	level = LevelReader.read(_level_node, GameData.load_level(LEVEL_ID))

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

	_choose_initial_language()
	restart()


func _process(delta: float) -> void:
	advance(delta)
	for state in _views:
		_views[state].sync(delta)
	hud.refresh(self)


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


func restart() -> void:
	for state in _views:
		_views[state].queue_free()
	_views.clear()
	for child in _effects.get_children():
		child.queue_free()
	sim = Simulation.new(catalog, level)
	paused = false
	speed = 1
	clear_selection()
	_accumulator = 0.0
	hud.set_classes(sim.available_classes(), _frames_for_unit)
	hud.hide_result()
	_update_village()


func view_count() -> int:
	return _views.size()


func finish_level(state: String, stars: int) -> void:
	var won := state == "won"
	if won:
		progress.record(LEVEL_INDEX, stars)
		_save_progress()
	hud.show_result(won, stars)


func _handle_events() -> void:
	for event: Dictionary in sim.drain_events():
		match event.type:
			"monster_spawned":
				_add_monster_view(event.monster)
			"monster_killed":
				_burst(event.position, event.monster.kind)
				_remove_view(event.monster)
			"monster_escaped":
				_remove_view(event.monster)
				_update_village()
			"monster_hit":
				_flash(event.monster)
			"unit_placed":
				_add_unit_view(event.unit)
			"unit_dismissed":
				_remove_view(event.unit)
			"unit_hit":
				_flash(event.unit)
				_lunge(event.monster, event.monster.facing)
			"attack":
				_show_attack(event.unit, event.position)
			"level_won":
				finish_level("won", event.stars)
			"level_lost":
				finish_level("lost", 0)


func _add_monster_view(monster) -> void:
	var data: Dictionary = catalog.monsters[monster.kind]
	var view := EntityView.new()
	view.setup(monster, _frames(data.sprite), true, Color(data.get("tint", "#ffffff")))
	_entities.add_child(view)
	_views[monster] = view


func _add_unit_view(unit) -> void:
	var view := EntityView.new()
	view.setup(unit, _frames_for_unit(unit.kind), false)
	_entities.add_child(view)
	_views[unit] = view


func _remove_view(state) -> void:
	if _views.has(state):
		_views[state].queue_free()
		_views.erase(state)


func _flash(state) -> void:
	if _views.has(state):
		_views[state].flash()


func _lunge(state, direction: int) -> void:
	if _views.has(state):
		_views[state].lunge(direction)


func _show_attack(unit, target_position: Vector2) -> void:
	if unit.is_melee():
		_lunge(unit, unit.facing)
		return
	var arrow := Line2D.new()
	arrow.width = 1.0
	arrow.default_color = Color("f6e05e") if unit.stats().has("pierce_extra") else Color("f4f1de")
	arrow.points = PackedVector2Array([unit.position, target_position])
	_effects.add_child(arrow)
	var tween := arrow.create_tween()
	tween.tween_property(arrow, "modulate:a", 0.0, ARROW_SECONDS)
	tween.tween_callback(arrow.queue_free)


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
