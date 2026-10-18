class_name ItemLinha
extends PanelContainer
## Um item: nome, raridade (com cor), atributos e a diferença para o equipado no mesmo slot.

const CORES_RARIDADE: Array[Color] = [
	Color("efe7d4"), Color("3fae7f"), Color("6fa8dc"), Color("d6a24a")
]
const NOMES_ATRIBUTO: Dictionary[String, String] = {
	"for": "Força", "fol": "Fôlego", "mal": "Malícia", "gin": "Ginga"
}
const NOMES_SLOT: Dictionary[String, String] = {
	"cabeca": "Cabeça", "corpo": "Corpo", "arma": "Arma", "amuleto": "Amuleto"
}

## Linha de botões da tela que usa o item (comprar, equipar, vender).
var acoes: HBoxContainer
var _caixa: VBoxContainer


func _init() -> void:
	theme_type_variation = &"Cartao"
	_caixa = VBoxContainer.new()
	add_child(_caixa)
	acoes = HBoxContainer.new()
	acoes.add_theme_constant_override("separation", 12)


## Mostra `item`; `equipado` é o item no mesmo slot (ou vazio) para comparar.
func mostrar(item: Dictionary, equipado: Dictionary, rules: RulesPack) -> void:
	for filho: Node in _caixa.get_children():
		_caixa.remove_child(filho)
		if filho != acoes:
			filho.queue_free()
	var id: int = int(item["id"])
	var rar: int = clampi(int(item["rar"]), 0, CORES_RARIDADE.size() - 1)
	var nome := AbaBase.rotulo(str(item["nome"]), &"Valor", "ItemNome_%d" % id)
	nome.add_theme_color_override("font_color", CORES_RARIDADE[rar])
	_caixa.add_child(nome)
	var nome_rar: String = rules.rarities[rar].nome if rar < rules.rarities.size() else ""
	var linha_rar := AbaBase.rotulo(nome_rar, &"Dica", "ItemRaridade_%d" % id)
	linha_rar.add_theme_color_override("font_color", CORES_RARIDADE[rar])
	_caixa.add_child(linha_rar)
	_caixa.add_child(
		AbaBase.rotulo(
			"%s · %s" % [NOMES_SLOT.get(str(item["slot"]), ""), _atributos(item)], &"Dica"
		)
	)
	_caixa.add_child(AbaBase.rotulo(_diferenca(item, equipado), &"Dica", "ItemDiferenca_%d" % id))
	_caixa.add_child(acoes)


static func _atributos(item: Dictionary) -> String:
	var st: Dictionary = item.get("st", {})
	var partes: Array[String] = []
	for k: String in Defs.STAT_KEYS:
		if int(st.get(k, 0)) != 0:
			partes.append("+%d %s" % [int(st[k]), NOMES_ATRIBUTO[k]])
	return ", ".join(partes)


static func _diferenca(item: Dictionary, equipado: Dictionary) -> String:
	if equipado.is_empty():
		return "Slot vazio: tudo é ganho."
	var a: Dictionary = item.get("st", {})
	var b: Dictionary = equipado.get("st", {})
	var partes: Array[String] = []
	for k: String in Defs.STAT_KEYS:
		var d: int = int(a.get(k, 0)) - int(b.get(k, 0))
		if d > 0:
			partes.append("+%d %s" % [d, NOMES_ATRIBUTO[k]])
		elif d < 0:
			partes.append("−%d %s" % [-d, NOMES_ATRIBUTO[k]])
	return "Igual ao equipado." if partes.is_empty() else "Contra o equipado: " + ", ".join(partes)
