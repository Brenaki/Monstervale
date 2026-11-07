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
const Settings = preload("res://src/core/settings.gd")
const TitleScreen = preload("res://src/game/title_screen.gd")
const OptionsPanel = preload("res://src/game/options_panel.gd")
const SoundBoard = preload("res://src/game/sound_board.gd")
const VillageView = preload("res://src/game/village_view.gd")
const Tutorial = preload("res://src/game/tutorial.gd")
const Achievements = preload("res://src/core/achievements.gd")

const LEVEL_IDS := ["level_01", "level_02", "level_03", "level_04", "level_05"]
const LEVEL_SCENE := "res://src/game/levels/%s.tscn"
const TUTORIAL_PATH := "res://data/tutorial.json"
const STEP := 1.0 / 60.0
const MAX_SPEED := 2
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
const DEV_GOLD := 9999
const ATTACK_SOUNDS := {
	"archer": "arrow", "rogue": "knife", "warrior": "sword", "spearman": "thrust",
	"monk": "punch", "mage": "spell", "druid": "nature",
}

var progress_path := "user://progress.json"
var settings_path := "user://settings.json"
## Os testes começam direto na fase; quem joga começa pela tela de título.
var start_on_title := true
## Só os builds de desenvolvimento, como o editor, têm modo dev.
var dev_build := OS.is_debug_build()
var log_dir := "user://partidas"
var last_log_path := ""
var catalog: Dictionary
var level: Dictionary
var level_index := 0
var sim
var progress
var hud
var title
var options
var settings
var sounds
var village
var tutorial
var tutorial_steps: Dictionary
## Os testes que repetem partidas desligam o tutorial, que tomaria cliques no mapa.
var tutorials_enabled := true
var speed := 1
var paused := false
var selected_class := ""
var selected_unit = null
var hover_cell := NO_CELL
var quit_action := func(): get_tree().quit()

var _level_node: Node
var _overlay: Node2D
var _entities: Node2D
var _effects: Node2D
var _views := {}
var _frame_cache := {}
var _accumulator := 0.0
var _match_log
## O tempo desta partida já entrou no relógio da campanha.
var _match_timed := false
var _log_saved := false
var _paused_before_levels := false


func _ready() -> void:
	catalog = GameData.load_catalog()
	progress = _load_progress()
	settings = _load_settings()
	sounds = SoundBoard.new()
	add_child(sounds)
	get_tree().node_added.connect(_on_node_added)
	level_index = progress.furthest_unlocked(LEVEL_IDS.size())
	_load_level_scene()

	_overlay = Overlay.new()
	_overlay.game = self
	add_child(_overlay)
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
	hud.options_pressed.connect(open_options)
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
	hud.main_menu_pressed.connect(show_title)
	hud.set_levels(LEVEL_IDS.size())
	hud.set_monster_frames(_monster_frames)

	title = TitleScreen.new()
	add_child(title)
	title.set_levels(LEVEL_IDS.size())
	title.play_pressed.connect(play)
	title.new_game_pressed.connect(new_game)
	title.tutorial_pressed.connect(replay_tutorial)
	title.level_pressed.connect(start_level)
	title.options_pressed.connect(open_options)
	title.quit_pressed.connect(quit_game)
	if OS.has_feature("web"):
		title.hide_quit()
	title.visible = false

	tutorial_steps = JSON.parse_string(FileAccess.get_file_as_string(TUTORIAL_PATH))
	var tutorial_layer := CanvasLayer.new()
	add_child(tutorial_layer)
	tutorial = Tutorial.new()
	tutorial_layer.add_child(tutorial)
	tutorial.finished.connect(_on_tutorial_finished)
	var options_layer := CanvasLayer.new()
	options_layer.layer = 3
	add_child(options_layer)
	options = OptionsPanel.new()
	options.settings = settings
	options_layer.add_child(options)
	options.changed.connect(_on_settings_changed)
	options.language_pressed.connect(toggle_language)
	options.dev_available = dev_build

	_choose_initial_language()
	_apply_settings()
	restart()
	if start_on_title:
		show_title()


func _process(delta: float) -> void:
	if _dev("dev_infinite_gold") and sim.state == "playing":
		sim.gold = DEV_GOLD
	advance(delta)
	var time_scale := 0.0 if paused or sim.state != "playing" else float(speed)
	for state in _views:
		_views[state].sync(delta, time_scale)
	hud.refresh(self)
	_show_tutorial()
	_update_music()
	if title.visible:
		title.refresh(progress, progress.has_save())


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_unfinished_match("closed")
		_count_campaign_time()


func _unhandled_input(event: InputEvent) -> void:
	if title.visible or options.visible:
		return
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
	if selected_class != "":
		tutorial.notify("class_selected:%s" % kind)


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
	if selected_unit != null:
		tutorial.notify("unit_selected:%s" % selected_unit.kind)


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
		tutorial.notify("priority_changed")


func call_wave() -> void:
	sim.call_next_wave()
	_handle_events()


func toggle_pause() -> void:
	paused = not paused


func toggle_speed() -> void:
	speed = speed % MAX_SPEED + 1


func toggle_language() -> void:
	TranslationServer.set_locale("en" if TranslationServer.get_locale().begins_with("pt") else "pt_BR")
	settings.locale = TranslationServer.get_locale()
	_save_settings()
	options.refresh()


## A partida em andamento fica salva como abandonada, e o mapa da fase vira o fundo do título.
func show_title() -> void:
	_save_unfinished_match("left")
	tutorial.stop()
	hud.menu_panel.visible = false
	hud.levels_panel.visible = false
	restart()
	paused = true
	_set_match_visible(false)
	var kinds := {}
	for wave: Dictionary in level.waves:
		for group: Dictionary in wave.groups:
			kinds[group.monster] = true
	var speeds := {}
	for kind: String in kinds:
		speeds[kind] = float(catalog.monsters[kind].speed)
	title.show_title(sim.routes, kinds.keys(), _monster_frames, speeds)
	title.refresh(progress, progress.has_save())


## Sai do título para jogar a fase escolhida, do começo.
func start_level(index: int) -> void:
	title.hide_title()
	_set_match_visible(true)
	if index != level_index and progress.is_unlocked(index):
		open_level(index)
	else:
		restart()
	paused = false
	_begin_tutorial()


## Continuar segue da fase mais adiante; sem jogo salvo, começa um novo.
func play() -> void:
	if progress.has_save():
		start_level(progress.furthest_unlocked(LEVEL_IDS.size()))
	else:
		new_game()


## Apaga as estrelas e zera o relógio da campanha; as conquistas ficam.
func new_game() -> void:
	progress.new_game()
	_save_progress()
	start_level(0)


## O botão Tutorial do título: todas as fases voltam a explicar, começando pela primeira.
func replay_tutorial() -> void:
	progress.forget_tutorials()
	_save_progress()
	start_level(0)


## key é uma das chaves do modo dev nas configurações, como "dev_record".
func set_dev(key: String, on: bool) -> void:
	settings.set(key, on)
	options.refresh()
	_on_settings_changed()


## O modo dev serve para medir a dificuldade das fases: só ele registra partidas.
func dev_active() -> bool:
	return dev_build and settings.dev_mode


func recording() -> bool:
	return _dev("dev_record")


func _dev(key: String) -> bool:
	return dev_active() and settings.get(key)


## Vila imortal ou ouro infinito não dão estrelas.
func _cheating() -> bool:
	return _dev("dev_invincible") or _dev("dev_infinite_gold")


func _apply_dev() -> void:
	sim.invincible = _dev("dev_invincible")
	hud.dev_badge.visible = dev_active()
	hud.set_report_available(recording())


func open_options() -> void:
	options.open()


func _set_match_visible(shown: bool) -> void:
	hud.visible = shown
	_overlay.visible = shown
	_entities.visible = shown
	_effects.visible = shown


func _on_settings_changed() -> void:
	_apply_settings()
	_apply_dev()
	# Ajuda do modo dev invalida o speedrun da campanha inteira.
	if _cheating() and progress.campaign_timed():
		progress.void_campaign()
		_save_progress()
	_save_settings()


func _apply_settings() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), Settings.volume_db(settings.music_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sfx"), Settings.volume_db(settings.sfx_volume))
	if DisplayServer.get_name() == "headless":
		return
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if settings.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)


func _load_settings():
	if not FileAccess.file_exists(settings_path):
		return Settings.new()
	var data = JSON.parse_string(FileAccess.get_file_as_string(settings_path))
	return Settings.from_dict(data) if data is Dictionary else Settings.new()


func _save_settings() -> void:
	var file := FileAccess.open(settings_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(settings.to_dict()))


## Gosma para slimes, ossos para esqueletos e um ganido para os bichos.
func death_sound(kind: String) -> String:
	if kind.begins_with("slime"):
		return "death_slime"
	if kind.begins_with("skeleton"):
		return "death_bones"
	return "death_beast"


## Título, fase e chefe têm músicas próprias; no fim da partida fica só a vinheta.
func _update_music() -> void:
	if title.visible:
		sounds.play_music("title")
	elif sim.state != "playing" or hud.result_panel.visible:
		sounds.play_music("")
	elif sim.boss() != null:
		sounds.play_music("boss")
	else:
		sounds.play_music("battle")


## Todo botão do jogo faz um clique, inclusive os que nascem depois, como as cartas.
func _on_node_added(node: Node) -> void:
	if node is Button and is_ancestor_of(node):
		node.pressed.connect(sounds.play.bind("click"))


func _monster_frames(kind: String) -> SpriteFrames:
	return _frames(catalog.monsters[kind].sprite)


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
	_count_campaign_time()
	_views.clear()
	for child in _entities.get_children():
		child.queue_free()
	for child in _effects.get_children():
		child.queue_free()
	sim = Simulation.new(catalog, level)
	_match_timed = false
	_apply_dev()
	_match_log = MatchLog.new(level.id, Time.get_datetime_string_from_system(false, true))
	_log_saved = false
	paused = false
	speed = 1
	clear_selection()
	_accumulator = 0.0
	hud.set_classes(sim.available_classes(), _frames_for_unit)
	hud.hide_result()
	hud.menu_panel.visible = false
	_update_village(false)
	if tutorial.active():
		tutorial.start(tutorial.level_id, tutorial.steps)


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
	_begin_tutorial()


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
	_count_campaign_time()
	if won and not _cheating():
		progress.record(level_index, stars)
		for id: String in Achievements.after_win(progress, level_index, LEVEL_IDS.size()):
			_announce(id)
		_save_progress()
	if recording():
		_save_log(state)
	sounds.play("won" if won else "lost")
	hud.show_result(won, stars, won and has_next_level(), won and not has_next_level())


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
	# A arte inteira da vila fica na cena para o editor; no jogo ela vira peças que desabam.
	var village_sprite: Sprite2D = _level_node.get_node("Village")
	village_sprite.self_modulate.a = 0.0
	village = VillageView.new()
	village.position = -village_sprite.texture.get_size() / 2.0
	village.collapsed.connect(func(_part): sounds.play("collapse"))
	village_sprite.add_child(village)


func _save_unfinished_match(result: String) -> void:
	if not recording():
		return
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
				if event.monster.boss:
					sounds.play("boss_roar")
			"monster_killed":
				_burst(event.position, event.monster.kind)
				if event.monster.boss and not _cheating() and progress.unlock(Achievements.HERO):
					_announce(Achievements.HERO)
					_save_progress()
				sounds.play(death_sound(event.monster.kind))
				if event.bonus_gold > 0:
					_show_coin(event.position)
					sounds.play("coin")
				_kill_view(event.monster)
			"monster_escaped":
				_remove_view(event.monster)
				_update_village()
				sounds.play("escaped")
			"monster_hit":
				_flash(event.monster, HIT_COLORS[event.effect])
			"monster_split":
				if _views.has(event.monster):
					_views[event.monster].play_split()
				sounds.play("boss_split")
			"unit_placed":
				_add_unit_view(event.unit)
				sounds.play("place")
				tutorial.notify("unit_placed:%s" % event.unit.kind)
			"unit_upgraded":
				sounds.play("upgrade")
				tutorial.notify("unit_upgraded:%s" % event.unit.kind)
			"unit_dismissed":
				_remove_view(event.unit)
				sounds.play("dismiss")
			"unit_down":
				sounds.play("unit_down")
			"unit_up":
				sounds.play("unit_up")
			"wave_started":
				sounds.play("wave_start")
				tutorial.notify("wave_started")
			"wave_cleared":
				tutorial.notify("wave_cleared")
			"unit_hit":
				_flash(event.unit)
				_play_attack(event.monster)
			"attack":
				_show_attack(event.unit, event.position, event.crit)
				sounds.play(ATTACK_SOUNDS.get(event.unit.kind, ""))
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


func _update_village(animate := true) -> void:
	village.show_lives(sim.lives, sim.start_lives(), animate)


func _frames(sprite: String) -> SpriteFrames:
	if not _frame_cache.has(sprite):
		_frame_cache[sprite] = load("res://assets/sprites/%s.tres" % sprite)
	return _frame_cache[sprite]


func _frames_for_unit(kind: String) -> SpriteFrames:
	return _frames(kind)


func _choose_initial_language() -> void:
	if settings.locale != "":
		TranslationServer.set_locale(settings.locale)
		return
	var system := OS.get_locale_language()
	TranslationServer.set_locale("pt_BR" if system == "pt" else "en")


func _load_progress():
	if not FileAccess.file_exists(progress_path):
		return Progress.new()
	var data = JSON.parse_string(FileAccess.get_file_as_string(progress_path))
	var loaded = Progress.from_dict(data) if data is Dictionary else Progress.new()
	Achievements.from_stars(loaded, LEVEL_IDS.size())
	return loaded


func _save_progress() -> void:
	var file := FileAccess.open(progress_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(progress.to_dict()))


# Tutorial ---------------------------------------------------------------------

## A primeira vez em cada fase explica o que ela traz de novo.
func _begin_tutorial() -> void:
	var id: String = LEVEL_IDS[level_index]
	if tutorials_enabled and tutorial_steps.has(id) and not progress.saw_tutorial(id):
		tutorial.start(id, tutorial_steps[id])
	else:
		tutorial.stop()


func _on_tutorial_finished(id: String) -> void:
	progress.mark_tutorial(id)
	_save_progress()


func _show_tutorial() -> void:
	var hidden: bool = title.visible or options.visible or hud.menu_panel.visible or hud.levels_panel.visible or hud.result_panel.visible
	tutorial.show_step(tutorial_target(tutorial.current().get("target", "")), hidden)


## Onde fica na tela o alvo de um passo do tutorial, como "class:archer" ou "cell:7,5".
func tutorial_target(target: String) -> Rect2:
	var parts := target.split(":")
	match parts[0]:
		"village":
			var sprite: Sprite2D = _level_node.get_node("Village")
			var size := sprite.texture.get_size()
			return Rect2(sprite.global_position - size / 2.0, size)
		"top_panel":
			return hud.top_panel.get_global_rect()
		"gold":
			return _children_rect(hud.gold_label.get_parent())
		"wave_count":
			return _children_rect(hud.wave_label.get_parent())
		"class":
			return hud.class_buttons[parts[1]].get_global_rect() if hud.class_buttons.has(parts[1]) else Rect2()
		"cell":
			var xy := parts[1].split(",")
			return _cell_rect(Vector2i(int(xy[0]), int(xy[1])))
		"preview":
			return _children_rect(hud.preview_label.get_parent())
		"weak":
			return _children_rect(hud.weak_label.get_parent())
		"next_wave":
			return hud.next_wave_button.get_global_rect()
		"speed":
			return hud.speed_button.get_global_rect()
		"upgrade":
			return _ring_or_unit(hud.upgrade_button, parts[1])
		"priority":
			return _ring_or_unit(hud.priority_button, "")
	return Rect2()


## Com o humano selecionado, o botão do anel; senão, o próprio humano.
func _ring_or_unit(button: Button, kind: String) -> Rect2:
	if selected_unit != null and hud.ring.visible:
		return button.get_global_rect()
	for unit in sim.units:
		if kind == "" or unit.kind == kind:
			return _cell_rect(unit.cell)
	return Rect2()


## Fileiras da HUD não têm tamanho próprio: a área é a soma do que está visível nelas.
func _children_rect(row: Control) -> Rect2:
	var area := Rect2()
	for child: Control in row.find_children("*", "Control", true, false):
		if child.is_visible_in_tree() and child.size.x > 0.0 and child.size.y > 0.0:
			area = child.get_global_rect() if not area.has_area() else area.merge(child.get_global_rect())
	return area


func _cell_rect(cell: Vector2i) -> Rect2:
	var size := float(level.cell_size)
	return Rect2(Vector2(cell) * size, Vector2(size, size))


# Conquistas ------------------------------------------------------------------------

## Soma o tempo desta partida ao relógio da campanha, uma vez só; com ajuda do modo dev, o relógio para.
func _count_campaign_time() -> void:
	if sim == null or _match_timed:
		return
	_match_timed = true
	if _cheating():
		progress.void_campaign()
	elif sim.elapsed > 0.0:
		progress.add_campaign_time(sim.elapsed)
	else:
		return
	_save_progress()


func _announce(id: String) -> void:
	hud.show_achievement(tr("ACH_%s" % id.to_upper()))
	sounds.play("achievement")
