class_name TrainHandler
extends RefCounted
## `treinar`: sobe um atributo base em 1 pelo custo da tabela.


static func run(c: HandlerCtx) -> String:
	var stat: String = c.arg_str("stat")
	if not Defs.STAT_KEYS.has(stat):
		return "ATRIBUTO_INVALIDO"
	var cost: int = Progression.train_cost(c.s.stats[stat], c.rules)
	if c.s.vint < cost:
		return "VINTENS_INSUFICIENTES"
	c.s.vint -= cost
	c.s.stats[stat] += 1
	return ""
