class_name MissionBoostHandler
extends RefCounted
## `acelerar_missao` e `renovar_missoes`: gastam muiraquitãs.


static func speed_up(c: HandlerCtx) -> String:
	var s: GameState = c.s
	if s.ativa.is_empty():
		return "SEM_MISSAO"
	var cost: int = int(c.rules.balance.mission["skip_muir"])
	if s.muir < cost:
		return "MUIRAQUITAS_INSUFICIENTES"
	s.muir -= cost
	s.ativa["fim_ms"] = mini(int(s.ativa["fim_ms"]), c.now_ms)
	return ""


## Descarta as ofertas; o roteador gera as novas.
static func renew(c: HandlerCtx) -> String:
	var cost: int = int(c.rules.balance.mission["reroll_muir"])
	if c.s.muir < cost:
		return "MUIRAQUITAS_INSUFICIENTES"
	c.s.muir -= cost
	c.s.ofertas.clear()
	return ""
