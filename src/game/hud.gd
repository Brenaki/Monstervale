extends CanvasLayer
## Interface do jogo. Todo comando é um botão, porque o jogo usa só o mouse.

signal class_pressed(kind: String)
signal next_wave_pressed
signal pause_pressed
signal speed_pressed
signal restart_pressed
signal language_pressed
signal upgrade_pressed
signal dismiss_pressed
signal priority_pressed
signal close_pressed
signal log_pressed
signal next_level_pressed
signal levels_pressed
signal level_pressed(index: int)
signal menu_pressed
signal resume_pressed
signal quit_pressed

const TOP_HEIGHT := 24
const BOTTOM_TOP := 320
const SCREEN := Vector2(640, 360)
const FONT_SIZE := 10
const CLASS_BUTTON_WIDTH := 100
const ICON_MARGIN := Vector2(16, 8)
const ICON_SIZE := Vector2(30, 30)
const BAR_COLOR := Color("1b1626")
const PANEL_COLOR := Color("2a2438")
const BORDER_COLOR := Color("5d6a7a")
const BUTTON_COLOR := Color("3d4757")
const BUTTON_HOVER_COLOR := Color("56647a")
const BUTTON_PRESSED_COLOR := Color("2f6bb0")
const BUTTON_DISABLED_COLOR := Color("2a2438")
const CLASS_BAR_WIDTH := 320
const VILLAGE_BAR_SIZE := Vector2(96, 13)
const VILLAGE_LIFE_COLOR := Color("4f9d4a")
const VILLAGE_LOST_COLOR := Color("8e2f36")
const MENU_BOX := Rect2(220, 92, 200, 148)

var gold_label: Label
var lives_label: Label
var wave_label: Label
var preview_label: Label
var pause_button: Button
var speed_button: Button
var restart_button: Button
var language_button: Button
var levels_button: Button
var menu_button: Button
var menu_panel: Control
var menu_title: Label
var menu_resume: Button
var quit_button: Button
var village_bar: Panel
var village_fill: ColorRect
var village_label: Label
var next_wave_button: Button
var class_buttons := {}
var wave_box: Control
var unit_box: Control
var unit_label: Label
var upgrade_button: Button
var dismiss_button: Button
var priority_button: Button
var close_button: Button
var result_panel: Panel
var result_title: Label
var result_stars: Label
var result_restart: Button
var log_button: Button
var next_level_button: Button
var levels_panel: Control
var levels_title: Label
var level_buttons: Array = []
var levels_close: Button

var _root: Control
var _class_bar: Control
var _levels_box: Control
var _compact_classes := false


func _ready() -> void:
	_root = Control.new()
	_root.size = SCREEN
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = _make_theme()
	add_child(_root)
	_build_top_bar()
	_build_bottom_bar()
	_build_result_panel()
	_build_levels_panel()
	_build_menu_panel()
	_build_village_marker()


func set_classes(classes: Array, frames_for: Callable) -> void:
	for child in _class_bar.get_children():
		child.queue_free()
	class_buttons.clear()
	var width := mini(CLASS_BUTTON_WIDTH, (CLASS_BAR_WIDTH - 4) / maxi(classes.size(), 1) - 4)
	_compact_classes = width < CLASS_BUTTON_WIDTH
	var x := 4
	for kind: String in classes:
		var button := _button(_class_bar, Rect2(x, 3, width, 34))
		button.clip_text = false
		button.icon = _class_icon(frames_for.call(kind))
		button.toggle_mode = true
		button.pressed.connect(func(): class_pressed.emit(kind))
		class_buttons[kind] = button
		x += width + 4


func set_levels(count: int) -> void:
	for i in count:
		var button := _button(_levels_box, Rect2(12, 28 + i * 24, 216, 20))
		button.pressed.connect(func(): level_pressed.emit(i))
		level_buttons.append(button)
	levels_close = _button(_levels_box, Rect2(70, 34 + count * 24, 100, 20))
	levels_close.pressed.connect(func(): levels_pressed.emit())
	_levels_box.size.y = 62 + count * 24
	_levels_box.position.y = (SCREEN.y - _levels_box.size.y) / 2.0


## O marcador fica acima da vila, centralizado nela, sem entrar na barra superior.
func place_village_marker(center_x: float, top: float) -> void:
	village_bar.position = Vector2(center_x - VILLAGE_BAR_SIZE.x / 2.0, maxf(top - VILLAGE_BAR_SIZE.y, TOP_HEIGHT + 1))


## O quadro inteiro tem folga para armas; o ícone mostra só o corpo e a arma parada.
func _class_icon(frames: SpriteFrames) -> Texture2D:
	var frame: AtlasTexture = frames.get_frame_texture("idle", 0)
	var icon := AtlasTexture.new()
	icon.atlas = frame.atlas
	icon.region = Rect2(frame.region.position + ICON_MARGIN, ICON_SIZE)
	return icon


func refresh(game) -> void:
	var sim = game.sim
	gold_label.text = tr("HUD_GOLD") % sim.gold
	lives_label.text = tr("HUD_LIVES") % [sim.lives, sim.start_lives()]
	village_label.text = tr("VILLAGE_LIFE") % [sim.lives, sim.start_lives()]
	village_fill.size.x = VILLAGE_BAR_SIZE.x * sim.lives / sim.start_lives()
	menu_button.text = tr("BTN_MENU")
	menu_title.text = tr("MENU_TITLE")
	menu_resume.text = tr("BTN_RESUME")
	quit_button.text = tr("BTN_QUIT")
	wave_label.text = tr("HUD_WAVE") % [sim.waves_started(), sim.waves_total()]
	pause_button.text = tr("BTN_RESUME") if game.paused else tr("BTN_PAUSE")
	speed_button.text = tr("BTN_SPEED") % game.speed
	restart_button.text = tr("BTN_RESTART")
	language_button.text = tr("BTN_LANGUAGE")
	result_restart.text = tr("BTN_RESTART")
	log_button.text = tr("BTN_OPEN_LOG")
	next_level_button.text = tr("BTN_NEXT_LEVEL")
	levels_button.text = tr("BTN_LEVELS") % (game.level_index + 1)
	levels_title.text = tr("LEVELS_TITLE")
	levels_close.text = tr("BTN_CLOSE")
	for i in level_buttons.size():
		var unlocked: bool = game.progress.is_unlocked(i)
		level_buttons[i].disabled = not unlocked
		level_buttons[i].text = tr("LEVEL_ENTRY") % [i + 1, game.progress.stars_for(i)] if unlocked else tr("LEVEL_LOCKED") % (i + 1)
	for kind: String in class_buttons:
		var button: Button = class_buttons[kind]
		var cost: int = sim.unit_cost(kind)
		var unit_name := tr("UNIT_%s" % kind.to_upper())
		button.text = str(cost) if _compact_classes else "%s\n%d" % [unit_name, cost]
		button.tooltip_text = unit_name
		button.disabled = sim.gold < cost and game.selected_class != kind
		button.set_pressed_no_signal(game.selected_class == kind)
	wave_box.visible = game.selected_unit == null
	unit_box.visible = game.selected_unit != null
	if game.selected_unit != null:
		_refresh_unit(sim, game.selected_unit)
	else:
		_refresh_wave(sim)


func show_result(won: bool, stars: int, can_advance := false) -> void:
	result_title.text = tr("RESULT_WON") if won else tr("RESULT_LOST")
	result_stars.text = tr("RESULT_STARS") % stars if won else ""
	next_level_button.visible = can_advance
	result_panel.visible = true


func hide_result() -> void:
	result_panel.visible = false


func all_buttons() -> Array:
	var buttons := [
		pause_button, speed_button, restart_button, language_button, levels_button, next_wave_button,
		upgrade_button, dismiss_button, priority_button, close_button, result_restart, log_button,
		next_level_button, menu_button, menu_resume, quit_button, levels_close,
	]
	buttons.append_array(class_buttons.values())
	buttons.append_array(level_buttons)
	return buttons


func _refresh_wave(sim) -> void:
	var parts := []
	var preview: Dictionary = sim.next_wave_preview()
	for kind: String in preview:
		parts.append("%s x%d" % [tr("MONSTER_%s" % kind.to_upper()), preview[kind]])
	preview_label.text = "%s %s" % [tr("HUD_NEXT"), ", ".join(parts)] if not parts.is_empty() else ""
	var can_call: bool = sim.can_call_next_wave()
	next_wave_button.disabled = not can_call
	next_wave_button.text = tr("BTN_NEXT_WAVE") % sim.early_call_bonus() if can_call else tr("BTN_NO_WAVE")


func _refresh_unit(sim, unit) -> void:
	var name_text := tr("UNIT_%s" % unit.kind.to_upper())
	var status := tr("UNIT_DOWN") if unit.is_down() else tr("HUD_LEVEL") % unit.level
	unit_label.text = "%s - %s" % [name_text, status]
	upgrade_button.disabled = not unit.can_upgrade() or sim.gold < unit.upgrade_cost()
	upgrade_button.text = tr("BTN_UPGRADE") % unit.upgrade_cost() if unit.can_upgrade() else tr("BTN_MAX_LEVEL")
	dismiss_button.text = tr("BTN_DISMISS") % unit.refund()
	priority_button.text = tr("PRIORITY_LABEL") % tr("PRIORITY_%s" % unit.priority.to_upper())
	close_button.text = tr("BTN_CLOSE")


func _build_top_bar() -> void:
	var bar := _panel(_root, Rect2(0, 0, SCREEN.x, TOP_HEIGHT), BAR_COLOR)
	gold_label = _label(bar, Rect2(6, 3, 74, 18))
	lives_label = _label(bar, Rect2(80, 3, 84, 18))
	wave_label = _label(bar, Rect2(166, 3, 72, 18))
	levels_button = _button(bar, Rect2(240, 2, 54, 20))
	levels_button.pressed.connect(func(): levels_pressed.emit())
	pause_button = _button(bar, Rect2(298, 2, 76, 20))
	speed_button = _button(bar, Rect2(378, 2, 90, 20))
	menu_button = _button(bar, Rect2(562, 2, 74, 20))
	pause_button.pressed.connect(func(): pause_pressed.emit())
	speed_button.pressed.connect(func(): speed_pressed.emit())
	menu_button.pressed.connect(func(): menu_pressed.emit())


func _build_bottom_bar() -> void:
	var bar := _panel(_root, Rect2(0, BOTTOM_TOP, SCREEN.x, SCREEN.y - BOTTOM_TOP), BAR_COLOR)
	_class_bar = Control.new()
	_class_bar.position = Vector2.ZERO
	_class_bar.size = Vector2(320, 40)
	_class_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(_class_bar)

	wave_box = Control.new()
	wave_box.position = Vector2(324, 0)
	wave_box.size = Vector2(316, 40)
	wave_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(wave_box)
	preview_label = _label(wave_box, Rect2(0, 2, 312, 16))
	preview_label.clip_text = true
	next_wave_button = _button(wave_box, Rect2(0, 19, 150, 19))
	next_wave_button.pressed.connect(func(): next_wave_pressed.emit())

	unit_box = Control.new()
	unit_box.position = Vector2(324, 0)
	unit_box.size = Vector2(316, 40)
	unit_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	unit_box.visible = false
	bar.add_child(unit_box)
	unit_label = _label(unit_box, Rect2(0, 1, 170, 17))
	close_button = _button(unit_box, Rect2(244, 1, 68, 18))
	upgrade_button = _button(unit_box, Rect2(0, 20, 104, 18))
	dismiss_button = _button(unit_box, Rect2(106, 20, 104, 18))
	priority_button = _button(unit_box, Rect2(212, 20, 100, 18))
	upgrade_button.pressed.connect(func(): upgrade_pressed.emit())
	dismiss_button.pressed.connect(func(): dismiss_pressed.emit())
	priority_button.pressed.connect(func(): priority_pressed.emit())
	close_button.pressed.connect(func(): close_pressed.emit())


func _build_result_panel() -> void:
	result_panel = _panel(_root, Rect2(160, 120, 320, 110), PANEL_COLOR)
	result_panel.visible = false
	result_title = _label(result_panel, Rect2(0, 14, 320, 22))
	result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_stars = _label(result_panel, Rect2(0, 40, 320, 18))
	result_stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_restart = _button(result_panel, Rect2(8, 68, 98, 26))
	result_restart.pressed.connect(func(): restart_pressed.emit())
	log_button = _button(result_panel, Rect2(111, 68, 98, 26))
	log_button.pressed.connect(func(): log_pressed.emit())
	next_level_button = _button(result_panel, Rect2(214, 68, 98, 26))
	next_level_button.pressed.connect(func(): next_level_pressed.emit())


## Cobre a tela inteira para que nenhum clique chegue ao mapa com o painel aberto.
func _build_levels_panel() -> void:
	levels_panel = _panel(_root, Rect2(Vector2.ZERO, SCREEN), Color(0, 0, 0, 0.5))
	levels_panel.visible = false
	_levels_box = _panel(levels_panel, Rect2(200, 100, 240, 120), PANEL_COLOR)
	levels_title = _label(_levels_box, Rect2(0, 6, 240, 18))
	levels_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


## Cobre a tela para o jogo não receber cliques enquanto estiver pausado no menu.
func _build_menu_panel() -> void:
	menu_panel = _panel(_root, Rect2(Vector2.ZERO, SCREEN), Color(0, 0, 0, 0.5))
	menu_panel.visible = false
	var box := _panel(menu_panel, MENU_BOX, PANEL_COLOR)
	menu_title = _label(box, Rect2(0, 6, MENU_BOX.size.x, 18))
	menu_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_resume = _button(box, Rect2(12, 28, 176, 24))
	restart_button = _button(box, Rect2(12, 56, 176, 24))
	language_button = _button(box, Rect2(12, 84, 176, 24))
	quit_button = _button(box, Rect2(12, 112, 176, 24))
	menu_resume.pressed.connect(func(): resume_pressed.emit())
	restart_button.pressed.connect(func(): restart_pressed.emit())
	language_button.pressed.connect(func(): language_pressed.emit())
	quit_button.pressed.connect(func(): quit_pressed.emit())


## Vidas restantes em verde sobre as perdidas em vermelho. Não recebe cliques.
func _build_village_marker() -> void:
	village_bar = _panel(_root, Rect2(Vector2.ZERO, VILLAGE_BAR_SIZE), VILLAGE_LOST_COLOR)
	village_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.move_child(village_bar, 0)
	village_fill = ColorRect.new()
	village_fill.color = VILLAGE_LIFE_COLOR
	village_fill.size = VILLAGE_BAR_SIZE
	village_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	village_bar.add_child(village_fill)
	village_label = _label(village_bar, Rect2(Vector2.ZERO, VILLAGE_BAR_SIZE))
	village_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	village_label.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _panel(parent: Control, rect: Rect2, color: Color) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = BORDER_COLOR
	style.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	return panel


func _label(parent: Control, rect: Rect2) -> Label:
	var label := Label.new()
	label.position = rect.position
	label.size = rect.size
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	parent.add_child(label)
	return label


func _button(parent: Control, rect: Rect2) -> Button:
	var button := Button.new()
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_NONE
	button.clip_text = true
	button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	parent.add_child(button)
	return button


func _make_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = FONT_SIZE
	var font: Font = ThemeDB.fallback_font.duplicate()
	if font is FontFile:
		font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		font.hinting = TextServer.HINTING_NORMAL
	theme.default_font = font
	theme.set_stylebox("normal", "Button", _button_style(BUTTON_COLOR))
	theme.set_stylebox("hover", "Button", _button_style(BUTTON_HOVER_COLOR))
	theme.set_stylebox("pressed", "Button", _button_style(BUTTON_PRESSED_COLOR))
	theme.set_stylebox("disabled", "Button", _button_style(BUTTON_DISABLED_COLOR))
	theme.set_color("font_disabled_color", "Button", Color(1, 1, 1, 0.4))
	return theme


func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = BORDER_COLOR
	style.set_border_width_all(1)
	style.content_margin_left = 3
	style.content_margin_right = 3
	return style
