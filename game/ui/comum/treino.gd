class_name PainelTreino
extends PanelContainer
## Treino dos 4 atributos, aberto ao tocar no herói. Mostra o custo e manda `treinar`.

const NOMES: Dictionary[String, String] = {
	"for": "Força", "fol": "Fôlego", "mal": "Malícia", "gin": "Ginga"
}

var _botoes: Dictionary[String, Button] = {}
var _guardiao: Guardiao


func _ready() -> void:
	name = "Treino"
	theme_type_variation = &"Cartao"
	var caixa := VBoxContainer.new()
	caixa.add_theme_constant_override("separation", 12)
	add_child(caixa)
	var titulo := Label.new()
	titulo.text = "Treino"
	titulo.theme_type_variation = &"Titulo"
	caixa.add_child(titulo)
	_guardiao = Guardiao.new()
	_guardiao.name = "GuardiaoTreino"
	_guardiao.escala = 2
	_guardiao.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	caixa.add_child(_guardiao)
	for stat: String in Defs.STAT_KEYS:
		var botao := Button.new()
		botao.name = "Treinar_" + stat
		botao.custom_minimum_size = Vector2(0, 88)
		botao.pressed.connect(_treinar.bind(stat))
		caixa.add_child(botao)
		_botoes[stat] = botao
	var fechar := Button.new()
	fechar.name = "FecharTreino"
	fechar.text = "Fechar"
	fechar.theme_type_variation = &"BotaoPlano"
	fechar.custom_minimum_size = Vector2(0, 88)
	fechar.pressed.connect(hide)
	caixa.add_child(fechar)
	var service: Node = _service()
	if service != null:
		service.connect("state_changed", func(_s: GameState) -> void: atualizar())
		service.connect("busy_changed", func(_b: bool) -> void: atualizar())
	atualizar()


func atualizar() -> void:
	var service: Node = _service()
	var state: GameState = null if service == null else service.call("get_state")
	var rules: RulesPack = null if service == null else service.call("get_rules")
	var busy: bool = service != null and bool(service.call("is_busy"))
	if state != null and rules != null:
		_guardiao.aplicar_visual(state.visual)
		_guardiao.vestir(state.equip, rules)
	for stat: String in _botoes:
		var botao: Button = _botoes[stat]
		if state == null or rules == null:
			botao.text = NOMES[stat]
			botao.disabled = true
			continue
		var valor: int = state.stats[stat]
		botao.text = (
			"%s %d · custa %d vinténs" % [NOMES[stat], valor, Progression.train_cost(valor, rules)]
		)
		botao.disabled = busy


func _treinar(stat: String) -> void:
	var service: Node = _service()
	if service == null or bool(service.call("is_busy")):
		return
	var res: CommandResult = await service.call("send", "treinar", {"stat": stat})
	if res.ok:
		Toast.avisar(self, "%s subiu para %d." % [NOMES[stat], res.state.stats[stat]], "ok")
	else:
		Toast.avisar(self, Textos.erro(res.error, "treino"), "erro")


func _service() -> Node:
	return get_node_or_null("/root/GameService")
