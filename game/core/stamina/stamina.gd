class_name Stamina
extends RefCounted
## Energia e coragem: recarga por tempo e gasto. Funções puras; o relógio entra como `now_ms`.


## Recarrega `cur` conforme o tempo desde `upd_ms`. Devolve {cur, upd_ms}.
static func regen(cur: int, upd_ms: int, now_ms: int, max_v: int, step_ms: int) -> Dictionary:
	if now_ms < upd_ms or cur >= max_v or step_ms <= 0:
		# Relógio voltou, ou já está cheio: sem ganho, o relógio de recarga acompanha o agora.
		return {"cur": cur, "upd_ms": now_ms}
	var gain: int = (now_ms - upd_ms) / step_ms
	if gain <= 0:
		return {"cur": cur, "upd_ms": upd_ms}
	return {"cur": mini(max_v, cur + gain), "upd_ms": upd_ms + gain * step_ms}


## Gasta `amount`. Estando cheio, o relógio de recarga reinicia em `now_ms`.
## Sem saldo, nada muda e `ok` é falso. Devolve {cur, upd_ms, ok}.
static func spend(cur: int, upd_ms: int, now_ms: int, max_v: int, amount: int) -> Dictionary:
	if amount > cur:
		return {"cur": cur, "upd_ms": upd_ms, "ok": false}
	var new_upd: int = now_ms if cur >= max_v else upd_ms
	return {"cur": cur - amount, "upd_ms": new_upd, "ok": true}
