extends Control
## Esqueleto único (#32): a tira atual do PixelLab ao lado do esqueleto, com um botão por lenda e
## um por ação, para a dona comparar. Aberta pelos Ajustes (ou com F6 no editor).

const JOGO_SCENE: String = "res://ui/jogo.tscn"
const LENDAS: Dictionary[String, String] = {
	"saci": "Saci",
	"curupira": "Curupira",
	"cuca": "Cuca",
	"iara": "Iara",
	"boto": "Boto",
	"mapinguari": "Mapinguari",
}
const ROTULOS: Dictionary[String, String] = {
	"parado": "Parado",
	"ataque": "Ataque",
	"critico": "Crítico",
	"golpe": "Golpe",
	"esquiva": "Esquiva",
	"derrota": "Derrota",
	"vitoria": "Vitória",
}

var lenda: String = ""
var _sprite: AnimatedSprite2D
var _esqueleto: Esqueleto
var _titulo: Label
var _palco: VBoxContainer


func _ready() -> void:
	var tela := VBoxContainer.new()
	tela.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tela.add_theme_constant_override("separation", 16)
	add_child(tela)
	var voltar := Button.new()
	voltar.name = "Voltar"
	voltar.text = "< Voltar"
	voltar.theme_type_variation = &"BotaoPlano"
	voltar.custom_minimum_size = Vector2(120, 64)
	voltar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	voltar.pressed.connect(func() -> void: get_tree().change_scene_to_file(JOGO_SCENE))
	tela.add_child(voltar)
	_titulo = Label.new()
	_titulo.theme_type_variation = &"Titulo"
	_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tela.add_child(_titulo)
	var lendas := GridContainer.new()
	lendas.columns = 3
	lendas.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tela.add_child(lendas)
	for id: String in LENDAS:
		var l := Button.new()
		l.name = "Lenda_" + id
		l.text = LENDAS[id]
		l.custom_minimum_size = Vector2(200, 56)
		l.pressed.connect(mostrar.bind(id))
		lendas.add_child(l)
	_palco = VBoxContainer.new()
	_palco.alignment = BoxContainer.ALIGNMENT_CENTER
	_palco.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_palco.add_theme_constant_override("separation", 24)
	tela.add_child(_palco)
	var botoes := GridContainer.new()
	botoes.columns = 4
	botoes.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tela.add_child(botoes)
	for acao: String in ROTULOS:
		var b := Button.new()
		b.name = "Acao_" + acao
		b.text = ROTULOS[acao]
		b.custom_minimum_size = Vector2(150, 64)
		b.pressed.connect(animar.bind(acao))
		botoes.add_child(b)
	mostrar("saci")


## Troca a lenda mostrada nas duas colunas.
func mostrar(id: String) -> void:
	lenda = id
	_titulo.text = "Esqueleto único · %s" % LENDAS[id]
	for filho: Node in _palco.get_children():
		_palco.remove_child(filho)
		filho.queue_free()
	_sprite = null
	_palco.add_child(_coluna("Tira atual (7 gerações)", _montar_tira()))
	_esqueleto = Esqueleto.new()
	_esqueleto.name = "Esqueleto"
	_esqueleto.escala = 3
	_esqueleto.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_esqueleto.montar(id)
	_palco.add_child(_coluna("Esqueleto (1 geração)", _esqueleto))


func animar(acao: String) -> void:
	_esqueleto.animar(acao)
	if _sprite == null:
		return
	# A tira não tem crítico nem vitória: usa ataque e parado, como o Lutador.
	var nome: String = "ataque" if acao == "critico" else "parado" if acao == "vitoria" else acao
	if _sprite.sprite_frames.has_animation(nome):
		_sprite.play(nome)


func _coluna(texto: String, corpo: Control) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	var rotulo := Label.new()
	rotulo.text = texto
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(rotulo)
	col.add_child(corpo)
	return col


func _montar_tira() -> Control:
	var caixa := Control.new()
	var frames: SpriteFrames = SpriteLib.frames(lenda)
	if frames == null:
		return caixa
	var lado: float = frames.get_frame_texture(&"parado", 0).get_height()
	caixa.custom_minimum_size = Vector2(lado, lado) * 3
	caixa.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = frames
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = Vector2(3, 3)
	_sprite.position = caixa.custom_minimum_size / 2
	_sprite.animation_finished.connect(
		func() -> void:
			if str(_sprite.animation) != "derrota":
				_sprite.play(&"parado")
	)
	caixa.add_child(_sprite)
	_sprite.play(&"parado")
	return caixa
