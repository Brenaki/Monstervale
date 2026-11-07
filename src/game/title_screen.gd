extends CanvasLayer
## Tela de título: monstros andam pelo mapa ao fundo enquanto quem joga escolhe o que fazer.

const UiKit = preload("res://src/game/ui_kit.gd")
const Achievements = preload("res://src/core/achievements.gd")

signal play_pressed
signal level_pressed(index: int)
signal options_pressed
signal tutorial_pressed
signal new_game_pressed
signal quit_pressed

const SCREEN := Vector2(640, 360)
const LOGO_SCALE := 4
const LOGO_Y := 34.0
const LOGO_COLOR := Color("8de3b0")
const SUBTITLE_Y := 90.0
## O menu cresce para baixo a partir daqui, conforme os botões visíveis.
const MENU := Rect2(240, 108, 160, 0)
const MENU_BUTTON := Vector2(136, 22)
const MENU_STEP := 26
const MENU_PADDING := 10
const CONFIRM_BOX := Rect2(180, 130, 280, 92)
const ACHIEVEMENTS_BOX := Rect2(150, 14, 340, 332)
const ACHIEVEMENT_ROW := 32
const ACHIEVEMENT_LOCKED := Color(1, 1, 1, 0.45)
const LEVELS_BOX := Rect2(200, 60, 240, 240)
const LEVEL_ROW_STEP := 30
const STAR_STEP := 14
## Os monstros do fundo saem um de cada vez, alternando as entradas.
const WALKER_INTERVAL := 1.4
const FOOT_OFFSET := Vector2(0, 8)
const FEET_ABOVE_CANVAS_BOTTOM := 4.0
const SHADE := Color(0, 0, 0, 0.25)

var logo: Label
var subtitle: Label
var play_button: Button
var new_game_button: Button
var levels_button: Button
var tutorial_button: Button
var achievements_button: Button
var options_button: Button
var quit_button: Button
var levels_panel: Control
var levels_title: Label
var level_buttons: Array = []
var level_stars: Array = []
var levels_close: Button
var confirm_panel: Control
var confirm_text: Label
var confirm_button: Button
var confirm_back: Button
var achievements_panel: Control
var achievements_title: Label
var achievement_icons: Array = []
var achievement_names: Array = []
var achievement_descs: Array = []
var campaign_label: Label
var achievements_close: Button

var _root: Control
var _menu: Control
var _levels_box: Control
var _demo: Node2D
var _routes: Array = []
var _kinds: Array = []
var _frames_for: Callable
var _speeds := {}
var _walkers: Array = []
var _spawn_timer := 0.0
var _spawned := 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	layer = 2
	_demo = Node2D.new()
	add_child(_demo)
	_root = Control.new()
	_root.size = SCREEN
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = UiKit.theme()
	add_child(_root)
	var shade := ColorRect.new()
	shade.size = SCREEN
	shade.color = SHADE
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(shade)
	_build_logo()
	_build_menu()
	_build_levels_panel()
	_build_confirm_panel()
	_build_achievements_panel()


## Rotas e monstros da fase ao fundo; frames_for devolve as folhas de um tipo de monstro.
func show_title(routes: Array, kinds: Array, frames_for: Callable, speeds: Dictionary) -> void:
	_routes = routes
	_kinds = kinds
	_frames_for = frames_for
	_speeds = speeds
	_clear_walkers()
	_rng.seed = 1
	_spawn_timer = 0.0
	_spawned = 0
	levels_panel.visible = false
	confirm_panel.visible = false
	achievements_panel.visible = false
	visible = true


func hide_title() -> void:
	visible = false
	levels_panel.visible = false
	_clear_walkers()


func walker_count() -> int:
	return _walkers.size()


func refresh(progress, has_progress: bool) -> void:
	logo.text = tr("TITLE_NAME")
	subtitle.text = tr("TITLE_SUBTITLE")
	play_button.text = tr("BTN_RESUME") if has_progress else tr("BTN_NEW_GAME")
	new_game_button.text = tr("BTN_NEW_GAME")
	new_game_button.visible = has_progress
	levels_button.text = tr("BTN_CHOOSE_LEVEL")
	tutorial_button.text = tr("BTN_TUTORIAL")
	achievements_button.text = tr("BTN_ACHIEVEMENTS")
	_lay_out_menu()
	confirm_text.text = tr("NEW_GAME_CONFIRM")
	confirm_button.text = tr("BTN_START_OVER")
	confirm_back.text = tr("BTN_BACK")
	_refresh_achievements(progress)
	options_button.text = tr("BTN_OPTIONS")
	quit_button.text = tr("BTN_QUIT")
	levels_title.text = tr("LEVELS_TITLE")
	levels_close.text = tr("BTN_BACK")
	for i in level_buttons.size():
		var unlocked: bool = progress.is_unlocked(i)
		level_buttons[i].disabled = not unlocked
		level_buttons[i].text = tr("TITLE_LEVEL") % (i + 1)
		var stars: Array = level_stars[i]
		for s in stars.size():
			if not unlocked:
				stars[s].texture = UiKit.icon("lock") if s == stars.size() - 1 else null
			else:
				stars[s].texture = UiKit.icon("star" if s < progress.stars_for(i) else "star_empty")


func set_levels(count: int) -> void:
	for i in count:
		var button := UiKit.button(_levels_box, Rect2(12, 28 + i * LEVEL_ROW_STEP, 216, 24))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(func(): level_pressed.emit(i))
		var stars := []
		for s in 3:
			stars.append(UiKit.texture_rect(button, null, Rect2(Vector2(166 + s * STAR_STEP, 4), Vector2(16, 16))))
		level_buttons.append(button)
		level_stars.append(stars)
	levels_close.position.y = 28 + count * LEVEL_ROW_STEP + 6
	_levels_box.size.y = levels_close.position.y + levels_close.size.y + 12
	_levels_box.position.y = (SCREEN.y - _levels_box.size.y) / 2.0


func all_buttons() -> Array:
	var buttons := [play_button, new_game_button, levels_button, tutorial_button, achievements_button, options_button, quit_button, levels_close, confirm_button, confirm_back, achievements_close]
	buttons.append_array(level_buttons)
	return buttons


func _process(delta: float) -> void:
	if not visible or _routes.is_empty() or _kinds.is_empty():
		return
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = WALKER_INTERVAL
		_spawn_walker()
	for walker: Dictionary in _walkers.duplicate():
		walker.distance += _speeds.get(walker.kind, 20.0) * delta
		var route = walker.route
		if walker.distance >= route.length:
			walker.sprite.queue_free()
			_walkers.erase(walker)
			continue
		walker.sprite.position = route.position_at(walker.distance) + FOOT_OFFSET
		var facing: int = route.horizontal_direction_at(walker.distance)
		if facing != 0:
			walker.sprite.flip_h = facing < 0


func _spawn_walker() -> void:
	var kind: String = _kinds[_rng.randi() % _kinds.size()]
	var route = _routes[_spawned % _routes.size()]
	_spawned += 1
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = _frames_for.call(kind)
	var height := sprite.sprite_frames.get_frame_texture("walk", 0).get_height()
	sprite.offset = Vector2(0, -(height / 2.0 - FEET_ABOVE_CANVAS_BOTTOM))
	sprite.position = route.position_at(0.0) + FOOT_OFFSET
	sprite.play("walk")
	_demo.add_child(sprite)
	_walkers.append({"kind": kind, "route": route, "distance": 0.0, "sprite": sprite})


func _clear_walkers() -> void:
	for walker: Dictionary in _walkers:
		walker.sprite.queue_free()
	_walkers.clear()


## O nome em letras de pixel ampliadas, com a sombra crescendo junto.
func _build_logo() -> void:
	logo = UiKit.label(_root, Rect2(0, LOGO_Y, SCREEN.x / LOGO_SCALE, 12))
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.scale = Vector2(LOGO_SCALE, LOGO_SCALE)
	logo.add_theme_color_override("font_color", LOGO_COLOR)
	subtitle = UiKit.label(_root, Rect2(0, SUBTITLE_Y, SCREEN.x, 12))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _build_menu() -> void:
	_menu = UiKit.panel(_root, MENU)
	play_button = UiKit.button(_menu, Rect2(Vector2.ZERO, MENU_BUTTON), "green")
	new_game_button = UiKit.button(_menu, Rect2(Vector2.ZERO, MENU_BUTTON))
	levels_button = UiKit.button(_menu, Rect2(Vector2.ZERO, MENU_BUTTON))
	tutorial_button = UiKit.button(_menu, Rect2(Vector2.ZERO, MENU_BUTTON))
	achievements_button = UiKit.button(_menu, Rect2(Vector2.ZERO, MENU_BUTTON))
	options_button = UiKit.button(_menu, Rect2(Vector2.ZERO, MENU_BUTTON))
	quit_button = UiKit.button(_menu, Rect2(Vector2.ZERO, MENU_BUTTON))
	play_button.pressed.connect(func(): play_pressed.emit())
	new_game_button.pressed.connect(func(): confirm_panel.visible = true)
	levels_button.pressed.connect(func(): levels_panel.visible = true)
	tutorial_button.pressed.connect(func(): tutorial_pressed.emit())
	achievements_button.pressed.connect(func(): achievements_panel.visible = true)
	options_button.pressed.connect(func(): options_pressed.emit())
	quit_button.pressed.connect(func(): quit_pressed.emit())
	_lay_out_menu()


## Empilha os botões visíveis e ajusta a altura do menu.
func _lay_out_menu() -> void:
	var x := (MENU.size.x - MENU_BUTTON.x) / 2.0
	var y := float(MENU_PADDING)
	for button: Button in [play_button, new_game_button, levels_button, tutorial_button, achievements_button, options_button, quit_button]:
		if button.visible:
			button.position = Vector2(x, y)
			y += MENU_STEP
	_menu.size.y = y - MENU_STEP + MENU_BUTTON.y + MENU_PADDING


## Quem sai pelo navegador não tem botão de sair, e o menu encolhe junto.
func hide_quit() -> void:
	quit_button.visible = false
	_lay_out_menu()


## Novo jogo com fases já vencidas pergunta antes de apagar as estrelas.
func _build_confirm_panel() -> void:
	confirm_panel = UiKit.backdrop(_root, SCREEN)
	var box := UiKit.panel(confirm_panel, CONFIRM_BOX)
	confirm_text = UiKit.label(box, Rect2(12, 10, CONFIRM_BOX.size.x - 24, 36))
	confirm_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	confirm_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confirm_back = UiKit.button(box, Rect2(24, 56, 104, 22))
	confirm_button = UiKit.button(box, Rect2(CONFIRM_BOX.size.x - 128, 56, 104, 22), "green")
	confirm_back.pressed.connect(func(): confirm_panel.visible = false)
	confirm_button.pressed.connect(func():
		confirm_panel.visible = false
		new_game_pressed.emit())


func _build_achievements_panel() -> void:
	achievements_panel = UiKit.backdrop(_root, SCREEN)
	var box := UiKit.panel(achievements_panel, ACHIEVEMENTS_BOX)
	achievements_title = UiKit.label(box, Rect2(0, 6, ACHIEVEMENTS_BOX.size.x, 16))
	achievements_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for i in Achievements.IDS.size():
		var y := 24.0 + i * ACHIEVEMENT_ROW
		achievement_icons.append(UiKit.texture_rect(box, null, Rect2(12, y + 6, 16, 16)))
		achievement_names.append(UiKit.label(box, Rect2(34, y + 2, ACHIEVEMENTS_BOX.size.x - 46, 12)))
		var desc := UiKit.label(box, Rect2(34, y + 14, ACHIEVEMENTS_BOX.size.x - 46, 12))
		desc.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
		achievement_descs.append(desc)
	var bottom := 24.0 + Achievements.IDS.size() * ACHIEVEMENT_ROW
	campaign_label = UiKit.label(box, Rect2(12, bottom + 2, ACHIEVEMENTS_BOX.size.x - 24, 12))
	campaign_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	achievements_close = UiKit.button(box, Rect2((ACHIEVEMENTS_BOX.size.x - 100) / 2.0, bottom + 18, 100, 22))
	achievements_close.pressed.connect(func(): achievements_panel.visible = false)


func _refresh_achievements(progress) -> void:
	achievements_title.text = tr("ACHIEVEMENTS_TITLE")
	achievements_close.text = tr("BTN_BACK")
	for i in Achievements.IDS.size():
		var id: String = Achievements.IDS[i]
		var key := "ACH_%s" % id.to_upper()
		var unlocked: bool = progress.has_achievement(id)
		achievement_icons[i].texture = UiKit.icon("trophy" if unlocked else "lock")
		achievement_names[i].text = tr(key)
		achievement_names[i].modulate = Color.WHITE if unlocked else ACHIEVEMENT_LOCKED
		var desc := tr(key + "_DESC")
		achievement_descs[i].text = desc % Achievements.clock(Achievements.SPEEDRUN_SECONDS) if "%s" in desc else desc
	if progress.campaign_timed():
		campaign_label.text = tr("ACH_CAMPAIGN_TIME") % Achievements.clock(progress.campaign_seconds)
	else:
		campaign_label.text = tr("ACH_CAMPAIGN_UNTIMED")


func _build_levels_panel() -> void:
	levels_panel = UiKit.backdrop(_root, SCREEN)
	_levels_box = UiKit.panel(levels_panel, LEVELS_BOX)
	levels_title = UiKit.label(_levels_box, Rect2(0, 6, LEVELS_BOX.size.x, 16))
	levels_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	levels_close = UiKit.button(_levels_box, Rect2(70, 0, 100, 22))
	levels_close.pressed.connect(func(): levels_panel.visible = false)
