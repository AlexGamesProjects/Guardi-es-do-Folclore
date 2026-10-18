class_name MissionFinishHandler
extends RefCounted
## `concluir_missao`: luta (se for de luta), paga os prêmios e pode soltar um item.


static func run(c: HandlerCtx) -> String:
	var s: GameState = c.s
	if s.ativa.is_empty():
		return "SEM_MISSAO"
	var m: Dictionary = s.ativa
	if c.now_ms < int(m["fim_ms"]):
		return "MISSAO_EM_ANDAMENTO"
	s.ativa = {}
	s.missoes += 1
	var legend_id: String = str(m["c"])
	var legend: Defs.LegendDef = c.rules.legends.get(legend_id)
	# Lenda aliada nunca luta, mesmo que a missão diga o contrário.
	var fights: bool = bool(m["luta"]) and legend != null and not legend.ally
	var win: bool = true
	if fights:
		var enemy: Fighter = Missions.enemy_for(m, s.total_stats(), s.lvl, c.rng, c.rules)
		win = StateOps.fight(c, enemy, "missao")
	c.emit("missao_concluida", {"mission_id": m["id"], "c": legend_id, "luta": fights, "win": win})
	if win:
		StateOps.add_vint(c, int(m["vint"]), "missao")
		if fights:
			s.vitorias[legend_id] = int(s.vitorias.get(legend_id, 0)) + 1
		_drop(c)
		StateOps.gain_xp(c, int(m["xp"]))
	else:
		var pm: int = int(c.rules.balance.mission["defeat_xp_pm"])
		StateOps.gain_xp(c, IntMath.div_round(int(m["xp"]) * pm, 1000))
	return ""


static func _drop(c: HandlerCtx) -> void:
	var rolled: bool = c.rng.roll_bp(int(c.rules.balance.mission["drop_bp"]))
	if not rolled or c.s.mochila.size() >= c.rules.balance.mochila:
		return
	var item: Dictionary = Items.generate(c.s.lvl, "", 0, c.s.uid, c.rng, c.rules)
	c.s.uid += 1
	StateOps.give_item(c, item)
