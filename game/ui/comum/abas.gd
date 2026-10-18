class_name BarraAbas
extends PanelContainer
## Rodapé com as 5 abas. Emite `escolhida(id)`; a aba ativa fica marcada.

signal escolhida(id: String)

const ABAS: Array[String] = ["missoes", "torre", "arena", "feira", "mais"]
const ROTULOS: Dictionary[String, String] = {
	"missoes": "Missões", "torre": "Torre", "arena": "Arena", "feira": "Feira", "mais": "Mais"
}

var _botoes: Dictionary[String, Button] = {}


func _ready() -> void:
	name = "Abas"
	theme_type_variation = &"Cartao"
	var linha := HBoxContainer.new()
	add_child(linha)
	for id: String in ABAS:
		var botao := Button.new()
		botao.name = "Aba_" + id
		botao.text = ROTULOS[id]
		botao.toggle_mode = true
		botao.theme_type_variation = &"BotaoPlano"
		botao.custom_minimum_size = Vector2(0, 96)
		botao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		botao.pressed.connect(func() -> void: escolhida.emit(id))
		linha.add_child(botao)
		_botoes[id] = botao


func marcar(id: String) -> void:
	for chave: String in _botoes:
		_botoes[chave].set_pressed_no_signal(chave == id)
