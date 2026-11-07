extends Control
## Opções de volume, idioma e tela cheia. Abre por cima da tela de título ou do menu de pausa.

const UiKit = preload("res://src/game/ui_kit.gd")

signal changed
signal language_pressed

const SCREEN := Vector2(640, 360)
const BOX := Rect2(190, 84, 260, 168)
const SEGMENTS := 10
const SEGMENT := Vector2(8, 10)
const SEGMENT_STEP := 9
const VOLUME_ON := Color("7fbb4e")
const VOLUME_OFF := Color("3d3550")
const ROW_STEP := 26
const FIRST_DEV_ROW := 132.0
## Cada chave do modo dev, com o texto ligado e desligado.
const DEV_SWITCHES := {
	"dev_mode": ["OPT_DEV_ON", "OPT_DEV_OFF"],
	"dev_invincible": ["OPT_INVINCIBLE_ON", "OPT_INVINCIBLE_OFF"],
	"dev_infinite_gold": ["OPT_GOLD_ON", "OPT_GOLD_OFF"],
	"dev_record": ["OPT_RECORD_ON", "OPT_RECORD_OFF"],
}

var settings
## Só os builds de desenvolvimento mostram o modo dev.
var dev_available := false
var title: Label
var music_label: Label
var sfx_label: Label
var music_down: Button
var music_up: Button
var sfx_down: Button
var sfx_up: Button
var music_bar: Array = []
var sfx_bar: Array = []
var language_button: Button
var fullscreen_button: Button
var dev_button: Button
var invincible_button: Button
var gold_button: Button
var record_button: Button
var back_button: Button

var _box: Control


func _ready() -> void:
	size = SCREEN
	visible = false
	theme = UiKit.theme()
	UiKit.backdrop(self, SCREEN).visible = true
	var box := UiKit.panel(self, BOX)
	_box = box
	title = UiKit.label(box, Rect2(0, 6, BOX.size.x, 16))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	music_label = _volume_row(box, 30, "note", "music", music_bar)
	sfx_label = _volume_row(box, 54, "speaker", "sfx", sfx_bar)
	music_down = box.get_node("music_down")
	music_up = box.get_node("music_up")
	sfx_down = box.get_node("sfx_down")
	sfx_up = box.get_node("sfx_up")
	language_button = UiKit.button(box, Rect2(16, 80, 228, 22))
	fullscreen_button = UiKit.button(box, Rect2(16, 106, 228, 22))
	dev_button = _dev_switch(box, "dev_mode")
	invincible_button = _dev_switch(box, "dev_invincible")
	gold_button = _dev_switch(box, "dev_infinite_gold")
	record_button = _dev_switch(box, "dev_record")
	back_button = UiKit.button(box, Rect2(16, 136, 228, 22))
	language_button.pressed.connect(func(): language_pressed.emit())
	fullscreen_button.pressed.connect(_toggle_fullscreen)
	back_button.pressed.connect(close)


func open() -> void:
	refresh()
	visible = true


func close() -> void:
	visible = false


func refresh() -> void:
	title.text = tr("OPTIONS_TITLE")
	music_label.text = tr("OPT_MUSIC")
	sfx_label.text = tr("OPT_SFX")
	_fill(music_bar, settings.music_volume)
	_fill(sfx_bar, settings.sfx_volume)
	language_button.text = tr("BTN_LANGUAGE")
	fullscreen_button.text = tr("OPT_FULLSCREEN_ON") if settings.fullscreen else tr("OPT_FULLSCREEN_OFF")
	var switches := dev_switches()
	for button: Button in switches:
		var keys: Array = DEV_SWITCHES[button.name]
		button.text = tr(keys[0]) if settings.get(button.name) else tr(keys[1])
	back_button.text = tr("BTN_BACK")
	_lay_out_dev(switches)


## Quem desenvolve vê a chave do modo dev; com ele ligado, vê também as outras três.
func dev_switches() -> Array:
	if not dev_available:
		return []
	if not settings.dev_mode:
		return [dev_button]
	return [dev_button, invincible_button, gold_button, record_button]


## O painel cresce para caber as chaves visíveis.
func _lay_out_dev(switches: Array) -> void:
	for button: Button in [dev_button, invincible_button, gold_button, record_button]:
		button.visible = button in switches
	var y := FIRST_DEV_ROW
	for button: Button in switches:
		button.position.y = y
		y += ROW_STEP
	back_button.position.y = y + 4
	_box.size.y = back_button.position.y + back_button.size.y + 10
	_box.position.y = floorf((SCREEN.y - _box.size.y) / 2.0)


func _dev_switch(box: Control, key: String) -> Button:
	var button := UiKit.button(box, Rect2(16, FIRST_DEV_ROW, 228, 22))
	button.name = key
	button.pressed.connect(func():
		settings.set(key, not settings.get(key))
		refresh()
		changed.emit())
	return button


func all_buttons() -> Array:
	return [music_down, music_up, sfx_down, sfx_up, language_button, fullscreen_button, dev_button, invincible_button, gold_button, record_button, back_button]


## Ícone, nome, menos, dez barrinhas e mais, todos na mesma linha.
func _volume_row(box: Control, y: float, icon_name: String, channel: String, bar: Array) -> Label:
	UiKit.texture_rect(box, UiKit.icon(icon_name), Rect2(Vector2(14, y + 1), Vector2(16, 16)))
	var name_label := UiKit.label(box, Rect2(32, y + 1, 70, 16))
	var down := UiKit.button(box, Rect2(104, y, 20, 18))
	down.name = "%s_down" % channel
	down.text = "-"
	for i in SEGMENTS:
		var segment := ColorRect.new()
		segment.position = Vector2(128 + i * SEGMENT_STEP, y + 4)
		segment.size = SEGMENT
		segment.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(segment)
		bar.append(segment)
	var up := UiKit.button(box, Rect2(220, y, 20, 18))
	up.name = "%s_up" % channel
	up.text = "+"
	down.pressed.connect(func(): _step(channel, -1))
	up.pressed.connect(func(): _step(channel, 1))
	return name_label


func _fill(bar: Array, volume: float) -> void:
	var lit := roundi(volume * SEGMENTS)
	for i in bar.size():
		bar[i].color = VOLUME_ON if i < lit else VOLUME_OFF


func _step(channel: String, direction: int) -> void:
	settings.step_volume(channel, direction)
	refresh()
	changed.emit()


func _toggle_fullscreen() -> void:
	settings.fullscreen = not settings.fullscreen
	refresh()
	changed.emit()
