class_name Toast
extends PanelContainer
## Aviso curto comum a todas as telas (erros de comando e avisos de save). Some sozinho.

const DURACAO_S: float = 3.5

var _texto: Label
var _timer: Timer


func _ready() -> void:
	add_to_group("toast")
	name = "Toast"
	theme_type_variation = &"Aviso"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_texto = Label.new()
	_texto.name = "ToastTexto"
	_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto.add_theme_font_size_override("font_size", 26)
	add_child(_texto)
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(hide)
	add_child(_timer)
	hide()


## Mostra `texto`; `tipo` é "ok", "erro" ou "aviso".
func mostrar(texto: String, tipo: String) -> void:
	_texto.text = texto
	_texto.theme_type_variation = &"Sucesso" if tipo == "ok" else &"Erro" if tipo == "erro" else &""
	show()
	_timer.start(DURACAO_S)


## Atalho para qualquer tela: usa o Toast da casca, se houver.
static func avisar(origem: Node, texto: String, tipo: String = "erro") -> void:
	if origem == null or not origem.is_inside_tree():
		return
	var alvo: Node = origem.get_tree().get_first_node_in_group("toast")
	if alvo != null:
		alvo.call("mostrar", texto, tipo)
