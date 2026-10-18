extends Control
## Aba Mais: menu para Mochila, Bestiário e Ajustes. Cada tela abre no lugar do menu, com Voltar.

const TELAS: Dictionary[String, String] = {
	"Mochila": "res://ui/abas/mochila.tscn",
	"Bestiario": "res://ui/abas/bestiario.tscn",
	"Ajustes": "res://ui/abas/ajustes.tscn",
}
const ROTULOS: Dictionary[String, String] = {
	"Mochila": "Mochila", "Bestiario": "Bestiário", "Ajustes": "Ajustes"
}

var _menu: VBoxContainer
var _voltar: Button
var _telas: Dictionary[String, Control] = {}


func _ready() -> void:
	_menu = VBoxContainer.new()
	_menu.name = "MenuMais"
	_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_menu.offset_left = 20
	_menu.offset_right = -20
	_menu.offset_top = 20
	_menu.add_theme_constant_override("separation", 16)
	add_child(_menu)
	_menu.add_child(AbaBase.rotulo("Mais", &"Titulo"))
	for chave: String in TELAS:
		var b := AbaBase.botao("Abrir" + chave, ROTULOS[chave], true)
		b.pressed.connect(abrir.bind(chave))
		_menu.add_child(b)
	_voltar = AbaBase.botao("Voltar", "< Voltar")
	_voltar.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_voltar.custom_minimum_size = Vector2(200, 88)
	_voltar.pressed.connect(voltar)
	add_child(_voltar)
	_voltar.hide()


func abrir(chave: String) -> void:
	if not _telas.has(chave):
		if not ResourceLoader.exists(TELAS[chave]):
			Toast.avisar(self, "Em breve.", "aviso")
			return
		var tela: Control = (load(TELAS[chave]) as PackedScene).instantiate() as Control
		tela.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tela.offset_top = 96
		add_child(tela)
		_telas[chave] = tela
	_menu.hide()
	for c: String in _telas:
		_telas[c].visible = c == chave
	_voltar.show()


func voltar() -> void:
	for c: String in _telas:
		_telas[c].hide()
	_voltar.hide()
	_menu.show()
