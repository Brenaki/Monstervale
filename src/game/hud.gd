extends CanvasLayer
## Interface do jogo. Todo comando é um botão, porque o jogo usa só o mouse.

const UiKit = preload("res://src/game/ui_kit.gd")

signal class_pressed(kind: String)
signal next_wave_pressed
signal pause_pressed
signal speed_pressed
signal restart_pressed
signal options_pressed
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
signal main_menu_pressed

const TOP_HEIGHT := 24
const BOTTOM_TOP := 320
const SCREEN := Vector2(640, 360)
const ICON := Vector2(16, 16)
const CLASS_BAR_WIDTH := 320
const CARD_SIZE := Vector2(41, 36)
const CARD_STEP := 45
const CARD_ICON := 22
const BADGE_SIZE := Vector2(24, 14)
const DISABLED_ICON_ALPHA := 0.4
const BORDER_COLOR := Color("1b1626")
const PRICE_COLOR := Color("f6e05e")
const PREVIEW_ICON := 16
const ROW_HEIGHT := 16
const PAIR_GAP := 1
const ROW_GAP := 8
const STAR_WIDTH := 12
const RING_BUTTON := Vector2(20, 20)
const RING_DISTANCE := 28.0
const RING_LABEL_HEIGHT := 12
## O número fica 2 px fora do disco, em cima ou embaixo dele.
const RING_LABEL_ABOVE := -11.0
const RING_LABEL_BELOW := 19.0
## Direções do anel; cada botão tenta a sua primeiro e depois as outras, nesta ordem.
const RING_SLOTS := [
	Vector2(0, -1), Vector2(0, 1), Vector2(1, 0), Vector2(-1, 0),
	Vector2(0.7, -0.7), Vector2(-0.7, -0.7), Vector2(0.7, 0.7), Vector2(-0.7, 0.7),
]
const BOSS_LOST_COLOR := Color("8e2f36")
const MENU_BOX := Rect2(220, 80, 200, 176)
const BOSS_BAR := Rect2(272, 28, 216, 13)
const RESULT_BUTTON := Vector2(98, 26)
const RESULT_GAP := 5
const DEV_BADGE := Rect2(212, 4, 30, 16)
const DEV_COLOR := Color("d9534a")
const BOSS_LIFE_COLOR := Color("45b98c")
const WAVE_GLOW := Color(1.6, 1.6, 1.2)
const WAVE_PULSE_SPEED := 0.006
const TOAST := Rect2(200, 28, 240, 24)
const TOAST_TIME := 3.0
const TOAST_FADE := 0.4

var top_panel: Control
var gold_label: Label
var wave_label: Label
var level_label: Label
var preview_label: Label
var weak_label: Label
var weak_icons: Array = []
var pause_button: Button
var speed_button: Button
var restart_button: Button
var options_button: Button
var levels_button: Button
var menu_button: Button
var menu_panel: Control
var menu_title: Label
var menu_resume: Button
var main_menu_button: Button
var lives_label: Label
var boss_bar: Panel
var boss_fill: ColorRect
var boss_label: Label
var next_wave_button: Button
## O campo está vazio e a próxima onda espera o jogador.
var wave_waiting := false
var class_buttons := {}
var class_icons := {}
var class_prices := {}
var wave_box: Control
var unit_box: Control
var unit_portrait: TextureRect
var unit_label: Label
var unit_stars: Array = []
var unit_priority_label: Label
var unit_damage_label: Label
var unit_type_icon: TextureRect
var unit_type_label: Label
var unit_range_label: Label
var unit_cadence_label: Label
var unit_hp_label: Label
var ring: Control
var upgrade_button: Button
var upgrade_label: Label
var dismiss_button: Button
var dismiss_label: Label
var priority_button: Button
var close_button: Button
var result_panel: Panel
var result_title: Label
var result_stars: Label
var result_restart: Button
var log_button: Button
var dev_badge: Panel
var next_level_button: Button
var levels_panel: Control
var levels_title: Label
var level_buttons: Array = []
var levels_close: Button
## Textos das conquistas já anunciadas nesta sessão, na ordem.
var announced: Array = []
var toast: Panel
var toast_label: Label

var _root: Control
var _class_bar: Control
var _levels_box: Control
var _preview: Control
var _portraits := {}
var _monster_icons := {}
var _monster_frames: Callable
var _shown_preview := {}
var _toast_queue: Array = []


func _ready() -> void:
	_root = Control.new()
	_root.size = SCREEN
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = UiKit.theme()
	add_child(_root)
	_build_boss_bar()
	_build_ring()
	_build_top_bar()
	_build_bottom_bar()
	_build_result_panel()
	_build_menu_panel()
	_build_levels_panel()
	_build_toast()


## frames_for devolve as folhas de um humano; a carta mostra o rosto e a arma parada.
func set_classes(classes: Array, frames_for: Callable) -> void:
	for child in _class_bar.get_children():
		child.queue_free()
	class_buttons.clear()
	class_icons.clear()
	class_prices.clear()
	var x := 4
	for kind: String in classes:
		var button := _button(_class_bar, Rect2(Vector2(x, 2), CARD_SIZE))
		button.toggle_mode = true
		button.pressed.connect(func(): class_pressed.emit(kind))
		_portraits[kind] = UiKit.frame_icon(frames_for.call(kind), "idle", CARD_ICON)
		var icon := _texture(button, _portraits[kind], Rect2(Vector2((CARD_SIZE.x - CARD_ICON) / 2.0, 1), Vector2(CARD_ICON, CARD_ICON)))
		var badge_rect := Rect2(Vector2((CARD_SIZE.x - BADGE_SIZE.x) / 2.0, CARD_SIZE.y - BADGE_SIZE.y - 1), BADGE_SIZE)
		_texture(button, UiKit.texture("badge"), badge_rect)
		var price := _label(button, Rect2(badge_rect.position + Vector2(1, 1), Vector2(BADGE_SIZE.x, 12)))
		price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		price.add_theme_color_override("font_color", PRICE_COLOR)
		class_buttons[kind] = button
		class_icons[kind] = icon
		class_prices[kind] = price
		x += CARD_STEP


## Folhas dos monstros, para os ícones da prévia da próxima onda.
func set_monster_frames(frames_for: Callable) -> void:
	_monster_frames = frames_for
	_monster_icons.clear()


func set_levels(count: int) -> void:
	for i in count:
		var button := _button(_levels_box, Rect2(12, 28 + i * 24, 216, 20))
		button.pressed.connect(func(): level_pressed.emit(i))
		level_buttons.append(button)
	levels_close = _button(_levels_box, Rect2(70, 34 + count * 24, 100, 20))
	levels_close.pressed.connect(func(): levels_pressed.emit())
	_levels_box.size.y = 62 + count * 24
	_levels_box.position.y = (SCREEN.y - _levels_box.size.y) / 2.0


func refresh(game) -> void:
	var sim = game.sim
	gold_label.text = str(sim.gold)
	wave_label.text = tr("HUD_WAVE") % [sim.waves_started(), sim.waves_total()]
	level_label.text = tr("BTN_LEVELS") % (game.level_index + 1)
	lives_label.text = tr("HUD_LIVES") % [sim.lives, sim.start_lives()]
	_refresh_boss(sim.boss())
	_refresh_corner_buttons(game)
	_refresh_menus(game)
	_refresh_classes(game)
	wave_box.visible = game.selected_unit == null
	unit_box.visible = game.selected_unit != null
	ring.visible = game.selected_unit != null and sim.state == "playing"
	if game.selected_unit != null:
		_refresh_unit(sim, game.selected_unit)
	else:
		_refresh_wave(sim)


## campaign_done troca o título na vitória da última fase.
func show_result(won: bool, stars: int, can_advance := false, campaign_done := false) -> void:
	result_title.text = tr("RESULT_LOST")
	if won:
		result_title.text = tr("RESULT_CAMPAIGN") if campaign_done else tr("RESULT_WON")
	result_stars.text = tr("RESULT_STARS") % stars if won else ""
	next_level_button.visible = can_advance
	_center_result_buttons()
	result_panel.visible = true


## O relatório da partida é só para quem desenvolve.
func set_report_available(available: bool) -> void:
	log_button.visible = available


func _center_result_buttons() -> void:
	var shown := [result_restart, log_button, next_level_button].filter(func(b): return b.visible)
	var width: float = RESULT_BUTTON.x * shown.size() + RESULT_GAP * (shown.size() - 1)
	var x := (result_panel.size.x - width) / 2.0
	for button: Button in shown:
		button.position.x = x
		x += RESULT_BUTTON.x + RESULT_GAP


func hide_result() -> void:
	result_panel.visible = false


func all_buttons() -> Array:
	var buttons := [
		pause_button, speed_button, restart_button, options_button, levels_button, next_wave_button,
		upgrade_button, dismiss_button, priority_button, close_button, result_restart, log_button,
		next_level_button, menu_button, menu_resume, main_menu_button, levels_close,
	]
	buttons.append_array(class_buttons.values())
	buttons.append_array(level_buttons)
	return buttons


func _refresh_corner_buttons(game) -> void:
	pause_button.icon = UiKit.icon("play" if game.paused else "pause")
	pause_button.tooltip_text = tr("BTN_RESUME") if game.paused else tr("BTN_PAUSE")
	speed_button.set_pressed_no_signal(game.speed > 1)
	speed_button.tooltip_text = tr("BTN_SPEED") % game.speed
	menu_button.tooltip_text = tr("BTN_MENU")


func _refresh_menus(game) -> void:
	menu_title.text = tr("MENU_TITLE")
	menu_resume.text = tr("BTN_RESUME")
	levels_button.text = tr("BTN_CHOOSE_LEVEL")
	restart_button.text = tr("BTN_RESTART")
	options_button.text = tr("BTN_OPTIONS")
	main_menu_button.text = tr("BTN_MAIN_MENU")
	result_restart.text = tr("BTN_RESTART")
	log_button.text = tr("BTN_OPEN_LOG")
	next_level_button.text = tr("BTN_NEXT_LEVEL")
	levels_title.text = tr("LEVELS_TITLE")
	levels_close.text = tr("BTN_CLOSE")
	for i in level_buttons.size():
		var unlocked: bool = game.progress.is_unlocked(i)
		level_buttons[i].disabled = not unlocked
		level_buttons[i].text = tr("LEVEL_ENTRY") % [i + 1, game.progress.stars_for(i)] if unlocked else tr("LEVEL_LOCKED") % (i + 1)


func _refresh_classes(game) -> void:
	var sim = game.sim
	for kind: String in class_buttons:
		var button: Button = class_buttons[kind]
		var cost: int = sim.unit_cost(kind)
		class_prices[kind].text = str(cost)
		button.tooltip_text = tr("UNIT_TOOLTIP") % [tr("UNIT_%s" % kind.to_upper()), tr("DAMAGE_%s" % sim.unit_damage_type(kind).to_upper())]
		button.disabled = sim.gold < cost and game.selected_class != kind
		button.set_pressed_no_signal(game.selected_class == kind)
		var alpha := DISABLED_ICON_ALPHA if button.disabled else 1.0
		class_icons[kind].modulate.a = alpha
		class_prices[kind].modulate.a = alpha


func _refresh_boss(boss) -> void:
	boss_bar.visible = boss != null
	if boss == null:
		return
	boss_label.text = tr("MONSTER_%s" % boss.kind.to_upper())
	boss_fill.size.x = BOSS_BAR.size.x * maxf(0.0, float(boss.hp) / boss.max_hp)


func _refresh_wave(sim) -> void:
	var preview: Dictionary = sim.next_wave_preview()
	preview_label.text = tr("HUD_NEXT") if not preview.is_empty() else ""
	if preview != _shown_preview:
		_show_preview(preview)
	var weak: Array = sim.next_wave_weaknesses()
	weak_label.text = tr("HUD_WEAK_SHORT") if not weak.is_empty() else ""
	for i in weak_icons.size():
		weak_icons[i].visible = i < weak.size()
		if i < weak.size():
			weak_icons[i].texture = UiKit.icon(weak[i])
			weak_icons[i].tooltip_text = tr("WEAK_%s" % weak[i].to_upper())
	var can_call: bool = sim.can_call_next_wave()
	var bonus: int = sim.early_call_bonus() if can_call else 0
	wave_waiting = can_call and sim.monsters.is_empty()
	next_wave_button.disabled = not can_call
	next_wave_button.text = tr("HUD_BONUS") % bonus if bonus > 0 else ""
	next_wave_button.alignment = HORIZONTAL_ALIGNMENT_LEFT if bonus > 0 else HORIZONTAL_ALIGNMENT_CENTER
	if not can_call:
		next_wave_button.tooltip_text = tr("BTN_NO_WAVE")
	elif bonus > 0:
		next_wave_button.tooltip_text = tr("BTN_NEXT_WAVE") % bonus
	else:
		next_wave_button.tooltip_text = tr("BTN_START_WAVE")
	# Com o campo vazio nada acontece até o jogador chamar, então o botão pisca.
	var glow := (sin(Time.get_ticks_msec() * WAVE_PULSE_SPEED) + 1.0) / 2.0 if wave_waiting else 0.0
	next_wave_button.modulate = Color.WHITE.lerp(WAVE_GLOW, glow)


func _show_preview(preview: Dictionary) -> void:
	_shown_preview = preview
	for child in _preview.get_children():
		child.queue_free()
	for kind: String in preview:
		var pair := _row(_preview, Vector2.ZERO, PAIR_GAP)
		var icon := _texture(pair, _monster_icon(kind), Rect2(Vector2.ZERO, ICON))
		icon.custom_minimum_size = ICON
		icon.tooltip_text = tr("MONSTER_%s" % kind.to_upper())
		icon.mouse_filter = Control.MOUSE_FILTER_PASS
		_row_label(pair).text = "x%d" % preview[kind]


func _monster_icon(kind: String) -> Texture2D:
	if not _monster_icons.has(kind):
		_monster_icons[kind] = UiKit.frame_icon(_monster_frames.call(kind), "walk", PREVIEW_ICON)
	return _monster_icons[kind]


func _refresh_unit(sim, unit) -> void:
	var stats: Dictionary = unit.stats()
	unit_portrait.texture = _portraits.get(unit.kind)
	var name_text := tr("UNIT_%s" % unit.kind.to_upper())
	unit_label.text = "%s (%s)" % [name_text, tr("UNIT_DOWN")] if unit.is_down() else name_text
	for i in unit_stars.size():
		unit_stars[i].texture = UiKit.icon("star" if i < unit.level else "star_empty")
	unit_priority_label.text = tr("PRIORITY_%s" % unit.priority.to_upper())
	unit_damage_label.text = _number(stats.damage)
	unit_type_icon.texture = UiKit.icon(unit.damage_type())
	unit_type_label.text = tr("WEAK_%s" % unit.damage_type().to_upper())
	unit_range_label.text = _number(stats.range)
	unit_cadence_label.text = tr("HUD_SECONDS") % _number(stats.cooldown)
	unit_hp_label.text = _number(stats.hp)

	upgrade_button.disabled = not unit.can_upgrade() or sim.gold < unit.upgrade_cost()
	upgrade_label.text = str(unit.upgrade_cost()) if unit.can_upgrade() else tr("HUD_MAX")
	upgrade_button.tooltip_text = tr("BTN_UPGRADE") % unit.upgrade_cost() if unit.can_upgrade() else tr("BTN_MAX_LEVEL")
	dismiss_label.text = "+%d" % unit.refund()
	dismiss_button.tooltip_text = tr("BTN_DISMISS") % unit.refund()
	priority_button.tooltip_text = tr("PRIORITY_LABEL") % tr("PRIORITY_%s" % unit.priority.to_upper())
	close_button.tooltip_text = tr("BTN_CLOSE")
	_place_ring(unit.position)


## Inteiro quando não tem fração; senão uma casa decimal, com vírgula em português.
func _number(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(roundi(value))
	var text := "%.1f" % value
	return text.replace(".", ",") if TranslationServer.get_locale().begins_with("pt") else text


## Cada botão fica na sua direção em volta do humano; perto da borda, usa a próxima livre.
func _place_ring(center: Vector2) -> void:
	var area := Rect2(0, TOP_HEIGHT, SCREEN.x, BOTTOM_TOP - TOP_HEIGHT)
	var taken := []
	var wanted := [[upgrade_button, Vector2(0, -1)], [dismiss_button, Vector2(0, 1)], [priority_button, Vector2(1, 0)]]
	for item: Array in wanted:
		var button: Button = item[0]
		var slots := [item[1]]
		slots.append_array(RING_SLOTS.filter(func(s): return s != item[1]))
		for slot: Vector2 in slots:
			var at: Vector2 = center + slot * RING_DISTANCE - RING_BUTTON / 2.0
			var footprint := Rect2(at, RING_BUTTON + Vector2(0, RING_LABEL_HEIGHT)).grow_individual(2, 0, 2, 0)
			if slot.y < 0:
				footprint.position.y -= RING_LABEL_HEIGHT
			if slot in taken or not area.encloses(footprint):
				continue
			button.position = at
			_put_ring_label(button, slot)
			taken.append(slot)
			break


## O preço fica do lado de fora do anel, para não cobrir o humano.
func _put_ring_label(button: Button, slot: Vector2) -> void:
	for label in button.get_children():
		if label is Label:
			label.position.y = RING_LABEL_ABOVE if slot.y < 0 else RING_LABEL_BELOW


## Vidas, ouro, onda e fase.
func _build_top_bar() -> void:
	var stats := _panel(_root, Rect2(2, 1, 206, 22))
	top_panel = stats
	var row := _row(stats, Vector2(5, 3), ROW_GAP)
	lives_label = _pair(row, "heart", "TIP_LIVES")
	gold_label = _pair(row, "coin", "TIP_GOLD")
	wave_label = _pair(row, "skull", "TIP_WAVE")
	level_label = _row_label(row)
	speed_button = _button(_root, Rect2(562, 1, 24, 22))
	pause_button = _button(_root, Rect2(588, 1, 24, 22))
	menu_button = _button(_root, Rect2(614, 1, 24, 22))
	menu_button.icon = UiKit.icon("menu")
	_build_dev_badge()
	speed_button.icon = UiKit.icon("fast")
	speed_button.toggle_mode = true
	for button: Button in [speed_button, pause_button, menu_button]:
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_button.pressed.connect(func(): pause_pressed.emit())
	speed_button.pressed.connect(func(): speed_pressed.emit())
	menu_button.pressed.connect(func(): menu_pressed.emit())


## Selo vermelho ao lado do painel do alto enquanto o modo dev está ligado.
func _build_dev_badge() -> void:
	dev_badge = Panel.new()
	dev_badge.position = DEV_BADGE.position
	dev_badge.size = DEV_BADGE.size
	dev_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = DEV_COLOR
	style.border_color = BORDER_COLOR
	style.set_border_width_all(1)
	dev_badge.add_theme_stylebox_override("panel", style)
	dev_badge.visible = false
	_root.add_child(dev_badge)
	var text := _label(dev_badge, Rect2(Vector2.ZERO, DEV_BADGE.size))
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.text = "DEV"


func _build_bottom_bar() -> void:
	var bar := _panel(_root, Rect2(0, BOTTOM_TOP, SCREEN.x, SCREEN.y - BOTTOM_TOP))
	_class_bar = Control.new()
	_class_bar.size = Vector2(CLASS_BAR_WIDTH, 40)
	_class_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(_class_bar)
	_build_wave_box(bar)
	_build_unit_box(bar)


func _build_wave_box(bar: Control) -> void:
	wave_box = _box(bar)
	var next_row := _row(wave_box, Vector2(0, 3), ROW_GAP)
	preview_label = _row_label(next_row)
	_preview = _row(next_row, Vector2.ZERO, ROW_GAP)
	var weak_row := _row(wave_box, Vector2(0, 21), 2)
	weak_label = _row_label(weak_row)
	for i in 3:
		var icon := _texture(weak_row, null, Rect2(Vector2.ZERO, ICON))
		icon.custom_minimum_size = ICON
		icon.mouse_filter = Control.MOUSE_FILTER_PASS
		weak_icons.append(icon)
	next_wave_button = _button(wave_box, Rect2(270, 3, 44, 34), "green")
	next_wave_button.icon = UiKit.icon("play")
	next_wave_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	next_wave_button.add_theme_constant_override("h_separation", 2)
	next_wave_button.pressed.connect(func(): next_wave_pressed.emit())


## Ficha do humano selecionado: retrato, nome, nível e alvo em cima, atributos embaixo.
func _build_unit_box(bar: Control) -> void:
	unit_box = _box(bar)
	unit_box.visible = false
	var frame := _panel(unit_box, Rect2(0, 3, 34, 34))
	unit_portrait = _texture(frame, null, Rect2(Vector2(6, 6), Vector2(CARD_ICON, CARD_ICON)))
	var top := _row(unit_box, Vector2(40, 3), ROW_GAP)
	unit_label = _row_label(top)
	var stars := _row(top, Vector2.ZERO, 0)
	for i in 3:
		var star := _texture(stars, null, Rect2(Vector2.ZERO, ICON))
		star.custom_minimum_size = Vector2(STAR_WIDTH, ICON.y)
		unit_stars.append(star)
	unit_priority_label = _pair(top, "target", "STAT_PRIORITY")
	close_button = _button(unit_box, Rect2(290, 2, 24, 18))
	close_button.icon = UiKit.icon("close")
	close_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	close_button.pressed.connect(func(): close_pressed.emit())
	var stats := _row(unit_box, Vector2(40, 21), ROW_GAP)
	unit_damage_label = _pair(stats, "sword", "STAT_DAMAGE")
	unit_type_label = _pair(stats, "pierce", "")
	unit_type_icon = unit_type_label.get_parent().get_child(0)
	unit_range_label = _pair(stats, "range", "STAT_RANGE")
	unit_cadence_label = _pair(stats, "cadence", "STAT_COOLDOWN")
	unit_hp_label = _pair(stats, "heart", "STAT_HP")


## Linha que centraliza ícones e textos na altura e os espaça pela largura real do texto.
func _row(parent: Control, at: Vector2, separation: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.position = at
	row.custom_minimum_size = Vector2(0, ROW_HEIGHT)
	row.add_theme_constant_override("separation", separation)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(row)
	return row


func _row_label(row: HBoxContainer) -> Label:
	var label := _label(row, Rect2())
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return label


## Ícone com o número logo ao lado; o ícone explica o número quando o mouse passa por cima.
func _pair(row: HBoxContainer, icon_name: String, tooltip_key: String) -> Label:
	var pair := _row(row, Vector2.ZERO, PAIR_GAP)
	var icon := _texture(pair, UiKit.icon(icon_name), Rect2(Vector2.ZERO, ICON))
	icon.custom_minimum_size = ICON
	if tooltip_key != "":
		icon.mouse_filter = Control.MOUSE_FILTER_PASS
		icon.tooltip_text = tooltip_key
		icon.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_ALWAYS
	return _row_label(pair)


## Botões redondos em volta do humano selecionado; o resto do anel deixa o clique passar.
func _build_ring() -> void:
	ring = Control.new()
	ring.size = SCREEN
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.visible = false
	_root.add_child(ring)
	upgrade_button = _ring_button("upgrade")
	upgrade_label = _ring_label(upgrade_button)
	dismiss_button = _ring_button("coin")
	dismiss_label = _ring_label(dismiss_button)
	priority_button = _ring_button("target")
	upgrade_button.pressed.connect(func(): upgrade_pressed.emit())
	dismiss_button.pressed.connect(func(): dismiss_pressed.emit())
	priority_button.pressed.connect(func(): priority_pressed.emit())


func _ring_button(icon_name: String) -> Button:
	var button := _button(ring, Rect2(Vector2.ZERO, RING_BUTTON))
	for state: String in ["normal", "hover", "pressed", "disabled"]:
		var style := StyleBoxTexture.new()
		style.texture = UiKit.texture("ring_%s" % state)
		style.set_content_margin_all(2)
		button.add_theme_stylebox_override(state, style)
	button.icon = UiKit.icon(icon_name)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return button


func _ring_label(button: Button) -> Label:
	var label := _label(button, Rect2(-6, RING_LABEL_BELOW, RING_BUTTON.x + 12, RING_LABEL_HEIGHT))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", PRICE_COLOR)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _build_result_panel() -> void:
	result_panel = _panel(_root, Rect2(160, 120, 320, 110))
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
## Vem depois do menu, porque abre por cima dele.
func _build_levels_panel() -> void:
	levels_panel = _backdrop()
	_levels_box = _panel(levels_panel, Rect2(200, 100, 240, 120))
	levels_title = _label(_levels_box, Rect2(0, 6, 240, 18))
	levels_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


## Cobre a tela para o jogo não receber cliques enquanto estiver pausado no menu.
func _build_menu_panel() -> void:
	menu_panel = _backdrop()
	var box := _panel(menu_panel, MENU_BOX)
	menu_title = _label(box, Rect2(0, 6, MENU_BOX.size.x, 18))
	menu_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_resume = _button(box, Rect2(12, 28, 176, 24))
	levels_button = _button(box, Rect2(12, 56, 176, 24))
	restart_button = _button(box, Rect2(12, 84, 176, 24))
	options_button = _button(box, Rect2(12, 112, 176, 24))
	main_menu_button = _button(box, Rect2(12, 140, 176, 24))
	menu_resume.pressed.connect(func(): resume_pressed.emit())
	levels_button.pressed.connect(func(): levels_pressed.emit())
	restart_button.pressed.connect(func(): restart_pressed.emit())
	options_button.pressed.connect(func(): options_pressed.emit())
	main_menu_button.pressed.connect(func(): main_menu_pressed.emit())


## Barra larga no alto do mapa, enquanto o chefe está em campo.
func _build_boss_bar() -> void:
	boss_bar = _bar(BOSS_BAR)
	boss_bar.visible = false
	boss_fill = _fill(boss_bar, BOSS_LIFE_COLOR)
	boss_label = _label(boss_bar, Rect2(Vector2.ZERO, BOSS_BAR.size))
	boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_label.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _bar(rect: Rect2) -> Panel:
	var bar := Panel.new()
	bar.position = rect.position
	bar.size = rect.size
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = BOSS_LOST_COLOR
	style.border_color = BORDER_COLOR
	style.set_border_width_all(1)
	bar.add_theme_stylebox_override("panel", style)
	_root.add_child(bar)
	return bar


func _fill(bar: Panel, color: Color) -> ColorRect:
	var fill := ColorRect.new()
	fill.color = color
	fill.size = bar.size
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(fill)
	return fill


func _box(bar: Control) -> Control:
	var box := Control.new()
	box.position = Vector2(324, 0)
	box.size = Vector2(316, 40)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(box)
	return box


func _backdrop() -> Panel:
	return UiKit.backdrop(_root, SCREEN)


## Conquista nova: um aviso no alto da tela; várias de uma vez aparecem uma depois da outra.
func show_achievement(text: String) -> void:
	announced.append(text)
	_toast_queue.append(text)
	if _toast_queue.size() == 1:
		_show_next_toast()


func _build_toast() -> void:
	toast = _panel(_root, TOAST)
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := _row(toast, Vector2(6, 4), PAIR_GAP + 3)
	var icon := _texture(row, UiKit.icon("trophy"), Rect2(Vector2.ZERO, ICON))
	icon.custom_minimum_size = ICON
	toast_label = _row_label(row)
	toast.visible = false


func _show_next_toast() -> void:
	toast_label.text = tr("ACH_UNLOCKED") % _toast_queue[0]
	toast.modulate.a = 1.0
	toast.visible = true
	var tween := create_tween()
	tween.tween_interval(TOAST_TIME)
	tween.tween_property(toast, "modulate:a", 0.0, TOAST_FADE)
	tween.tween_callback(func():
		toast.visible = false
		_toast_queue.pop_front()
		if not _toast_queue.is_empty():
			_show_next_toast())


func _panel(parent: Control, rect: Rect2) -> Panel:
	return UiKit.panel(parent, rect)


func _texture(parent: Control, texture: Texture2D, rect: Rect2) -> TextureRect:
	return UiKit.texture_rect(parent, texture, rect)


func _label(parent: Control, rect: Rect2) -> Label:
	return UiKit.label(parent, rect)


func _button(parent: Control, rect: Rect2, kind := "button") -> Button:
	return UiKit.button(parent, rect, kind)
