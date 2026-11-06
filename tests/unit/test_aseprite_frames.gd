extends GutTest

const AsepriteFrames = preload("res://src/core/aseprite_frames.gd")

const ARRAY_JSON := """{ "frames": [
 { "filename": "slime 0.aseprite", "frame": { "x": 0, "y": 0, "w": 32, "h": 32 }, "duration": 100 },
 { "filename": "slime 1.aseprite", "frame": { "x": 32, "y": 0, "w": 32, "h": 32 }, "duration": 250 }
 ],
 "meta": { "image": "slime.png", "frameTags": [
   { "name": "idle", "from": 0, "to": 1, "direction": "forward" },
   { "name": "attack", "from": 1, "to": 1, "direction": "forward" }
 ] } }"""

const HASH_JSON := """{ "frames": {
 "slime 0.aseprite": { "frame": { "x": 0, "y": 0, "w": 32, "h": 32 }, "duration": 100 },
 "slime 1.aseprite": { "frame": { "x": 32, "y": 0, "w": 32, "h": 32 }, "duration": 250 }
 },
 "meta": { "image": "slime.png", "frameTags": [ { "name": "idle", "from": 0, "to": 1, "direction": "forward" } ] } }"""

func test_reads_array_export() -> void:
	var sheet := AsepriteFrames.parse(ARRAY_JSON)
	assert_eq(sheet.error, "")
	assert_eq(sheet.frames.size(), 2)
	assert_eq(sheet.frames[1].region, Rect2i(32, 0, 32, 32))
	assert_eq(sheet.tags.size(), 2)

func test_reads_hash_export() -> void:
	var sheet := AsepriteFrames.parse(HASH_JSON)
	assert_eq(sheet.error, "")
	assert_eq(sheet.frames[1].region, Rect2i(32, 0, 32, 32))

func test_missing_tags_is_an_error_not_a_silent_empty_sprite() -> void:
	var sheet := AsepriteFrames.parse('{"frames": [], "meta": {"image": "a.png"}}')
	assert_eq(sheet.error, "sem frameTags: exporte com list_tags")

func test_tag_outside_frames_is_an_error() -> void:
	var text := ARRAY_JSON.replace('"to": 1, "direction": "forward" },\n', '"to": 9, "direction": "forward" },\n')
	assert_eq(AsepriteFrames.parse(text).error, "tag idle fora dos quadros")

func test_invalid_json_is_an_error() -> void:
	assert_eq(AsepriteFrames.parse("{nope").error, "JSON inválido")

func test_builds_sprite_frames_with_durations_from_milliseconds() -> void:
	var frames := AsepriteFrames.build(AsepriteFrames.parse(ARRAY_JSON), PlaceholderTexture2D.new())
	assert_eq(frames.get_frame_count("idle"), 2)
	assert_eq(frames.get_animation_speed("idle"), 10.0)
	assert_eq(frames.get_frame_duration("idle", 0), 1.0)
	assert_eq(frames.get_frame_duration("idle", 1), 2.5)

func test_atlas_regions_match_the_sheet() -> void:
	var frames := AsepriteFrames.build(AsepriteFrames.parse(ARRAY_JSON), PlaceholderTexture2D.new())
	var atlas: AtlasTexture = frames.get_frame_texture("idle", 1)
	assert_eq(atlas.region, Rect2(32, 0, 32, 32))

func test_looping_depends_on_the_animation() -> void:
	var frames := AsepriteFrames.build(AsepriteFrames.parse(ARRAY_JSON), PlaceholderTexture2D.new())
	assert_true(frames.get_animation_loop("idle"))
	assert_false(frames.get_animation_loop("attack"))

func test_default_animation_is_removed() -> void:
	var frames := AsepriteFrames.build(AsepriteFrames.parse(ARRAY_JSON), PlaceholderTexture2D.new())
	assert_false(frames.has_animation("default"))
