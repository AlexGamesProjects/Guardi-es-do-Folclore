class_name BagHandler
extends RefCounted
## `equipar`, `desequipar` e `vender`.


static func equip(c: HandlerCtx) -> String:
	var s: GameState = c.s
	var i: int = StateOps.index_of(s.mochila, c.arg_int("item_id"))
	if i < 0 or not Defs.SLOT_KEYS.has(str(s.mochila[i]["slot"])):
		return "NAO_ENCONTRADO"
	var item: Dictionary = s.mochila[i]
	s.mochila.remove_at(i)
	var slot: String = str(item["slot"])
	var old: Variant = s.equip.get(slot)
	s.equip[slot] = item
	if old is Dictionary:
		s.mochila.append(old)
	return ""


static func unequip(c: HandlerCtx) -> String:
	var s: GameState = c.s
	var slot: String = c.arg_str("slot")
	var item: Variant = s.equip.get(slot)
	if not Defs.SLOT_KEYS.has(slot) or not item is Dictionary:
		return "NAO_ENCONTRADO"
	if s.mochila.size() >= c.rules.balance.mochila:
		return "MOCHILA_CHEIA"
	s.mochila.append(item)
	s.equip[slot] = null
	return ""


static func sell(c: HandlerCtx) -> String:
	var s: GameState = c.s
	var i: int = StateOps.index_of(s.mochila, c.arg_int("item_id"))
	if i < 0:
		return "NAO_ENCONTRADO"
	var item: Dictionary = s.mochila[i]
	s.mochila.remove_at(i)
	var pm: int = int(c.rules.balance.item["sell_pm"])
	StateOps.add_vint(c, IntMath.div_round(int(item["preco"]) * pm, 1000), "venda")
	return ""
