class_name Esqueleto
extends Control
## Lenda montada num esqueleto único (#32): partes recortadas do quadro parado do PixelLab
## (`tools/recortar_lenda.gd`), presas a ossos de um Skeleton2D e animadas por um AnimationPlayer
## com a biblioteca comum `esqueleto_anims.tres` (editável na linha do tempo do editor).
## Desenhado num SubViewport pequeno e mostrado ampliado com filtro nearest, como o Boneco.
## Olha para a esquerda, como as tiras das lendas.

const RAIZ: String = "res://assets/esqueleto/%s"
const ANIMS: String = "res://ui/luta/esqueleto_anims.tres"
const OSSOS: Array[String] = ["Quadril", "Tronco", "Cabeca", "Bracos", "PernaFrente", "PernaTras"]
## Ações que voltam para "parado" ao terminar.
const VOLTAM: Array[String] = ["ataque", "critico", "golpe", "esquiva"]

## Ampliação na tela.
@export var escala: int = 4
## Ações tocadas, em ordem (os testes leem).
var historico: Array[String] = []
## Lado do quadro de origem, em pixels.
var lado: int = 0

var _vp: SubViewport
var _raiz: Node2D
var _player: AnimationPlayer
var _ossos: Dictionary[String, Bone2D] = {}


static func existe(id: String) -> bool:
	return id != "" and FileAccess.file_exists((RAIZ % id) + "/montagem.json")


## Monta a lenda `id`. Devolve false se ela não tiver montagem.
func montar(id: String) -> bool:
	if not existe(id):
		return false
	var dados: Variant = JSON.parse_string(
		FileAccess.get_file_as_string((RAIZ % id) + "/montagem.json")
	)
	if not dados is Dictionary:
		return false
	var m: Dictionary = dados
	lado = int(m["lado"])
	var pes := Vector2(float(m["pes"][0]), float(m["pes"][1]))
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Quadro 1,5× da largura: sobra espaço para avançar, recuar e cair.
	_vp = SubViewport.new()
	_vp.size = Vector2i(lado * 7 / 4, lado)
	_vp.transparent_bg = true
	_vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_vp)
	var tela := TextureRect.new()
	tela.name = "Tela"
	tela.texture = _vp.get_texture()
	tela.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tela.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tela.stretch_mode = TextureRect.STRETCH_SCALE
	tela.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tela.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tela)
	custom_minimum_size = Vector2(lado * 7 / 4, lado) * escala
	size = custom_minimum_size
	# Raiz nos pés; Corpo é o que anda e gira (em volta dos pés); o esqueleto fica sob ele.
	_raiz = Node2D.new()
	_raiz.name = "Raiz"
	_raiz.position = pes + Vector2(lado / 4.0, 0)
	_vp.add_child(_raiz)
	var corpo := Node2D.new()
	corpo.name = "Corpo"
	_raiz.add_child(corpo)
	var esq := Skeleton2D.new()
	esq.name = "Skeleton2D"
	esq.position = -pes
	corpo.add_child(esq)
	_montar_ossos(id, m["partes"], esq)
	_player = AnimationPlayer.new()
	_player.name = "Animacoes"
	_raiz.add_child(_player)
	_player.add_animation_library(&"", load(ANIMS) as AnimationLibrary)
	_player.animation_finished.connect(_terminou)
	animar("parado")
	return true


func osso(nome: String) -> Bone2D:
	return _ossos.get(nome)


func acao_atual() -> String:
	return "" if _player == null else str(_player.current_animation)


## Toca uma ação: parado, ataque, critico, golpe, esquiva, derrota ou vitoria.
func animar(acao: String) -> void:
	if _player == null or not _player.has_animation(acao):
		return
	historico.append(acao)
	_player.stop()
	_player.play(acao)
	if not is_inside_tree():
		_player.seek(_player.current_animation_length, true)


func _terminou(acao: StringName) -> void:
	if VOLTAM.has(str(acao)):
		_player.play(&"parado")


func _montar_ossos(id: String, partes: Array, esq: Skeleton2D) -> void:
	var por_nome: Dictionary[String, Dictionary] = {}
	for p: Dictionary in partes:
		por_nome[str(p["osso"])] = p
	# Pais antes dos filhos: cria na ordem fixa de OSSOS.
	for nome: String in OSSOS:
		if not por_nome.has(nome):
			continue
		var p: Dictionary = por_nome[nome]
		var pivo := Vector2(float(p["pivo"][0]), float(p["pivo"][1]))
		var pai_nome: String = str(p["pai"])
		var pai: Node = esq
		var base := Vector2.ZERO
		if pai_nome != "" and _ossos.has(pai_nome):
			pai = _ossos[pai_nome]
			var pp: Dictionary = por_nome[pai_nome]
			base = Vector2(float(pp["pivo"][0]), float(pp["pivo"][1]))
		var o := Bone2D.new()
		o.name = nome
		o.set_autocalculate_length_and_angle(false)
		o.set_length(4.0)
		o.position = pivo - base
		o.rest = o.transform
		pai.add_child(o)
		_ossos[nome] = o
		var s := Sprite2D.new()
		s.name = "Arte"
		s.centered = false
		s.texture = load("%s/%s.png" % [RAIZ % id, nome]) as Texture2D
		s.position = Vector2(float(p["canto"][0]), float(p["canto"][1])) - pivo
		s.z_index = int(p["z"])
		s.z_as_relative = false
		o.add_child(s)
