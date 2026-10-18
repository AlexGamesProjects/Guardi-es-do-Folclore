class_name AbaBase
extends MarginContainer
## Base das abas: acesso ao `GameService`, envio de comando com aviso de erro no Toast e
## redesenho quando o estado ou o "ocupado" mudam. As abas só implementam `_montar` e `atualizar`.

## Contexto dos textos de erro (`Textos.erro`).
var contexto: String = "geral"
var _corpo: VBoxContainer


func _ready() -> void:
	for lado: String in ["left", "right", "top", "bottom"]:
		add_theme_constant_override("margin_" + lado, 20)
	var rolagem := ScrollContainer.new()
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(rolagem)
	_corpo = VBoxContainer.new()
	_corpo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_corpo.add_theme_constant_override("separation", 16)
	rolagem.add_child(_corpo)
	_montar(_corpo)
	var service: Node = servico()
	if service != null:
		service.connect("state_changed", func(_s: GameState) -> void: atualizar())
		service.connect("busy_changed", func(_b: bool) -> void: atualizar())
	visibility_changed.connect(_on_visibilidade)
	atualizar()


func _on_visibilidade() -> void:
	if visible:
		atualizar()


## Cria os nós fixos da aba dentro de `corpo`.
func _montar(_corpo_aba: VBoxContainer) -> void:
	pass


## Redesenha a aba a partir do estado atual.
func atualizar() -> void:
	pass


func servico() -> Node:
	return get_node_or_null("/root/GameService")


func estado() -> GameState:
	var s: Node = servico()
	return null if s == null else s.call("get_state")


func regras() -> RulesPack:
	var s: Node = servico()
	return null if s == null else s.call("get_rules")


func ocupado() -> bool:
	var s: Node = servico()
	return s != null and bool(s.call("is_busy"))


func agora_ms() -> int:
	var s: Node = servico()
	if s == null:
		return 0
	var view: Dictionary = s.call("stamina_view")
	return int(view.get("now_ms", 0))


## Manda o comando; em erro mostra o texto do contexto no Toast. Devolve o resultado (ou null).
func enviar(tipo: String, params: Dictionary = {}) -> CommandResult:
	var s: Node = servico()
	if s == null or ocupado():
		return null
	var res: CommandResult = await s.call("send", tipo, params)
	if not res.ok:
		Toast.avisar(self, Textos.erro(res.error, contexto), "erro")
	return res


static func botao(nome: String, texto: String, principal: bool = false) -> Button:
	var b := Button.new()
	b.name = nome
	b.text = texto
	b.custom_minimum_size = Vector2(0, 88)
	b.theme_type_variation = &"BotaoPrincipal" if principal else &"BotaoPlano"
	return b


static func rotulo(texto: String, variacao: StringName = &"", nome: String = "") -> Label:
	var r := Label.new()
	if nome != "":
		r.name = nome
	r.text = texto
	r.theme_type_variation = variacao
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return r


static func cartao() -> PanelContainer:
	var p := PanelContainer.new()
	p.theme_type_variation = &"Cartao"
	return p
