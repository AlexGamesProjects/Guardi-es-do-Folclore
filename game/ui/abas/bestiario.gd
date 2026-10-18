extends AbaBase
## Bestiário: carta (pintura) e história de cada lenda. Fica "desconhecida" até ser enfrentada;
## lendas aliadas (o Negrinho do Pastoreio) aparecem desde o começo.

var _cards: Dictionary[String, Dictionary] = {}


func _montar(corpo: VBoxContainer) -> void:
	corpo.add_child(rotulo("Bestiário", &"Titulo"))
	var r: RulesPack = regras()
	if r == null:
		return
	for id: String in r.legends:
		var lenda: Defs.LegendDef = r.legends[id]
		var painel := cartao()
		painel.name = "Lenda_" + id
		var caixa := HBoxContainer.new()
		caixa.add_theme_constant_override("separation", 16)
		painel.add_child(caixa)
		var img := TextureRect.new()
		img.custom_minimum_size = Vector2(200, 268)
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		img.texture = CartaLib.textura(id)
		caixa.add_child(img)
		var textos := VBoxContainer.new()
		textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		caixa.add_child(textos)
		var nome := rotulo("", &"Valor", "LendaNome_" + id)
		textos.add_child(nome)
		var lugar := rotulo("", &"Dica")
		textos.add_child(lugar)
		var lore := rotulo("", &"")
		lore.add_theme_font_size_override("font_size", 22)
		textos.add_child(lore)
		corpo.add_child(painel)
		_cards[id] = {"img": img, "nome": nome, "lugar": lugar, "lore": lore, "lenda": lenda}


func atualizar() -> void:
	var s: GameState = estado()
	if s == null:
		return
	for id: String in _cards:
		var c: Dictionary = _cards[id]
		var lenda: Defs.LegendDef = c["lenda"]
		var conhecida: bool = lenda.ally or bool(s.vistos.get(id, false))
		(c["nome"] as Label).text = lenda.nome if conhecida else "Lenda desconhecida"
		(c["lugar"] as Label).text = (
			"%s · aparece no nível %d" % [lenda.lugar, lenda.lvl]
			if conhecida
			else "Enfrente-a para conhecer."
		)
		(c["lore"] as Label).text = lenda.lore if conhecida else ""
		(c["img"] as TextureRect).modulate = Color.WHITE if conhecida else Color(0.08, 0.06, 0.05)
