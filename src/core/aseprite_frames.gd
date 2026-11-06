extends RefCounted
## Converte o JSON exportado pelo Aseprite em SpriteFrames, sem plugin.

const SPEED_FPS := 10.0
const ONE_SHOT_ANIMATIONS := ["attack", "death", "fall", "split"]


## Lê o JSON e retorna {error, frames, tags}. A falta de tags é um erro, para
## que um sprite nunca fique sem animação sem aviso.
static func parse(text: String) -> Dictionary:
	var json := JSON.new()
	if json.parse(text) != OK or not json.data is Dictionary:
		return _failure("JSON inválido")
	var data: Dictionary = json.data
	var tags: Array = data.get("meta", {}).get("frameTags", [])
	if tags.is_empty():
		return _failure("sem frameTags: exporte com list_tags")
	var entries: Array = data.frames.values() if data.frames is Dictionary else data.frames
	var frames := []
	for entry: Dictionary in entries:
		var box: Dictionary = entry.frame
		frames.append({
			"region": Rect2i(int(box.x), int(box.y), int(box.w), int(box.h)),
			"duration": float(entry.duration),
		})
	for tag: Dictionary in tags:
		if int(tag.to) >= frames.size() or int(tag.from) < 0:
			return _failure("tag %s fora dos quadros" % tag.name)
	return {"error": "", "frames": frames, "tags": tags}


static func build(sheet: Dictionary, texture: Texture2D) -> SpriteFrames:
	var result := SpriteFrames.new()
	result.remove_animation("default")
	for tag: Dictionary in sheet.tags:
		var animation: String = tag.name
		result.add_animation(animation)
		result.set_animation_speed(animation, SPEED_FPS)
		result.set_animation_loop(animation, not animation in ONE_SHOT_ANIMATIONS)
		for i in range(int(tag.from), int(tag.to) + 1):
			var frame: Dictionary = sheet.frames[i]
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(frame.region)
			result.add_frame(animation, atlas, frame.duration * SPEED_FPS / 1000.0)
	return result


static func _failure(message: String) -> Dictionary:
	return {"error": message, "frames": [], "tags": []}
