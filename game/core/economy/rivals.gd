class_name Rivals
extends RefCounted
## Rivais da Arena, portado de genRival da v0.2. Funções puras.


## Rival {id, nome, lvl, st, cor, honra}. Ordem dos sorteios: nível, fator, ruído por atributo,
## nome, sobrenome, cor, fator de honra, acréscimo de honra.
static func generate(
	hero_lvl: int, hero_stats: Dictionary, honra: int, uid: int, rng: Rng, rules: RulesPack
) -> Dictionary:
	var cfg: Dictionary = rules.balance.rival
	var lvl: int = maxi(
		1, hero_lvl + rng.range_int(int(cfg["lvl_delta_min"]), int(cfg["lvl_delta_max"]))
	)
	var factor_pm: int = rng.range_int(int(cfg["factor_min_pm"]), int(cfg["factor_max_pm"]))
	factor_pm = factor_pm * (1000 + (lvl - hero_lvl) * int(cfg["lvl_gap_pm"])) / 1000
	var st: Dictionary = {}
	for k: String in Defs.STAT_KEYS:
		var noise: int = rng.range_int(int(cfg["noise_min_pm"]), int(cfg["noise_max_pm"]))
		var raw: int = int(hero_stats[k]) * factor_pm * noise
		st[k] = maxi(int(cfg["stat_min"]), IntMath.div_round(maxi(raw, 0), 1000000))
	var nome: String = "%s %s" % [str(rng.pick(rules.rival_first)), str(rng.pick(rules.rival_last))]
	var cor: String = str(rng.pick(cfg["colors"]))
	var honra_pm: int = rng.range_int(int(cfg["honra_min_pm"]), int(cfg["honra_max_pm"]))
	var honra_add: int = rng.range_int(0, int(cfg["honra_add_max"]))
	return {
		"id": uid,
		"nome": nome,
		"lvl": lvl,
		"st": st,
		"cor": cor,
		"honra": maxi(0, IntMath.div_round(maxi(honra, 0) * honra_pm, 1000) + honra_add),
	}
