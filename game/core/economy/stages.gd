class_name Stages
extends RefCounted
## Fases da Torre dos Chefes: inimigo, nível exigido e recompensa. `act` e `n` começam em 0;
## a última fase de cada ato é a do chefe. Funções puras.


static func required_level(act: int, n: int, rules: RulesPack) -> int:
	return rules.acts[act].de + n


static func is_boss(act: int, n: int, rules: RulesPack) -> bool:
	return n == rules.acts[act].stages.size() - 1


## Atributos = CURVA[nível] × multiplicador da fase × perfil da lenda.
static func enemy(act: int, n: int, rules: RulesPack) -> Fighter:
	var cfg: Dictionary = rules.balance.stage
	var stage: Defs.StageDef = rules.acts[act].stages[n]
	var legend: Defs.LegendDef = rules.legends[stage.legend_id]
	var lvl: int = required_level(act, n, rules)
	var mult_pm: int = int(cfg["mult_base_pm"]) + int(cfg["mult_step_pm"]) * (n + 1)
	if is_boss(act, n, rules):
		mult_pm = int(cfg["boss_pm"])
	var base: int = rules.balance.curva[lvl - 1]
	var st: Dictionary = {}
	for k: String in Defs.STAT_KEYS:
		st[k] = IntMath.div_round(base * mult_pm * legend.perf_pm[k], 1000000)
	return Fighter.make(stage.nome, lvl, st, legend.id)


## Recompensa da vitória: {xp, vint, muir, item_rarity_min}. Chefe dá mais XP e vinténs,
## muiraquitãs e um item de raridade mínima.
static func reward(act: int, n: int, rules: RulesPack) -> Dictionary:
	var cfg: Dictionary = rules.balance.stage
	var lvl: int = required_level(act, n, rules)
	var vint: int = int(cfg["vint_base"]) + lvl * int(cfg["vint_lvl"])
	var xp_pm: int = int(cfg["xp_pm"])
	var muir: int = 0
	var rarity_min: int = 0
	if is_boss(act, n, rules):
		vint *= int(cfg["boss_vint_mult"])
		xp_pm = int(cfg["boss_xp_pm"])
		muir = int(cfg["boss_muir"])
		rarity_min = int(cfg["boss_rarity_min"])
	return {
		"xp": rules.balance.xp_table[lvl] * xp_pm / 1000,
		"vint": vint,
		"muir": muir,
		"item_rarity_min": rarity_min,
	}


## Raridade mínima do item do chefe: lendária (2) com chance `boss_legendary_bp`,
## senão `boss_rarity_min`.
static func boss_item_rarity_min(rng: Rng, rules: RulesPack) -> int:
	var cfg: Dictionary = rules.balance.stage
	if rng.roll_bp(int(cfg["boss_legendary_bp"])):
		return 2
	return int(cfg["boss_rarity_min"])
