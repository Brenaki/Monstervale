extends RefCounted
## Conquistas: concluir cada fase, derrotar o Rei Slime, 3 estrelas em todas e o speedrun com 3 estrelas.

## 39:07, a soma das melhores vitórias com 3 estrelas de quem dirige o projeto, com as regras atuais:
## Fase 1 em 4:01, Fase 2 em 6:13, Fase 3 em 6:41, Fase 4 em 10:36 (a partida aprovada, que hoje
## ganha 3 estrelas) e Fase 5 em 11:36.
const SPEEDRUN_SECONDS := 2347.0
const HERO := "hero"
const IDS := ["level_1", "level_2", "level_3", "level_4", "level_5", HERO, "hero_of_heroes", "speedrunner"]


## As conquistas novas de uma vitória sem ajuda. progress já tem as estrelas e o tempo desta partida.
static func after_win(progress, level: int, level_count: int) -> Array:
	var earned := ["level_%d" % (level + 1)]
	var all_three := true
	for i in level_count:
		all_three = all_three and progress.stars_for(i) == progress.MAX_STARS
	if all_three:
		earned.append("hero_of_heroes")
	# Speedrunner: 3 estrelas em todas as fases desta campanha, dentro do tempo. Voltar a uma fase
	# para tirar as 3 estrelas vale, se o relógio ainda não passou do limite.
	if all_three and progress.campaign_timed() and progress.campaign_seconds <= SPEEDRUN_SECONDS:
		earned.append("speedrunner")
	return earned.filter(func(id: String) -> bool: return progress.unlock(id))


## Saves de antes das conquistas: as fases vencidas e as 3 estrelas em todas valem, sem aviso.
static func from_stars(progress, level_count: int) -> void:
	var all_three := true
	for i in level_count:
		if progress.stars_for(i) > 0:
			progress.unlock("level_%d" % (i + 1))
		all_three = all_three and progress.stars_for(i) == progress.MAX_STARS
	if all_three:
		progress.unlock("hero_of_heroes")


static func clock(seconds: float) -> String:
	var whole := floori(seconds)
	return "%d:%02d" % [whole / 60, whole % 60]
