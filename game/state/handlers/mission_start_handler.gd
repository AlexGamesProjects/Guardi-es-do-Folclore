class_name MissionStartHandler
extends RefCounted
## `iniciar_missao`: gasta a energia e põe a oferta em andamento.


static func run(c: HandlerCtx) -> String:
	var s: GameState = c.s
	if not s.ativa.is_empty():
		return "MISSAO_ATIVA"
	var i: int = StateOps.index_of(s.ofertas, c.arg_int("mission_id"))
	if i < 0:
		return "NAO_ENCONTRADO"
	var m: Dictionary = s.ofertas[i]
	if not StateOps.spend_energy(c, int(m["en"])):
		return "ENERGIA_INSUFICIENTE"
	var active: Dictionary = m.duplicate(true)
	active["fim_ms"] = c.now_ms + int(m["dur"]) * 1000
	s.ativa = active
	s.ofertas.remove_at(i)
	return ""
