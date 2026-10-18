class_name HeroiVisual
extends RefCounted
## Liga um item ao desenho que o guardião veste: procura o nome-base mais longo (de
## `RulesPack.visuais`) no começo do nome do item, que pode trazer epíteto ("da Serra").


static func para_item(item: Dictionary, rules: RulesPack) -> String:
	var nome: String = str(item.get("nome", ""))
	if nome == "" or rules == null:
		return ""
	var melhor: String = ""
	for base: String in rules.visuais:
		if nome.begins_with(base) and base.length() > melhor.length():
			melhor = base
	return rules.visuais[melhor] if melhor != "" else ""
