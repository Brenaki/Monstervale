extends Node2D
## Mostra a célula sob o mouse e o alcance do humano escolhido ou selecionado.

const VALID := Color(0.5, 1.0, 0.5, 0.35)
const INVALID := Color(1.0, 0.3, 0.3, 0.35)
const RANGE_LINE := Color(1.0, 1.0, 1.0, 0.7)
const RANGE_FILL := Color(1.0, 1.0, 1.0, 0.08)
const CIRCLE_POINTS := 64

var game


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if game == null or game.sim == null:
		return
	if game.selected_unit != null:
		_draw_range(game.selected_unit.position, float(game.selected_unit.stats().range))
	if game.selected_class != "" and game.hover_cell.y >= 1 and game.hover_cell.y <= 9:
		var cell: Vector2i = game.hover_cell
		var size := float(game.level.cell_size)
		var color := VALID if game.sim.can_place(game.selected_class, cell) else INVALID
		draw_rect(Rect2(Vector2(cell) * size, Vector2(size, size)), color)
		_draw_range(game.sim.cell_center(cell), float(game.catalog.units[game.selected_class].levels[0].range))


func _draw_range(center: Vector2, radius: float) -> void:
	draw_circle(center, radius, RANGE_FILL)
	draw_arc(center, radius, 0.0, TAU, CIRCLE_POINTS, RANGE_LINE, 1.0)
