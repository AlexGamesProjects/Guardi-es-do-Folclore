extends AbaBase
## Aba Feira: itens à venda com raridade e comparação com o equipado; renovar a feira.

var _lista: VBoxContainer
var _renovar: Button


func _montar(corpo: VBoxContainer) -> void:
	contexto = "feira"
	corpo.add_child(rotulo("Feira", &"Titulo"))
	_lista = VBoxContainer.new()
	_lista.add_theme_constant_override("separation", 12)
	corpo.add_child(_lista)
	_renovar = botao("RenovarFeira", "Renovar a feira (1 muiraquitã)")
	_renovar.pressed.connect(func() -> void: enviar("renovar_feira"))
	corpo.add_child(_renovar)


func atualizar() -> void:
	var s: GameState = estado()
	var r: RulesPack = regras()
	if s == null or r == null or _lista == null:
		return
	for filho: Node in _lista.get_children():
		_lista.remove_child(filho)
		filho.queue_free()
	var busy: bool = ocupado()
	for item: Dictionary in s.feira:
		var linha := ItemLinha.new()
		var eq: Variant = s.equip.get(str(item["slot"]))
		linha.mostrar(item, eq if eq is Dictionary else {}, r)
		var id: int = int(item["id"])
		var b := botao("Comprar_%d" % id, "Comprar por %d vinténs" % int(item["preco"]), true)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.disabled = busy
		b.pressed.connect(func() -> void: enviar("comprar", {"item_id": id}))
		linha.acoes.add_child(b)
		_lista.add_child(linha)
	_renovar.disabled = busy
