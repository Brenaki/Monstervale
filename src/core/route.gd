extends RefCounted
## Caminho dos monstros: uma linha de pontos percorrida por distância.

var length: float = 0.0

var _points: Array[Vector2] = []
var _starts: Array[float] = []


func _init(points: Array) -> void:
	for point: Vector2 in points:
		_points.append(point)
	for i in range(_points.size() - 1):
		_starts.append(length)
		length += _points[i].distance_to(_points[i + 1])


func position_at(distance: float) -> Vector2:
	if _starts.is_empty():
		return _points[0] if not _points.is_empty() else Vector2.ZERO
	var segment := _segment_at(distance)
	var segment_length := _points[segment].distance_to(_points[segment + 1])
	var along: float = clampf(distance - _starts[segment], 0.0, segment_length)
	return _points[segment].move_toward(_points[segment + 1], along)


## Retorna 1 ou -1 em trechos que andam na horizontal e 0 em trechos verticais.
func horizontal_direction_at(distance: float) -> int:
	if _starts.is_empty():
		return 0
	var segment := _segment_at(distance)
	return signi(int(signf(_points[segment + 1].x - _points[segment].x)))


func _segment_at(distance: float) -> int:
	for i in range(_starts.size() - 1, -1, -1):
		if distance >= _starts[i]:
			return i
	return 0
