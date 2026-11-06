extends GutTest

const Route = preload("res://src/core/route.gd")

func _route() -> Route:
	return Route.new([Vector2(0, 0), Vector2(100, 0), Vector2(100, 50)])

func test_length_sums_all_segments() -> void:
	assert_eq(_route().length, 150.0)

func test_position_at_start_and_end() -> void:
	assert_eq(_route().position_at(0.0), Vector2(0, 0))
	assert_eq(_route().position_at(150.0), Vector2(100, 50))

func test_position_interpolates_inside_a_segment() -> void:
	assert_eq(_route().position_at(50.0), Vector2(50, 0))
	assert_eq(_route().position_at(125.0), Vector2(100, 25))

func test_position_clamps_outside_the_route() -> void:
	assert_eq(_route().position_at(-10.0), Vector2(0, 0))
	assert_eq(_route().position_at(999.0), Vector2(100, 50))

func test_horizontal_direction_follows_the_segment() -> void:
	var route := Route.new([Vector2(0, 0), Vector2(100, 0), Vector2(100, 50), Vector2(40, 50)])
	assert_eq(route.horizontal_direction_at(10.0), 1)
	assert_eq(route.horizontal_direction_at(120.0), 0, "trecho vertical não define lado")
	assert_eq(route.horizontal_direction_at(170.0), -1)

func test_route_needs_two_points() -> void:
	var route := Route.new([Vector2(5, 5)])
	assert_eq(route.length, 0.0)
	assert_eq(route.position_at(10.0), Vector2(5, 5))
