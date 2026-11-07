extends GutTest

const UiKit = preload("res://src/game/ui_kit.gd")

const ICONS := [
	"heart", "coin", "skull", "pause", "play", "fast", "menu", "upgrade", "target", "sword",
	"pierce", "impact", "magic", "range", "cadence", "star", "star_empty", "close", "lock", "speaker",
]

func test_every_piece_lies_inside_the_sheet() -> void:
	var sheet: Texture2D = UiKit.sheet()
	for name: String in UiKit.regions():
		var rect: Rect2 = UiKit.texture(name).region
		assert_true(Rect2(Vector2.ZERO, sheet.get_size()).encloses(rect), name)

func test_every_icon_has_pixels() -> void:
	var image := UiKit.sheet().get_image()
	for name: String in ICONS:
		var rect: Rect2i = Rect2i(UiKit.icon(name).region)
		assert_false(image.get_region(rect).is_invisible(), name)

func test_button_styles_stretch_the_middle_and_keep_the_border() -> void:
	for state: String in ["normal", "hover", "pressed", "disabled"]:
		var style: StyleBoxTexture = UiKit.style("button_%s" % state)
		assert_eq(style.texture_margin_left, 3.0, state)
		assert_eq(style.texture_margin_bottom, 3.0, state)

func test_pressed_button_pushes_its_content_down() -> void:
	var normal: StyleBoxTexture = UiKit.style("button_normal")
	var pressed: StyleBoxTexture = UiKit.style("button_pressed")
	assert_gt(pressed.content_margin_top, normal.content_margin_top)

func test_monster_icon_shows_the_top_of_the_body() -> void:
	var frames: SpriteFrames = load("res://assets/sprites/slime_king.tres")
	var icon: AtlasTexture = UiKit.frame_icon(frames, "walk", 20)
	assert_eq(icon.get_size(), Vector2(20, 20))
	assert_false(icon.get_image().is_invisible())

func test_pixel_font_has_every_character_of_the_translations() -> void:
	var font: FontFile = UiKit.font()
	var file := FileAccess.open("res://data/i18n/strings.csv", FileAccess.READ)
	file.get_csv_line()
	while not file.eof_reached():
		var row := file.get_csv_line()
		for text: String in row.slice(1):
			for i in text.length():
				assert_true(font.has_char(text.unicode_at(i)), "falta '%s' em %s" % [text[i], row[0]])

func test_pixel_font_keeps_its_pixel_height() -> void:
	var font: FontFile = UiKit.font()
	assert_eq(font.get_height(UiKit.FONT_SIZE), 12.0)
	assert_eq(font.get_ascent(UiKit.FONT_SIZE), 9.0)
