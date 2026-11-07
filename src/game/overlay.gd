extends Node2D
## Mostra a célula sob o mouse e o alcance do humano escolhido ou selecionado.

const VALID := Color(0.5, 1.0, 0.5, 0.35)
const INVALID := Color(1.0, 0.3, 0.3, 0.35)
const RANGE_LINE := Color(1.0, 1.0, 1.0, 0.7)
const RANGE_FILL := Color(1.0, 1.0, 1.0, 0.08)
const CIRCLE_POINTS := 64
const FIRE_GROUND := Color(0.85, 0.3, 0.2, 0.3)
const FIRE_COLORS := [Color("f6e05e"), Color("e8913a"), Color("d9534a")]
const FLAMES := 9
const FLAME_SPEED := 12.0
const ROOT_COLORS := [Color("4f9d4a"), Color("6b4228")]
const ROOT_SIZE := 9
const STUN_COLOR := Color("f6e05e")
const STUN_STARS := 3
const STUN_RADIUS := 7.0
const STUN_HEIGHT := 26.0
const STUN_SPIN := 6.0
const ENTRY_COLOR := Color("f6e05e")
const ENTRY_DISTANCE := 34.0
const ENTRY_PULSE_SPEED := 5.0

var game


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if game == null or game.sim == null:
		return
	for fire: Dictionary in game.sim.fires:
		_draw_fire(fire)
	_draw_next_entries()
	for monster in game.sim.monsters:
		if monster.is_rooted():
			_draw_roots(monster.position())
		if monster.is_stunned():
			_draw_stun(monster.position())
	if game.selected_unit != null:
		_draw_range(game.selected_unit.position, float(game.selected_unit.stats().range))
	if game.selected_class != "" and game.hover_cell.y >= 1 and game.hover_cell.y <= 9:
		var cell: Vector2i = game.hover_cell
		var size := float(game.level.cell_size)
		var color := VALID if game.sim.can_place(game.selected_class, cell) else INVALID
		draw_rect(Rect2(Vector2(cell) * size, Vector2(size, size)), color)
		_draw_range(game.sim.cell_center(cell), float(game.catalog.units[game.selected_class].levels[0].range))


## Chamas de pixels que tremem sobre uma mancha no chão, abaixo dos personagens.
func _draw_fire(fire: Dictionary) -> void:
	draw_set_transform(fire.position, 0.0, Vector2(1.0, 0.5))
	draw_circle(Vector2.ZERO, fire.radius, FIRE_GROUND)
	draw_set_transform(Vector2.ZERO)
	var time := Time.get_ticks_msec() / 1000.0
	for i in FLAMES:
		var angle := TAU * i / FLAMES
		var reach: float = fire.radius * (0.3 + 0.6 * ((i * 37) % 10) / 10.0)
		var base: Vector2 = fire.position + Vector2(cos(angle) * reach, sin(angle) * reach * 0.5)
		var height := roundf(3.0 + 2.0 * sin(time * FLAME_SPEED + i * 1.7))
		draw_rect(Rect2(base - Vector2(1, height), Vector2(2, height)), FIRE_COLORS[i % FIRE_COLORS.size()])


## Em fases com mais de uma entrada, setas mostram por onde vem a próxima onda.
func _draw_next_entries() -> void:
	if game.sim.routes.size() < 2:
		return
	var pulse := 0.6 + 0.4 * sin(Time.get_ticks_msec() / 1000.0 * ENTRY_PULSE_SPEED)
	var color := Color(ENTRY_COLOR, pulse)
	for index: int in game.sim.next_wave_routes():
		var route = game.sim.routes[index]
		var tip: Vector2 = route.position_at(ENTRY_DISTANCE)
		var back: Vector2 = route.position_at(0.0).direction_to(tip) * -10.0
		var side := back.orthogonal() * 0.8
		draw_colored_polygon(PackedVector2Array([tip, tip + back + side, tip + back - side]), color)


## Raízes que sobem do chão em volta dos pés do monstro preso.
func _draw_roots(feet: Vector2) -> void:
	for i in ROOT_SIZE:
		var x := float(i * 2 - ROOT_SIZE)
		var height := 2.0 + (i * 5) % 4
		draw_rect(Rect2(feet + Vector2(x, 8.0 - height), Vector2(2, height)), ROOT_COLORS[i % ROOT_COLORS.size()])


## Estrelas de pixels girando sobre a cabeça do monstro atordoado.
func _draw_stun(feet: Vector2) -> void:
	var time := Time.get_ticks_msec() / 1000.0
	for i in STUN_STARS:
		var angle := time * STUN_SPIN + TAU * i / STUN_STARS
		var star := feet + Vector2(cos(angle) * STUN_RADIUS, sin(angle) * STUN_RADIUS * 0.4 - STUN_HEIGHT)
		draw_rect(Rect2(star, Vector2(2, 2)), STUN_COLOR)


func _draw_range(center: Vector2, radius: float) -> void:
	draw_circle(center, radius, RANGE_FILL)
	draw_arc(center, radius, 0.0, TAU, CIRCLE_POINTS, RANGE_LINE, 1.0)
