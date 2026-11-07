extends RefCounted
## Joga como a pessoa jogou, clicando nos botões reais a partir de um relatório de partida.
## O ritmo é relativo às ondas: cada compra acontece no mesmo momento da onda e cada onda é
## chamada depois da mesma pausa. Sem ouro, espera, e se o botão não responde, anota a falha.

const CLOCK_MARGIN := 0.000001
const MOUSE_MOVES_BEFORE_CLICK := 2
const REINVEST_FROM_WAVE := 4
const REINVEST_ABOVE_GOLD := 100
const REINVEST_ORDER := ["mage", "spearman", "warrior", "druid", "archer"]

var game
var failed_clicks: Array = []
## Com células aqui, além de repetir a partida, gasta o ouro que sobra: melhora quem já está
## em campo e depois compra magos nessas células, como quem reage à dificuldade.
var reinvest_cells: Array = []

var _report: Dictionary
var _actions: Array
var _started: Dictionary = {}


func _init(the_game, report: Dictionary) -> void:
	game = the_game
	_report = report
	_actions = report.actions.duplicate()


func open_level() -> void:
	var index: int = game.LEVEL_IDS.find(_report.level)
	if game.level_index == index:
		return
	click(game.hud.menu_button)
	click(game.hud.levels_button)
	click(game.hud.level_buttons[index])


func is_done() -> bool:
	var sim = game.sim
	if sim.state != "playing":
		return true
	return _report.result not in ["won", "lost"] and sim.elapsed >= _report.duration


## Um passo da pessoa e um passo do jogo, como em um quadro a 60 por segundo.
func step() -> void:
	var sim = game.sim
	_note_wave_starts()
	while not _actions.is_empty() and sim.elapsed >= _action_time(_actions[0]) and _perform(_actions[0]):
		_actions.pop_front()
	_reinvest()
	_call_wave_if_due()
	game._process(game.STEP)


func pending_actions() -> int:
	return _actions.size()


func _reinvest() -> void:
	var sim = game.sim
	if reinvest_cells.is_empty() or sim.gold < REINVEST_ABOVE_GOLD or sim.waves_started() < REINVEST_FROM_WAVE:
		return
	for kind: String in REINVEST_ORDER:
		for unit in sim.units:
			if unit.kind == kind and _upgrade(unit.cell):
				return
	for cell: Vector2i in reinvest_cells:
		if sim.can_place("mage", cell) and _place("mage", cell):
			return


func _note_wave_starts() -> void:
	var sim = game.sim
	if sim.waves_started() > 0 and not _started.has(sim.waves_started()):
		_started[sim.waves_started()] = sim.elapsed


func _recorded_wave(number: int) -> Dictionary:
	return _report.waves[number - 1] if number <= _report.waves.size() else {}


func _action_time(action: Dictionary) -> float:
	var wave := int(action.wave)
	if wave == 0:
		return action.time - CLOCK_MARGIN
	if not _started.has(wave):
		return INF
	return _started[wave] + action.time - _recorded_wave(wave).started_at - CLOCK_MARGIN


func _call_wave_if_due() -> void:
	var sim = game.sim
	var number: int = sim.waves_started() + 1
	var recorded := _recorded_wave(number)
	# Nas partidas de antes das ondas manuais, a onda não chamada começava sozinha quando a espera
	# acabava; depois do fim da gravação, o jogo segue no mesmo ritmo.
	var by_timer: bool = recorded.is_empty() or not recorded.called_early
	var due: bool = sim.next_wave_countdown - game.STEP <= 0.0 if by_timer else sim.elapsed >= _call_time(number, recorded)
	if not due:
		return
	if game.selected_unit == null and sim.can_call_next_wave():
		click(game.hud.next_wave_button)


## Chamou com o campo limpo: repete a pausa depois da limpeza. Chamou com monstros em campo:
## repete o tempo desde o início da onda anterior.
func _call_time(number: int, recorded: Dictionary) -> float:
	if number == 1:
		return recorded.started_at - CLOCK_MARGIN
	var before := _recorded_wave(number - 1)
	if before.cleared_at == null or before.cleared_at > recorded.started_at:
		return _started[number - 1] + recorded.started_at - before.started_at - CLOCK_MARGIN
	var cleared = game._match_log.to_dict().waves[number - 2].cleared_at
	if cleared == null:
		return INF
	return cleared + recorded.started_at - before.cleared_at - CLOCK_MARGIN


func _perform(action: Dictionary) -> bool:
	var cell := Vector2i(int(action.cell[0]), int(action.cell[1]))
	match action.action:
		"place":
			return _place(action.unit, cell)
		"upgrade":
			return _upgrade(cell)
		"dismiss":
			return _dismiss(cell)
	return false


func _place(kind: String, cell: Vector2i) -> bool:
	var sim = game.sim
	if sim.gold < sim.unit_cost(kind) or sim.unit_at(cell) != null:
		return false
	game._process(0.0)
	click(game.hud.class_buttons[kind])
	_click_cell(cell)
	if sim.unit_at(cell) == null:
		failed_clicks.append("posicionar %s em %s" % [kind, cell])
		game.clear_selection()
	return true


func _upgrade(cell: Vector2i) -> bool:
	var sim = game.sim
	var unit = sim.unit_at(cell)
	if unit == null or not unit.can_upgrade() or sim.gold < unit.upgrade_cost():
		return false
	var level_before: int = unit.level
	_select(cell)
	click(game.hud.upgrade_button)
	if unit.level == level_before:
		failed_clicks.append("melhorar %s" % cell)
	click(game.hud.close_button)
	return true


func _dismiss(cell: Vector2i) -> bool:
	var unit = game.sim.unit_at(cell)
	if unit == null:
		return false
	_select(cell)
	click(game.hud.dismiss_button)
	if game.sim.unit_at(cell) != null:
		failed_clicks.append("dispensar %s" % cell)
		click(game.hud.close_button)
	return true


func _select(cell: Vector2i) -> void:
	_click_cell(cell)
	game._process(0.0)


func click(button: Button) -> void:
	game._process(0.0)
	_mouse_click(button.get_global_rect().get_center())
	game._process(0.0)


func _click_cell(cell: Vector2i) -> void:
	_mouse_click(game.sim.cell_center(cell))


func _mouse_click(at: Vector2) -> void:
	var viewport: Viewport = game.get_viewport()
	# O controle sob o cursor só é reconhecido no movimento seguinte, como em um mouse real.
	for moves in MOUSE_MOVES_BEFORE_CLICK:
		var motion := InputEventMouseMotion.new()
		motion.position = at
		viewport.push_input(motion, true)
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = at
		event.pressed = pressed
		viewport.push_input(event, true)
