class_name Missions
extends RefCounted
## Ofertas de missão e o inimigo das missões de luta. Funções puras.


## Missão {id, c, luta, d, f, dur, en, xp, vint}. `c` é o id da lenda, `d` a dificuldade
## (0 a 2) e `f` o índice da frase. Só entram lendas com `lvl <= lvl`; lenda aliada nunca luta.
static func generate(lvl: int, uid: int, rng: Rng, rules: RulesPack) -> Dictionary:
	var cfg: Dictionary = rules.balance.mission
	var pool: Array = []
	for id: String in rules.legends:
		if rules.legends[id].lvl <= lvl:
			pool.append(id)
	var legend_id: String = str(rng.pick(pool))
	var legend: Defs.LegendDef = rules.legends[legend_id]
	var d: int = rng.range_int(0, (cfg["dif_pm"] as Array).size() - 1)
	var luta: bool = not legend.ally and rng.roll_bp(int(cfg["luta_chance_bp"]))
	var phrases: PackedStringArray = legend.lutas if luta else legend.tarefas
	var f: int = rng.range_int(0, phrases.size() - 1)
	var mult_pm: int = int(cfg["dif_pm"][d])
	if luta:
		mult_pm = mult_pm * int(cfg["luta_pm"]) / 1000
	mult_pm = mult_pm * (1000 + legend.lvl * int(cfg["lenda_pm_por_lvl"])) / 1000
	return {
		"id": uid,
		"c": legend_id,
		"luta": luta,
		"d": d,
		"f": f,
		"dur": int(cfg["dur_s"][d]),
		"en": int(cfg["energia"][d]),
		"xp": IntMath.div_round((int(cfg["xp_base"]) + lvl * int(cfg["xp_lvl"])) * mult_pm, 1000),
		"vint":
		IntMath.div_round((int(cfg["vint_base"]) + lvl * int(cfg["vint_lvl"])) * mult_pm, 1000),
	}


## Inimigo de uma missão de luta: atributos do herói × dificuldade × perfil da lenda × ruído.
## `hero_stats` são os atributos totais (com equipamento). Um sorteio de ruído por atributo.
static func enemy_for(
	mission: Dictionary, hero_stats: Dictionary, lvl: int, rng: Rng, rules: RulesPack
) -> Fighter:
	var cfg: Dictionary = rules.balance.mission
	var legend: Defs.LegendDef = rules.legends[str(mission["c"])]
	var diff_pm: int = int(cfg["enemy_pm"][int(mission["d"])])
	var st: Dictionary = {}
	for k: String in Defs.STAT_KEYS:
		var noise: int = rng.range_int(
			int(cfg["enemy_noise_min_pm"]), int(cfg["enemy_noise_max_pm"])
		)
		var raw: int = int(hero_stats[k]) * diff_pm * legend.perf_pm[k] * noise
		st[k] = maxi(int(cfg["enemy_stat_min"]), IntMath.div_round(raw, 1000000000))
	return Fighter.make(legend.nome, lvl, st, legend.id)
