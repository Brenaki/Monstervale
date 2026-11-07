extends RefCounted
## Relatório de uma partida, por onda, para avaliar a dificuldade depois de jogar.
## É sempre em português, qualquer que seja o idioma do jogo.

const RESULT_LABELS := {
	"won": "Vitória",
	"lost": "Derrota",
	"restarted": "Reiniciada",
	"closed": "Jogo fechado",
	"left": "Voltou ao menu",
	"playing": "Em andamento",
}
const REPORT_LOCALE := "pt_BR"
const ACTION_VERBS := {"place": "Posicionou", "upgrade": "Melhorou", "dismiss": "Dispensou"}

var _level_id: String
var _started_at: String
var _result := "playing"
var _duration := 0.0
var _lives_final := 0
var _gold_final := 0
var _stars := 0
var _actions: Array = []
var _waves: Array = []


func _init(level_id: String, started_at: String) -> void:
	_level_id = level_id
	_started_at = started_at


func has_activity() -> bool:
	return not _actions.is_empty() or not _waves.is_empty()


func consume(events: Array, sim) -> void:
	for event: Dictionary in events:
		match event.type:
			"unit_placed":
				_add_action("place", event)
			"unit_upgraded":
				_add_action("upgrade", event)
			"unit_dismissed":
				_add_action("dismiss", event)
			"wave_started":
				_add_wave(event, sim)
			"wave_cleared":
				_close_wave(event)
			"monster_spawned":
				_count(event.monster, "spawned")
			"monster_killed":
				_count(event.monster, "killed")
				var killed_wave = _wave_of(event.monster)
				if killed_wave != null:
					killed_wave.kill_gold += event.monster.gold + int(event.get("bonus_gold", 0))
			"monster_escaped":
				_count(event.monster, "escaped")
				var escaped_wave = _wave_of(event.monster)
				if escaped_wave != null:
					escaped_wave.lives_end = event.lives
			"monster_hit":
				var hit_wave = _wave_of(event.monster)
				if hit_wave != null:
					hit_wave.damage[event.source] = hit_wave.damage.get(event.source, 0) + event.damage
			"unit_down":
				if not _waves.is_empty():
					_waves[-1].units_down += 1


func finish(result: String, sim) -> void:
	_result = result
	_duration = sim.elapsed
	_lives_final = sim.lives
	_gold_final = sim.gold
	_stars = sim.stars() if result == "won" else 0


func file_stem() -> String:
	var stamp := _started_at.replace(":", "-").replace(" ", "_").replace("T", "_")
	return "partida_%s_%s" % [stamp, _level_id]


func to_dict() -> Dictionary:
	return {
		"level": _level_id,
		"started_at": _started_at,
		"result": _result,
		"duration": _duration,
		"lives_final": _lives_final,
		"gold_final": _gold_final,
		"stars": _stars,
		"actions": _actions,
		"waves": _waves,
	}


func to_markdown() -> String:
	var lines := PackedStringArray()
	lines.append("# Partida: %s" % _level_id)
	lines.append("")
	lines.append("- Início: %s" % _started_at)
	lines.append("- Resultado: %s" % _result_text())
	lines.append("- Tempo de jogo: %s" % _clock(_duration))
	lines.append("- Vidas finais: %d" % _lives_final)
	lines.append("- Ouro final: %d" % _gold_final)
	lines.append("")
	lines.append("Os tempos são de jogo: não contam pausas e, na velocidade 2x, correm duas vezes mais rápido que o relógio.")
	var preparation := _actions_of(0)
	if not preparation.is_empty():
		lines.append("")
		lines.append("## Preparação inicial")
		lines.append("")
		lines.append_array(preparation)
	for wave: Dictionary in _waves:
		lines.append("")
		lines.append_array(_wave_lines(wave))
	lines.append("")
	lines.append("## Notas gerais")
	lines.append("")
	return "\n".join(lines) + "\n"


func _add_action(action: String, event: Dictionary) -> void:
	var unit = event.unit
	_actions.append({
		"time": event.time,
		"action": action,
		"unit": unit.kind,
		"cell": [unit.cell.x, unit.cell.y],
		"level": unit.level,
		"gold_after": event.gold,
		"wave": event.waves_started,
	})


func _add_wave(event: Dictionary, sim) -> void:
	var defenders := {}
	for unit in sim.units:
		var key := "%s %d" % [unit.kind, unit.level]
		defenders[key] = defenders.get(key, 0) + 1
	_waves.append({
		"number": event.number,
		"started_at": event.time,
		"cleared_at": null,
		"called_early": event.called_early,
		"early_bonus": event.early_bonus,
		"gold_start": event.gold,
		"gold_end": null,
		"lives_start": event.lives,
		"lives_end": event.lives,
		"defenders": defenders,
		"spawned": {},
		"killed": {},
		"escaped": {},
		"damage": {},
		"kill_gold": 0,
		"bonus": 0,
		"units_down": 0,
	})


func _close_wave(event: Dictionary) -> void:
	var wave: Dictionary = _waves[event.number - 1]
	wave.cleared_at = event.time
	wave.gold_end = event.gold
	wave.lives_end = event.lives
	wave.bonus = event.bonus


func _wave_of(monster):
	if monster.wave == null:
		return null
	return _waves[monster.wave.number - 1]


func _count(monster, field: String) -> void:
	var wave = _wave_of(monster)
	if wave != null:
		wave[field][monster.kind] = wave[field].get(monster.kind, 0) + 1


func _result_text() -> String:
	var label: String = RESULT_LABELS.get(_result, _result)
	if _result == "won":
		return "%s (%d estrelas)" % [label, _stars]
	return label


func _wave_lines(wave: Dictionary) -> PackedStringArray:
	var lines := PackedStringArray()
	lines.append("## Onda %d" % wave.number)
	lines.append("")
	var start := _clock(wave.started_at)
	if wave.called_early:
		start += " (chamada antes da hora, +%d de ouro)" % wave.early_bonus
	lines.append("- Início: %s" % start)
	if wave.cleared_at == null:
		lines.append("- Fim: não terminou")
	else:
		lines.append("- Fim: %s (duração %s)" % [_clock(wave.cleared_at), _clock(wave.cleared_at - wave.started_at)])
	lines.append("- Defesa no início: %s" % _defenders_text(wave.defenders))
	lines.append("- Monstros: %s" % _monsters_text(wave.spawned))
	lines.append("- Abatidos: %s" % _monsters_text(wave.killed))
	lines.append("- Passaram: %s" % _monsters_text(wave.escaped))
	lines.append("- Vidas: %d → %d" % [wave.lives_start, wave.lives_end])
	if wave.gold_end == null:
		lines.append("- Ouro no início: %d (abates +%d)" % [wave.gold_start, wave.kill_gold])
	else:
		lines.append("- Ouro: %d → %d (abates +%d, bônus +%d)" % [wave.gold_start, wave.gold_end, wave.kill_gold, wave.bonus])
	lines.append("- Dano: %s" % _damage_text(wave.damage))
	lines.append("- Humanos caídos: %d" % wave.units_down)
	var actions := _actions_of(wave.number)
	if not actions.is_empty():
		lines.append("- Ações depois do início da onda:")
		for action in actions:
			lines.append("  " + action)
	lines.append("- Notas:")
	return lines


func _actions_of(wave_number: int) -> PackedStringArray:
	var lines := PackedStringArray()
	for action: Dictionary in _actions:
		if action.wave == wave_number:
			var name_text := _unit_name(action.unit)
			if action.action == "upgrade":
				name_text += " para o nível %d" % action.level
			lines.append("- %s %s %s em (%d, %d), ouro restante %d" % [
				_clock(action.time), ACTION_VERBS[action.action], name_text,
				action.cell[0], action.cell[1], action.gold_after,
			])
	return lines


func _defenders_text(defenders: Dictionary) -> String:
	if defenders.is_empty():
		return "nenhuma"
	var parts := []
	for key: String in defenders:
		var pieces := key.split(" ")
		parts.append("%s nível %s x%d" % [_unit_name(pieces[0]), pieces[1], defenders[key]])
	return ", ".join(parts)


func _monsters_text(counts: Dictionary) -> String:
	if counts.is_empty():
		return "nenhum"
	var parts := []
	for kind: String in counts:
		parts.append("%s x%d" % [_translated("MONSTER_%s" % kind.to_upper()), counts[kind]])
	return ", ".join(parts)


func _damage_text(damage: Dictionary) -> String:
	if damage.is_empty():
		return "nenhum"
	var parts := []
	for kind: String in damage:
		parts.append("%s %d" % [_unit_name(kind), damage[kind]])
	return ", ".join(parts)


func _unit_name(kind: String) -> String:
	return _translated("UNIT_%s" % kind.to_upper())


func _translated(key: String) -> String:
	var translation := TranslationServer.get_translation_object(REPORT_LOCALE)
	var text: String = translation.get_message(key) if translation != null else ""
	return text if text != "" else key


func _clock(seconds: float) -> String:
	var total := int(seconds)
	return "%02d:%02d" % [total / 60, total % 60]
