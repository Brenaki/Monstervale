extends RefCounted
## Escolhas de quem joga que valem para todas as partidas: volumes, tela cheia e idioma.

const VOLUME_STEP := 0.1
const SILENCE_DB := -80.0
const DEV_KEYS := ["dev_mode", "dev_invincible", "dev_infinite_gold", "dev_record"]

var music_volume := 0.6
var sfx_volume := 0.8
var fullscreen := false
## Vazio segue o idioma do sistema.
var locale := ""
## Modo dev, só nos builds de desenvolvimento: serve para medir a dificuldade das fases.
var dev_mode := false
var dev_invincible := false
var dev_infinite_gold := false
var dev_record := true


static func from_dict(data: Dictionary):
	var settings = new()
	settings.music_volume = _volume(data.get("music_volume"), settings.music_volume)
	settings.sfx_volume = _volume(data.get("sfx_volume"), settings.sfx_volume)
	if data.get("fullscreen") is bool:
		settings.fullscreen = data.fullscreen
	if data.get("locale") is String:
		settings.locale = data.locale
	for key: String in DEV_KEYS:
		if data.get(key) is bool:
			settings.set(key, data[key])
	return settings


static func volume_db(volume: float) -> float:
	return SILENCE_DB if volume <= 0.0 else linear_to_db(volume)


static func _volume(value, fallback: float) -> float:
	if value is float or value is int:
		return clampf(float(value), 0.0, 1.0)
	return fallback


func to_dict() -> Dictionary:
	var data := {"music_volume": music_volume, "sfx_volume": sfx_volume, "fullscreen": fullscreen, "locale": locale}
	for key: String in DEV_KEYS:
		data[key] = get(key)
	return data


## channel é "music" ou "sfx"; direction, 1 ou -1.
func step_volume(channel: String, direction: int) -> void:
	var key := "%s_volume" % channel
	var stepped: float = snappedf(get(key) + direction * VOLUME_STEP, VOLUME_STEP)
	set(key, clampf(stepped, 0.0, 1.0))
