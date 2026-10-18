class_name ShopHandler
extends RefCounted
## `comprar` e `renovar_feira`.


static func buy(c: HandlerCtx) -> String:
	var s: GameState = c.s
	var i: int = StateOps.index_of(s.feira, c.arg_int("item_id"))
	if i < 0:
		return "NAO_ENCONTRADO"
	var item: Dictionary = s.feira[i]
	if s.vint < int(item["preco"]):
		return "VINTENS_INSUFICIENTES"
	var slot: String = str(item["slot"])
	var free_slot: bool = s.equip.get(slot) == null
	if not free_slot and s.mochila.size() >= c.rules.balance.mochila:
		return "MOCHILA_CHEIA"
	s.vint -= int(item["preco"])
	s.feira.remove_at(i)
	if free_slot:
		s.equip[slot] = item
		StateOps.announce_item(c, item, "equipado")
	else:
		StateOps.give_item(c, item)
	return ""


static func renew(c: HandlerCtx) -> String:
	var cost: int = int(c.rules.balance.item["reroll_muir"])
	if c.s.muir < cost:
		return "MUIRAQUITAS_INSUFICIENTES"
	c.s.muir -= cost
	Refill.renew_shop(c.s, c.now_ms, c.rng, c.rules)
	return ""
