class_name Progression
extends RefCounted
## Experiência, nível, custo de treino e patente. Funções puras.


## Soma `gain` ao XP e sobe de nível enquanto houver XP para o próximo, carregando a sobra.
## O nível máximo é o último índice de `xp_table`.
## Devolve {lvl, xp, levels_gained}.
static func add_xp(lvl: int, xp: int, gain: int, rules: RulesPack) -> Dictionary:
	var table: PackedInt64Array = rules.balance.xp_table
	var max_lvl: int = table.size() - 1
	var cur_lvl: int = lvl
	var cur_xp: int = xp + gain
	var gained: int = 0
	while cur_lvl < max_lvl and cur_xp >= table[cur_lvl]:
		cur_xp -= table[cur_lvl]
		cur_lvl += 1
		gained += 1
	return {"lvl": cur_lvl, "xp": cur_xp, "levels_gained": gained}


## Custo em vinténs de subir um atributo que está em `value` (valores fora da tabela são limitados).
static func train_cost(value: int, rules: RulesPack) -> int:
	var table: PackedInt64Array = rules.balance.train_cost
	return table[clampi(value, 1, table.size() - 1)]


## Nome da maior patente cujo nível mínimo já foi atingido (a primeira, se nenhuma).
static func rank(lvl: int, rules: RulesPack) -> String:
	var ranks: Array[Defs.RankDef] = rules.balance.ranks
	var out: String = ranks[0].nome
	for r: Defs.RankDef in ranks:
		if lvl >= r.lvl:
			out = r.nome
	return out
