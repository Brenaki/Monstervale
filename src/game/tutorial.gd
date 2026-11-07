extends Control
## Guia passo a passo: aponta um ponto da tela, explica e espera o jogador agir.
## Cada passo tem o texto, o alvo e, quando espera uma ação, o evento que o encerra (wait);
## sem wait, o passo termina no botão Entendi.

const UiKit = preload("res://src/game/ui_kit.gd")

signal finished(level_id: String)

const SCREEN := Vector2(640, 360)
const BOX_WIDTH := 240.0
const PADDING := 6.0
const LINE_HEIGHT := 12.0
const BUTTON_HEIGHT := 18.0
const SKIP_WIDTH := 96.0
const OK_WIDTH := 64.0
const TOP_Y := 28.0
const BOTTOM_Y := 316.0
const MARGIN := 4.0
const ARROW := Vector2(16, 16)
const BOB := 3.0
const BOB_SPEED := 0.008
const PULSE_SPEED := 0.006
const HIGHLIGHT_COLOR := Color("f6e05e")
const HIGHLIGHT_BORDER := 2

var level_id := ""
var steps: Array = []
var index := 0
var box: Panel
var text_label: Label
var ok_button: Button
var skip_button: Button
var highlight: Panel
var arrow: TextureRect


func _ready() -> void:
	size = SCREEN
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UiKit.theme()
	visible = false
	highlight = Panel.new()
	var frame := StyleBoxFlat.new()
	frame.draw_center = false
	frame.border_color = HIGHLIGHT_COLOR
	frame.set_border_width_all(HIGHLIGHT_BORDER)
	highlight.add_theme_stylebox_override("panel", frame)
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(highlight)
	arrow = UiKit.texture_rect(self, UiKit.icon("arrow"), Rect2(Vector2.ZERO, ARROW))
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box = UiKit.panel(self, Rect2(0, 0, BOX_WIDTH, 60))
	text_label = UiKit.label(box, Rect2(PADDING, PADDING, BOX_WIDTH - PADDING * 2, LINE_HEIGHT))
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	skip_button = UiKit.button(box, Rect2(PADDING, 0, SKIP_WIDTH, BUTTON_HEIGHT))
	ok_button = UiKit.button(box, Rect2(BOX_WIDTH - PADDING - OK_WIDTH, 0, OK_WIDTH, BUTTON_HEIGHT), "green")
	ok_button.pressed.connect(_advance)
	skip_button.pressed.connect(skip)


func start(id: String, list: Array) -> void:
	level_id = id
	steps = list
	index = 0


func stop() -> void:
	steps = []
	index = 0
	visible = false


func active() -> bool:
	return index < steps.size()


func current() -> Dictionary:
	return steps[index] if active() else {}


## O jogo avisa o que o jogador fez, como "unit_placed:archer"; o passo que esperava isso termina.
func notify(event: String) -> void:
	if active() and current().get("wait", "") == event:
		_advance()


func skip() -> void:
	index = steps.size()
	_finish()


## target vem do jogo, em coordenadas de tela; vazio quando não há o que apontar.
func show_step(target: Rect2, hidden: bool) -> void:
	visible = active() and not hidden
	if not visible:
		return
	var step := current()
	text_label.text = tr(step.text)
	ok_button.text = tr("BTN_OK")
	skip_button.text = tr("BTN_SKIP_TUTORIAL")
	ok_button.visible = not step.has("wait")
	var lines := maxi(1, text_label.get_line_count())
	text_label.size.y = lines * LINE_HEIGHT
	var buttons_y := PADDING + lines * LINE_HEIGHT + PADDING
	skip_button.position.y = buttons_y
	ok_button.position.y = buttons_y
	box.size.y = buttons_y + BUTTON_HEIGHT + PADDING
	box.position = _box_position(target)
	_point_at(target)


func _box_position(target: Rect2) -> Vector2:
	if not target.has_area():
		return ((SCREEN - box.size) / 2.0).floor()
	var x := clampf(target.get_center().x - box.size.x / 2.0, MARGIN, SCREEN.x - MARGIN - box.size.x)
	# Alvo embaixo, caixa em cima; alvo em cima, caixa embaixo.
	var y := TOP_Y if target.get_center().y > SCREEN.y / 2.0 else BOTTOM_Y - MARGIN - box.size.y
	return Vector2(x, y).floor()


func _point_at(target: Rect2) -> void:
	highlight.visible = target.has_area()
	arrow.visible = target.has_area()
	if not target.has_area():
		return
	var ticks := Time.get_ticks_msec()
	highlight.position = target.position - Vector2.ONE * HIGHLIGHT_BORDER
	highlight.size = target.size + Vector2.ONE * HIGHLIGHT_BORDER * 2
	highlight.modulate.a = 0.8 + 0.2 * sin(ticks * PULSE_SPEED)
	var bob := roundf(BOB * sin(ticks * BOB_SPEED))
	var x := floorf(target.get_center().x - ARROW.x / 2.0)
	# Perto do topo a seta fica embaixo do alvo, apontando para cima.
	arrow.flip_v = target.position.y < TOP_Y + ARROW.y
	if arrow.flip_v:
		arrow.position = Vector2(x, target.end.y + HIGHLIGHT_BORDER + 1 + bob)
	else:
		arrow.position = Vector2(x, target.position.y - HIGHLIGHT_BORDER - ARROW.y - 1 - bob)


func _advance() -> void:
	index += 1
	if not active():
		_finish()


func _finish() -> void:
	var id := level_id
	stop()
	finished.emit(id)
