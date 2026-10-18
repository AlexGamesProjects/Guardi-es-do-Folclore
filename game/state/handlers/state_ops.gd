class_name StateOps
extends RefCounted
## Operações que vários handlers repetem: ganhos, gastos, itens e luta.


static func index_of(list: Array[Dictionary], id: int) -> int:
	for i: int in list.size():
		if int(list[i]["id"]) == id:
			return i
	return -1


static func add_vint(c: HandlerCtx, amount: int, origem: String) -> void:
	c.s.vint += amount
	c.emit("vintens_ganhos", {"amount": amount, "origem": origem})


static func add_muir(c: HandlerCtx, amount: int, origem: String) -> void:
	if amount <= 0:
		return
	c.s.muir += amount
	c.emit("muiraquitas_ganhas", {"amount": amount, "origem": origem})


static func spend_energy(c: HandlerCtx, amount: int) -> bool:
	var b: Defs.BalanceDef = c.rules.balance
	var r: Dictionary = Stamina.spend(c.s.energia, c.s.en_upd_ms, c.now_ms, b.en_max, amount)
	if r["ok"]:
		c.s.energia = r["cur"]
		c.s.en_upd_ms = r["upd_ms"]
	return r["ok"]


static func spend_courage(c: HandlerCtx, amount: int) -> bool:
	var b: Defs.BalanceDef = c.rules.balance
	var r: Dictionary = Stamina.spend(c.s.coragem, c.s.co_upd_ms, c.now_ms, b.co_max, amount)
	if r["ok"]:
		c.s.coragem = r["cur"]
		c.s.co_upd_ms = r["upd_ms"]
	return r["ok"]


## Soma XP e sobe de nível: cada nível dá muiraquitãs e enche a energia.
static func gain_xp(c: HandlerCtx, amount: int) -> void:
	var s: GameState = c.s
	var r: Dictionary = Progression.add_xp(s.lvl, s.xp, amount, c.rules)
	c.emit("xp_ganho", {"amount": amount})
	var old_lvl: int = s.lvl
	s.lvl = r["lvl"]
	s.xp = r["xp"]
	for new_lvl: int in range(old_lvl + 1, s.lvl + 1):
		s.energia = c.rules.balance.en_max
		s.en_upd_ms = c.now_ms
		add_muir(c, int(c.rules.balance.progress["levelup_muir"]), "nivel")
		c.emit("subiu_nivel", {"lvl": new_lvl})


## Guarda o item na mochila se houver lugar. Devolve falso quando a mochila está cheia.
static func give_item(c: HandlerCtx, item: Dictionary) -> bool:
	if c.s.mochila.size() >= c.rules.balance.mochila:
		return false
	c.s.mochila.append(item)
	announce_item(c, item, "mochila")
	return true


static func announce_item(c: HandlerCtx, item: Dictionary, destino: String) -> void:
	var data: Dictionary = {"item_id": item["id"], "nome": item["nome"], "rar": item["rar"]}
	data["destino"] = destino
	c.emit("item_ganho", data)


## Luta o herói contra `enemy`, acrescenta o evento `luta` e os do combate. Devolve se venceu.
static func fight(c: HandlerCtx, enemy: Fighter, contexto: String) -> bool:
	var cfg: Defs.CombatDef = c.rules.balance.combat
	var hero: Fighter = Fighter.make(c.s.nome, c.s.lvl, c.s.total_stats())
	(
		c
		. emit(
			"luta",
			{
				"contexto": contexto,
				"heroi": {"nome": hero.nome, "lvl": hero.lvl, "hp": hero.max_hp(cfg)},
				"inimigo":
				{
					"nome": enemy.nome,
					"lvl": enemy.lvl,
					"hp": enemy.max_hp(cfg),
					"legend_id": enemy.legend_id,
				},
			}
		)
	)
	var result: CombatResult = Combat.simulate(hero, enemy, c.rng, cfg)
	c.events.append_array(result.events)
	return result.win
