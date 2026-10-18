class_name RulesPack
extends RefCounted
## Pacote de regras já validado. Imutável por convenção: quem consome só lê.

var schema_version: int = 0
var rules_version: String = ""
var legends: Dictionary[String, Defs.LegendDef] = {}
var acts: Array[Defs.ActDef] = []
var balance: Defs.BalanceDef = null
var item_names: Dictionary[String, PackedStringArray] = {}
var epithets: PackedStringArray = PackedStringArray()
var rarities: Array[Defs.RarityDef] = []
var rival_first: PackedStringArray = PackedStringArray()
var rival_last: PackedStringArray = PackedStringArray()


## Monta o pacote a partir dos arquivos já lidos e validados (nome do arquivo -> conteúdo).
static func from_files(files: Dictionary) -> RulesPack:
	var out := RulesPack.new()
	var manifest: Dictionary = files["manifest.json"]
	out.schema_version = int(manifest["schema_version"])
	out.rules_version = str(manifest["rules_version"])
	var legend_list: Array = files["legends.json"]["legends"]
	for d: Variant in legend_list:
		var legend: Defs.LegendDef = Defs.LegendDef.from_dict(d)
		out.legends[legend.id] = legend
	var act_list: Array = files["acts.json"]["acts"]
	for d: Variant in act_list:
		out.acts.append(Defs.ActDef.from_dict(d))
	out.balance = Defs.BalanceDef.from_dict(files["balance.json"])
	var items: Dictionary = files["items.json"]
	var names: Dictionary = items["item_names"]
	for slot: Variant in names:
		out.item_names[str(slot)] = PackedStringArray(names[slot])
	out.epithets = PackedStringArray(items["epithets"])
	var rarity_list: Array = items["rarities"]
	for d: Variant in rarity_list:
		out.rarities.append(Defs.RarityDef.from_dict(d))
	var rivals: Dictionary = files["rivals.json"]
	out.rival_first = PackedStringArray(rivals["first"])
	out.rival_last = PackedStringArray(rivals["last"])
	return out
