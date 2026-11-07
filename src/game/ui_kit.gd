extends RefCounted
## Peças de interface desenhadas em tools/build_ui.lua: molduras, botões e ícones.

const SHEET_PATH := "res://assets/ui/ui.png"
const REGIONS_PATH := "res://assets/ui/ui.json"
const FONT_PATH := "res://assets/ui/font.fnt"
## A fonte de pixel tem 12 px de linha; em outro tamanho, as letras deixariam de bater com os pixels.
const FONT_SIZE := 12
const CONTENT_SIDE := 4
const CONTENT_TOP := 2
const CONTENT_BOTTOM := 4
const PRESSED_DROP := 1
const SHADOW_COLOR := Color("1b1626")
const BACKDROP_COLOR := Color(0, 0, 0, 0.5)

static var _regions := {}


static func sheet() -> Texture2D:
	return load(SHEET_PATH)


static func font() -> FontFile:
	return load(FONT_PATH)


static func regions() -> Dictionary:
	if _regions.is_empty():
		_regions = JSON.parse_string(FileAccess.get_file_as_string(REGIONS_PATH))
	return _regions


static func texture(name: String) -> AtlasTexture:
	var r: Dictionary = regions()[name]
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet()
	atlas.region = Rect2(r.x, r.y, r.w, r.h)
	return atlas


static func icon(name: String) -> AtlasTexture:
	return texture("icon_%s" % name)


## Moldura que estica o miolo e mantém a borda; apertado, o conteúdo desce junto com a face.
static func style(name: String) -> StyleBoxTexture:
	var margin := float(regions()[name].margin)
	var box := StyleBoxTexture.new()
	box.texture = texture(name)
	box.texture_margin_left = margin
	box.texture_margin_right = margin
	box.texture_margin_top = margin
	box.texture_margin_bottom = margin
	box.content_margin_left = CONTENT_SIDE
	box.content_margin_right = CONTENT_SIDE
	box.content_margin_top = CONTENT_TOP
	box.content_margin_bottom = CONTENT_BOTTOM
	if name.ends_with("_pressed"):
		box.content_margin_top += PRESSED_DROP
		box.content_margin_bottom -= PRESSED_DROP
	return box


## Um quadrado do alto do corpo, para mostrar um personagem num botão ou na prévia da onda.
static func frame_icon(frames: SpriteFrames, animation: String, size: int) -> AtlasTexture:
	var frame: AtlasTexture = frames.get_frame_texture(animation, 0)
	var body := frame.get_image().get_used_rect()
	var frame_size := Vector2i(frame.region.size)
	var corner := Vector2i(body.get_center().x - size / 2, body.position.y - 1)
	corner = corner.clamp(Vector2i.ZERO, frame_size - Vector2i(size, size))
	var icon := AtlasTexture.new()
	icon.atlas = frame.atlas
	icon.region = Rect2(frame.region.position + Vector2(corner), Vector2(size, size))
	return icon


## Tema de toda a interface: fonte de pixel, molduras e botões do kit.
static func theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = FONT_SIZE
	theme.default_font = font()
	# O tema padrão do Godot traz 16 px para cada tipo; sem isso a fonte de pixel desce da linha.
	for type_name: String in ["Label", "Button", "TooltipLabel"]:
		theme.set_font("font", type_name, font())
		theme.set_font_size("font_size", type_name, FONT_SIZE)
	theme.set_stylebox("panel", "Panel", style("panel"))
	for state: String in ["normal", "hover", "pressed", "disabled"]:
		theme.set_stylebox(state, "Button", style("button_%s" % state))
	theme.set_stylebox("hover_pressed", "Button", style("button_pressed"))
	theme.set_color("font_disabled_color", "Button", Color(1, 1, 1, 0.4))
	for type_name: String in ["Label", "Button"]:
		theme.set_color("font_shadow_color", type_name, SHADOW_COLOR)
		theme.set_constant("shadow_offset_x", type_name, 1)
		theme.set_constant("shadow_offset_y", type_name, 1)
	return theme


## Fundo escuro que cobre a tela e segura os cliques enquanto um painel está aberto.
static func backdrop(parent: Control, size: Vector2) -> Panel:
	var backdrop := Panel.new()
	backdrop.size = size
	backdrop.visible = false
	var flat := StyleBoxFlat.new()
	flat.bg_color = BACKDROP_COLOR
	backdrop.add_theme_stylebox_override("panel", flat)
	parent.add_child(backdrop)
	return backdrop


static func panel(parent: Control, rect: Rect2) -> Panel:
	var box := Panel.new()
	box.position = rect.position
	box.size = rect.size
	box.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(box)
	return box


static func texture_rect(parent: Control, texture: Texture2D, rect: Rect2) -> TextureRect:
	var image := TextureRect.new()
	image.texture = texture
	image.position = rect.position
	image.size = rect.size
	image.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(image)
	return image


## O tamanho vem depois de entrar no tema: antes, o rótulo mede com a fonte padrão, mais alta, e não encolhe mais.
static func label(parent: Control, rect: Rect2) -> Label:
	var text := Label.new()
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(text)
	text.position = rect.position
	text.size = rect.size
	return text


## kind escolhe o jogo de molduras do kit: "button" ou "green".
static func button(parent: Control, rect: Rect2, kind := "button") -> Button:
	var pressable := Button.new()
	pressable.position = rect.position
	pressable.size = rect.size
	pressable.focus_mode = Control.FOCUS_NONE
	pressable.clip_text = true
	pressable.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	if kind != "button":
		for state: String in ["normal", "hover", "pressed", "disabled"]:
			pressable.add_theme_stylebox_override(state, style("%s_%s" % [kind, state]))
	parent.add_child(pressable)
	return pressable
