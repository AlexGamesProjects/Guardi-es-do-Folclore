class_name DuelHandler
extends RefCounted
## `desafiar`: duelo na Arena. Vitória dá honra, vinténs e XP; derrota tira honra.


static func run(c: HandlerCtx) -> String:
	var s: GameState = c.s
	var i: int = StateOps.index_of(s.rivais, c.arg_int("rival_id"))
	if i < 0:
		return "NAO_ENCONTRADO"
	var cfg: Dictionary = c.rules.balance.arena
	if not StateOps.spend_courage(c, int(cfg["coragem"])):
		return "CORAGEM_INSUFICIENTE"
	var rival: Dictionary = s.rivais[i]
	s.rivais.remove_at(i)
	var enemy: Fighter = Fighter.make(str(rival["nome"]), int(rival["lvl"]), rival["st"])
	var win: bool = StateOps.fight(c, enemy, "arena")
	var delta: int
	if win:
		var gap: int = (enemy.lvl - s.lvl) * int(cfg["win_honra_lvl"])
		delta = maxi(int(cfg["win_honra_min"]), int(cfg["win_honra_base"]) + gap)
	else:
		delta = -mini(s.honra, int(cfg["loss_honra_max"]))
	s.honra += delta
	c.emit("honra_alterada", {"delta": delta, "honra": s.honra})
	s.duelos.push_front({"nome": enemy.nome, "win": win, "honra": delta})
	while s.duelos.size() > int(cfg["history"]):
		s.duelos.pop_back()
	if win:
		StateOps.add_vint(c, int(cfg["win_vint_base"]) + s.lvl * int(cfg["win_vint_lvl"]), "arena")
		StateOps.gain_xp(c, int(cfg["win_xp_base"]) + s.lvl * int(cfg["win_xp_lvl"]))
	return ""
