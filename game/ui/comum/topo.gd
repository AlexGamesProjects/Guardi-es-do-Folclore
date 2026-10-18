class_name Topo
extends PanelContainer
## Faixa fixa do topo: herói (abre o treino), nível e XP, vinténs, muiraquitãs, energia e coragem.

signal heroi_tocado

var _nome: Label
var _nivel: Label
var _xp: ProgressBar
var _vint: Label
var _muir: Label
var _energia: Label
var _en_prox: Label
var _coragem: Label
var _co_prox: Label


func _ready() -> void:
	name = "Topo"
	theme_type_variation = &"Cartao"
	var linhas := VBoxContainer.new()
	add_child(linhas)
	var l1 := HBoxContainer.new()
	linhas.add_child(l1)
	var heroi := Button.new()
	heroi.name = "Heroi"
	heroi.text = "Treinar"
	heroi.theme_type_variation = &"BotaoPlano"
	heroi.custom_minimum_size = Vector2(150, 88)
	heroi.pressed.connect(func() -> void: heroi_tocado.emit())
	l1.add_child(heroi)
	var id := VBoxContainer.new()
	id.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l1.add_child(id)
	_nome = _rotulo("NomeHeroi", &"Valor", id)
	_nivel = _rotulo("Nivel", &"Dica", id)
	_xp = ProgressBar.new()
	_xp.name = "XP"
	_xp.show_percentage = false
	_xp.custom_minimum_size = Vector2(0, 10)
	id.add_child(_xp)
	var moedas := VBoxContainer.new()
	l1.add_child(moedas)
	_vint = _rotulo("Vintens", &"Valor", moedas)
	_muir = _rotulo("Muiraquitas", &"Dica", moedas)
	var l2 := HBoxContainer.new()
	linhas.add_child(l2)
	_energia = _rotulo("EnergiaValor", &"Valor", _par(l2, "Energia"))
	_en_prox = _rotulo("EnergiaProx", &"Dica", _energia.get_parent())
	_coragem = _rotulo("CoragemValor", &"Valor", _par(l2, "Coragem"))
	_co_prox = _rotulo("CoragemProx", &"Dica", _coragem.get_parent())
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(atualizar)
	add_child(timer)
	var service: Node = _service()
	if service != null:
		service.connect("state_changed", func(_s: GameState) -> void: atualizar())
	atualizar()


func atualizar() -> void:
	var service: Node = _service()
	var state: GameState = null if service == null else service.call("get_state")
	if state == null:
		return
	var rules: RulesPack = service.call("get_rules")
	_nome.text = state.nome
	_nivel.text = "Nível %d" % state.lvl
	if rules != null:
		var tabela: PackedInt64Array = rules.balance.xp_table
		var prox: int = int(tabela[mini(state.lvl, tabela.size() - 1)])
		_xp.max_value = maxi(prox, 1)
		_xp.value = state.xp
	_vint.text = "%d vinténs" % state.vint
	_muir.text = "%d muiraquitãs" % state.muir
	var view: Dictionary = service.call("stamina_view")
	if view.is_empty():
		return
	_energia.text = "%d/%d" % [int(view["energia"]), int(view["en_max"])]
	_en_prox.text = _prox(int(view["en_next_ms"]))
	_coragem.text = "%d/%d" % [int(view["coragem"]), int(view["co_max"])]
	_co_prox.text = _prox(int(view["co_next_ms"]))


static func _prox(ms: int) -> String:
	return "cheia" if ms <= 0 else "+1 em %s" % Textos.relogio(ms)


static func _par(pai: Container, titulo: String) -> VBoxContainer:
	var caixa := VBoxContainer.new()
	caixa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pai.add_child(caixa)
	var t := Label.new()
	t.text = titulo
	t.theme_type_variation = &"Dica"
	caixa.add_child(t)
	return caixa


static func _rotulo(nome: String, variacao: StringName, pai: Node) -> Label:
	var r := Label.new()
	r.name = nome
	r.theme_type_variation = variacao
	r.clip_text = true
	r.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	pai.add_child(r)
	return r


func _service() -> Node:
	return get_node_or_null("/root/GameService")
