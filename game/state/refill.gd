class_name Refill
extends RefCounted
## Reabastece ofertas de missão, rivais e feira (a `garantir()` da v0.2).


static func ensure(s: GameState, now_ms: int, rng: Rng, rules: RulesPack) -> void:
	var offers: int = int(rules.balance.mission["offers"])
	while s.ofertas.size() < offers:
		var m: Dictionary = Missions.generate(s.lvl, s.uid, rng, rules)
		s.uid += 1
		s.vistos[str(m["c"])] = true
		s.ofertas.append(m)
	var rivals: int = int(rules.balance.rival["count"])
	while s.rivais.size() < rivals:
		var r: Dictionary = Rivals.generate(s.lvl, s.total_stats(), s.honra, s.uid, rng, rules)
		s.uid += 1
		s.rivais.append(r)
	if s.feira.is_empty() or now_ms - s.feira_upd_ms > rules.balance.feira_ms:
		renew_shop(s, now_ms, rng, rules)


## A feira tem um item de cada espaço e o resto sorteado, até `shop_size`.
static func renew_shop(s: GameState, now_ms: int, rng: Rng, rules: RulesPack) -> void:
	var size: int = int(rules.balance.item["shop_size"])
	var slots: Array = Array(Defs.SLOT_KEYS)
	s.feira.clear()
	for i: int in size:
		var slot: String = str(slots[i]) if i < slots.size() else str(rng.pick(slots))
		s.feira.append(Items.generate(s.lvl, slot, 0, s.uid, rng, rules))
		s.uid += 1
	s.feira_upd_ms = now_ms
