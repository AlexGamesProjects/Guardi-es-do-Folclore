class_name StageHandler
extends RefCounted
## `enfrentar_fase`: uma fase da Torre dos Chefes. Vitória avança a fase; derrota dá espera.


static func run(c: HandlerCtx) -> String:
	var s: GameState = c.s
	var act: int = c.arg_int("act")
	var n: int = c.arg_int("n")
	var acts: Array[Defs.ActDef] = c.rules.acts
	if act < 0 or act >= acts.size() or act >= s.fases.size():
		return "FASE_BLOQUEADA"
	if n < 0 or n >= acts[act].stages.size() or n != s.fases[act]:
		return "FASE_BLOQUEADA"
	if s.lvl < Stages.required_level(act, n, c.rules):
		return "NIVEL_INSUFICIENTE"
	if c.now_ms < s.chefe_espera_ms:
		return "EM_RECUPERACAO"
	if not StateOps.spend_energy(c, c.rules.balance.chefe_en):
		return "ENERGIA_INSUFICIENTE"
	var enemy: Fighter = Stages.enemy(act, n, c.rules)
	s.vistos[enemy.legend_id] = true
	if StateOps.fight(c, enemy, "fase"):
		_win(c, act, n, enemy)
	else:
		s.chefe_espera_ms = c.now_ms + c.rules.balance.chefe_espera_ms
	return ""


static func _win(c: HandlerCtx, act: int, n: int, enemy: Fighter) -> void:
	var s: GameState = c.s
	var boss: bool = Stages.is_boss(act, n, c.rules)
	var reward: Dictionary = Stages.reward(act, n, c.rules)
	StateOps.add_vint(c, int(reward["vint"]), "fase")
	s.vitorias[enemy.legend_id] = int(s.vitorias.get(enemy.legend_id, 0)) + 1
	s.fases[act] = n + 1
	c.emit("fase_vencida", {"act": act, "n": n, "boss": boss})
	if boss:
		StateOps.add_muir(c, int(reward["muir"]), "chefe")
		var rarity_min: int = Stages.boss_item_rarity_min(c.rng, c.rules)
		var item: Dictionary = Items.generate(enemy.lvl, "", rarity_min, s.uid, c.rng, c.rules)
		s.uid += 1
		if not StateOps.give_item(c, item):
			StateOps.add_vint(c, int(item["preco"]), "item_vendido")
		c.emit("ato_concluido", {"act": act})
	StateOps.gain_xp(c, int(reward["xp"]))
