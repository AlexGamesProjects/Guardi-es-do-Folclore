extends AbaBase
## Criação do guardião: nome, visual (EditorVisual) e uma das 4 origens (cada uma dá +2 num
## atributo). Manda `criar_guardiao` e, dando certo, abre o jogo.

const JOGO_SCENE: String = "res://ui/jogo.tscn"
const FUNDO: Texture2D = preload("res://ui/fundo.tres")

## Troca de cena (os testes substituem).
var abrir_cena: Callable = func(p: String) -> void: get_tree().change_scene_to_file(p)
var _nome: LineEdit
var _origem: String = ""
var _botoes: Dictionary[String, Button] = {}
var _criar: Button
var _editor: EditorVisual


func _montar(corpo: VBoxContainer) -> void:
	corpo.add_child(Toast.new())
	corpo.add_child(rotulo("Seu guardião", &"Titulo"))
	corpo.add_child(rotulo("Como você se chama?", &"Subtitulo"))
	_nome = LineEdit.new()
	_nome.name = "NomeGuardiao"
	_nome.custom_minimum_size = Vector2(0, 88)
	_nome.placeholder_text = "Jaci"
	var r: RulesPack = regras()
	if r != null:
		_nome.max_length = int(r.balance.start.get("nome_max", 18))
	corpo.add_child(_nome)
	corpo.add_child(rotulo("Como você é?", &"Subtitulo"))
	_editor = EditorVisual.new()
	corpo.add_child(_editor)
	corpo.add_child(rotulo("De onde você vem?", &"Subtitulo"))
	if r == null:
		return
	for id: String in r.balance.origens:
		var info: Dictionary = r.balance.origens[id]
		var b := botao("Origem_" + id, "%s · %s" % [str(info["nome"]), _bonus(info)])
		b.toggle_mode = true
		b.theme_type_variation = &""
		b.custom_minimum_size = Vector2(0, 100)
		b.pressed.connect(_escolher.bind(id))
		corpo.add_child(b)
		_botoes[id] = b
	_criar = botao("Criar", "Começar a jornada", true)
	_criar.pressed.connect(_criar_guardiao)
	corpo.add_child(_criar)


func _draw() -> void:
	draw_texture_rect(FUNDO, Rect2(Vector2.ZERO, size), false)


func atualizar() -> void:
	if _criar == null:
		return
	_criar.disabled = _origem == "" or ocupado()
	for id: String in _botoes:
		_botoes[id].set_pressed_no_signal(id == _origem)
		_botoes[id].theme_type_variation = &"BotaoPrincipal" if id == _origem else &""


func _escolher(id: String) -> void:
	_origem = id
	atualizar()


func _criar_guardiao() -> void:
	if _origem == "":
		return
	var nome: String = _nome.text if _nome.text.strip_edges() != "" else _nome.placeholder_text
	var params: Dictionary = {"nome": nome, "origem": _origem, "visual": _editor.visual()}
	var res: CommandResult = await enviar("criar_guardiao", params)
	if res != null and res.ok:
		abrir_cena.call(JOGO_SCENE)


static func _bonus(info: Dictionary) -> String:
	for k: String in Defs.STAT_KEYS:
		if info.has(k):
			return "+%d %s" % [int(info[k]), ItemLinha.NOMES_ATRIBUTO[k]]
	return ""
