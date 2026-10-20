extends AbaBase
## Mochila: o que está equipado em cada slot (com desequipar) e os itens guardados
## (equipar, vender).

var _equipados: VBoxContainer
var _lista: VBoxContainer
var _boneco: Boneco


func _montar(corpo: VBoxContainer) -> void:
	contexto = "mochila"
	corpo.add_child(rotulo("Mochila", &"Titulo"))
	_boneco = Boneco.new()
	_boneco.name = "BonecoMochila"
	_boneco.escala = 3
	_boneco.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	corpo.add_child(_boneco)
	corpo.add_child(rotulo("Equipado", &"Subtitulo"))
	_equipados = VBoxContainer.new()
	corpo.add_child(_equipados)
	corpo.add_child(rotulo("Guardado", &"Subtitulo"))
	_lista = VBoxContainer.new()
	_lista.add_theme_constant_override("separation", 12)
	corpo.add_child(_lista)


func atualizar() -> void:
	var s: GameState = estado()
	var r: RulesPack = regras()
	if s == null or r == null or _lista == null:
		return
	var busy: bool = ocupado()
	_boneco.vestir(s.equip, r)
	for caixa: VBoxContainer in [_equipados, _lista]:
		for filho: Node in caixa.get_children():
			caixa.remove_child(filho)
			filho.queue_free()
	for slot: String in Defs.SLOT_KEYS:
		var eq: Variant = s.equip.get(slot)
		if not eq is Dictionary:
			_equipados.add_child(rotulo("%s: vazio" % ItemLinha.NOMES_SLOT[slot], &"Dica"))
			continue
		var linha := ItemLinha.new()
		linha.mostrar(eq, eq, r)
		var b := botao("Desequipar_%s" % slot, "Desequipar")
		b.disabled = busy
		b.pressed.connect(func() -> void: enviar("desequipar", {"slot": slot}))
		linha.acoes.add_child(b)
		_equipados.add_child(linha)
	if s.mochila.is_empty():
		_lista.add_child(rotulo("A mochila está vazia. Compre na Feira ou vença chefes.", &"Dica"))
	for item: Dictionary in s.mochila:
		var linha := ItemLinha.new()
		var eq2: Variant = s.equip.get(str(item["slot"]))
		linha.mostrar(item, eq2 if eq2 is Dictionary else {}, r)
		var id: int = int(item["id"])
		var equipar := botao("Equipar_%d" % id, "Equipar", true)
		equipar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		equipar.disabled = busy
		equipar.pressed.connect(func() -> void: enviar("equipar", {"item_id": id}))
		linha.acoes.add_child(equipar)
		var vender := botao("Vender_%d" % id, "Vender")
		vender.disabled = busy
		vender.pressed.connect(func() -> void: enviar("vender", {"item_id": id}))
		linha.acoes.add_child(vender)
		_lista.add_child(linha)
