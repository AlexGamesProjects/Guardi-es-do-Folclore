class_name Items
extends RefCounted
## Geração de itens (loja, drops, recompensa de chefe). Funções puras.

const _PM: int = 1000
const _PM2: int = 1000000


## Item {id, slot, nome, rar, st, preco}. `slot` vazio sorteia o espaço. `rarity_min` é o piso.
## Ordem dos sorteios (igual à v0.2): espaço, raridade, atributo secundário, nome, epíteto.
static func generate(
	lvl: int, slot: String, rarity_min: int, uid: int, rng: Rng, rules: RulesPack
) -> Dictionary:
	var cfg: Dictionary = rules.balance.item
	var primary: Dictionary = cfg["primary"]
	var chosen: String = slot
	if chosen == "":
		var slots: Array = primary.keys()
		chosen = str(rng.pick(slots))
	var rar: int = maxi(_roll_rarity(rng, cfg), rarity_min)
	var mult_pm: int = rules.rarities[rar].mult_pm
	var raw: int = int(cfg["pts_base"]) * _PM + lvl * int(cfg["pts_lvl_pm"])
	var pts: int = IntMath.div_round(raw * mult_pm, _PM2)
	var main_stat: String = str(primary[chosen])
	var main_value: int = (pts * int(cfg["prim_pm"]) + _PM - 1) / _PM
	var others: Array = []
	for k: String in Defs.STAT_KEYS:
		if k != main_stat:
			others.append(k)
	var st: Dictionary = {main_stat: main_value}
	st[str(rng.pick(others))] = pts - main_value
	var names: PackedStringArray = rules.item_names[chosen]
	var nome: String = names[rng.next_int(names.size())]
	if rar > 0:
		nome += " " + rules.epithets[rng.next_int(rules.epithets.size())]
	var price_mult: int = _PM + lvl * int(cfg["price_lvl_pm"])
	var preco: int = IntMath.div_round(pts * int(cfg["price_pt"]) * price_mult, _PM)
	return {"id": uid, "slot": chosen, "nome": nome, "rar": rar, "st": st, "preco": preco}


## 2 = lendária, 1 = rara, 0 = comum. Uma única jogada de 0 a 9999.
static func _roll_rarity(rng: Rng, cfg: Dictionary) -> int:
	var roll: int = rng.next_int(10000)
	var legendary: int = int(cfg["legendary_bp"])
	if roll < legendary:
		return 2
	if roll < legendary + int(cfg["rare_bp"]):
		return 1
	return 0
