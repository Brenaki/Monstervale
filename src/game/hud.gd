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

const TOP_HEIGHT := 24
const BOTTOM_TOP := 320
const SCREEN := Vector2(640, 360)
const FONT_SIZE := 10
const CLASS_BUTTON_WIDTH := 100
const BAR_COLOR := Color("1b1626")
const PANEL_COLOR := Color("2a2438")
const BORDER_COLOR := Color("5d6a7a")
const BUTTON_COLOR := Color("3d4757")
const BUTTON_HOVER_COLOR := Color("56647a")
const BUTTON_PRESSED_COLOR := Color("2f6bb0")
const BUTTON_DISABLED_COLOR := Color("2a2438")

var gold_label: Label
var lives_label: Label
var wave_label: Label
var preview_label: Label
var pause_button: Button
var speed_button: Button
var restart_button: Button
var language_button: Button
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

var _root: Control
var _class_bar: Control


func _ready() -> void:
	_root = Control.new()
	_root.size = SCREEN
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = _make_theme()
	add_child(_root)
	_build_top_bar()
	_build_bottom_bar()
	_build_result_panel()


func set_classes(classes: Array, frames_for: Callable) -> void:
	for child in _class_bar.get_children():
		child.queue_free()
	class_buttons.clear()
	var x := 4
	for kind: String in classes:
		var button := _button(_class_bar, Rect2(x, 3, CLASS_BUTTON_WIDTH, 34))
		button.clip_text = false
		button.icon = frames_for.call(kind).get_frame_texture("idle", 0)
		button.toggle_mode = true
		button.pressed.connect(func(): class_pressed.emit(kind))
		class_buttons[kind] = button
		x += CLASS_BUTTON_WIDTH + 4


func refresh(game) -> void:
	var sim = game.sim
	gold_label.text = tr("HUD_GOLD") % sim.gold
	lives_label.text = tr("HUD_LIVES") % sim.lives
	wave_label.text = tr("HUD_WAVE") % [sim.waves_started(), sim.waves_total()]
	pause_button.text = tr("BTN_RESUME") if game.paused else tr("BTN_PAUSE")
	speed_button.text = tr("BTN_SPEED") % game.speed
	restart_button.text = tr("BTN_RESTART")
	language_button.text = tr("BTN_LANGUAGE")
	result_restart.text = tr("BTN_RESTART")
	for kind: String in class_buttons:
		var button: Button = class_buttons[kind]
		var cost: int = sim.unit_cost(kind)
		button.text = "%s\n%d" % [tr("UNIT_%s" % kind.to_upper()), cost]
		button.disabled = sim.gold < cost and game.selected_class != kind
		button.set_pressed_no_signal(game.selected_class == kind)
	wave_box.visible = game.selected_unit == null
	unit_box.visible = game.selected_unit != null
	if game.selected_unit != null:
		_refresh_unit(sim, game.selected_unit)
	else:
		_refresh_wave(sim)


func show_result(won: bool, stars: int) -> void:
	result_title.text = tr("RESULT_WON") if won else tr("RESULT_LOST")
	result_stars.text = tr("RESULT_STARS") % stars if won else ""
	result_panel.visible = true


func hide_result() -> void:
	result_panel.visible = false


func all_buttons() -> Array:
	var buttons := [
		pause_button, speed_button, restart_button, language_button, next_wave_button,
		upgrade_button, dismiss_button, priority_button, close_button, result_restart,
	]
	buttons.append_array(class_buttons.values())
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
	gold_label = _label(bar, Rect2(6, 3, 80, 18))
	lives_label = _label(bar, Rect2(86, 3, 70, 18))
	wave_label = _label(bar, Rect2(156, 3, 80, 18))
	pause_button = _button(bar, Rect2(286, 2, 76, 20))
	speed_button = _button(bar, Rect2(364, 2, 90, 20))
	restart_button = _button(bar, Rect2(456, 2, 86, 20))
	language_button = _button(bar, Rect2(544, 2, 92, 20))
	pause_button.pressed.connect(func(): pause_pressed.emit())
	speed_button.pressed.connect(func(): speed_pressed.emit())
	restart_button.pressed.connect(func(): restart_pressed.emit())
	language_button.pressed.connect(func(): language_pressed.emit())


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
	result_panel = _panel(_root, Rect2(190, 120, 260, 110), PANEL_COLOR)
	result_panel.visible = false
	result_title = _label(result_panel, Rect2(0, 14, 260, 22))
	result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_stars = _label(result_panel, Rect2(0, 40, 260, 18))
	result_stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_restart = _button(result_panel, Rect2(80, 68, 100, 26))
	result_restart.pressed.connect(func(): restart_pressed.emit())


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
