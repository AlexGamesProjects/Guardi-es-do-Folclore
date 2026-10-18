class_name Boneco
extends Control
## Guardião articulado: 11 ossos (Node2D) com partes em pixel art, desenhados num SubViewport
## pequeno e mostrados ampliados com filtro nearest, para os giros manterem o visual de pixel.
## `vestir` põe os itens equipados nos ossos; `animar` toca poses com Tween. Olha para a direita.

const LADO: int = 96
const PARTES: String = "res://assets/heroi/partes/%s.png"
const ITENS: String = "res://assets/heroi/itens/%s.png"
const RARA: Color = Color(0.75, 1.0, 0.75)
const LENDARIA: Color = Color(1.35, 1.15, 0.55)

## Ampliação do boneco na tela.
@export var escala: int = 4
## Ações tocadas, em ordem (os testes leem).
var historico: Array[String] = []

var _vp: SubViewport
var _raiz: Node2D
var _ossos: Dictionary[String, Node2D] = {}
var _partes: Dictionary[String, Sprite2D] = {}
var _pecas: Dictionary[String, Sprite2D] = {}
var _brilhos: Dictionary[String, String] = {}
var _tween: Tween
var _pulso: Tween


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vp = SubViewport.new()
	_vp.size = Vector2i(LADO, LADO)
	_vp.transparent_bg = true
	_vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_vp)
	var tela := TextureRect.new()
	tela.name = "Tela"
	tela.texture = _vp.get_texture()
	tela.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tela.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tela.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tela.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tela.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tela)
	_montar()


func _ready() -> void:
	custom_minimum_size = Vector2(LADO * escala, LADO * escala)
	animar("parado")


func osso(nome: String) -> Node2D:
	return _ossos.get(nome)


## Sprite da parte do corpo de um osso (tronco, braço...).
func parte(nome: String) -> Sprite2D:
	return _partes.get(nome)


## Sprite do item de um slot (cabeca, arma, amuleto).
func peca(slot: String) -> Sprite2D:
	return _pecas.get(slot)


## "" (comum), "rara" ou "lendario".
func brilho(slot: String) -> String:
	return _brilhos.get(slot, "")


## Veste os itens de `equip` (slot → item ou vazio). Slot sem item volta ao corpo base.
func vestir(equip: Dictionary, rules: RulesPack) -> void:
	var roupa: String = ""
	var corpo: Variant = equip.get("corpo")
	if corpo is Dictionary:
		roupa = HeroiVisual.para_item(corpo, rules)
	_por_textura("Tronco", _arquivo_roupa(roupa, "tronco"))
	for lado: String in ["Tras", "Frente"]:
		_por_textura("Braco" + lado, _arquivo_roupa(roupa, "braco"))
		_por_textura("Antebraco" + lado, _arquivo_roupa(roupa, "antebraco"))
	_marcar_brilho("corpo", corpo, [_partes["Tronco"]])
	for slot: String in ["cabeca", "arma", "amuleto"]:
		var item: Variant = equip.get(slot)
		var sprite: Sprite2D = _pecas[slot]
		var visual: String = HeroiVisual.para_item(item, rules) if item is Dictionary else ""
		var caminho: String = ITENS % visual
		sprite.texture = (
			load(caminho) as Texture2D if visual != "" and ResourceLoader.exists(caminho) else null
		)
		_marcar_brilho(slot, item, [sprite])
	_atualizar_pulso()


## Toca uma ação: parado, ataque, critico, golpe, esquiva, derrota, vitoria ou andar.
func animar(acao: String) -> void:
	var quadros: Array = HeroiPoses.sequencia(acao)
	if quadros.is_empty():
		return
	historico.append(acao)
	if _tween != null:
		_tween.kill()
	if not is_inside_tree():
		_aplicar(quadros[-1][0], 0.0)
		return
	_tween = create_tween()
	_tween.set_loops(0 if acao == "parado" or acao == "andar" else 1)
	for q: Array in quadros:
		_tween.set_parallel(true)
		var pose: Dictionary = q[0]
		var dur: float = float(q[1])
		for nome: String in pose:
			if nome == "x" or nome == "y":
				_tween.tween_property(
					_ossos["Quadril"],
					"position:" + nome,
					_base_quadril()[nome] + float(pose[nome]),
					dur
				)
			elif _ossos.has(nome):
				_tween.tween_property(_ossos[nome], "rotation_degrees", float(pose[nome]), dur)
		_tween.set_parallel(false)
		_tween.tween_interval(dur)
	if acao != "parado" and acao != "andar" and acao != "derrota" and acao != "vitoria":
		_tween.finished.connect(func() -> void: animar("parado"), CONNECT_ONE_SHOT)


func _aplicar(pose: Dictionary, _dur: float) -> void:
	for nome: String in pose:
		if nome == "x" or nome == "y":
			_ossos["Quadril"].set_indexed(
				"position:" + nome, _base_quadril()[nome] + float(pose[nome])
			)
		elif _ossos.has(nome):
			_ossos[nome].rotation_degrees = float(pose[nome])


static func _base_quadril() -> Dictionary:
	return {"x": 48.0, "y": 66.0}


func _montar() -> void:
	_raiz = Node2D.new()
	_raiz.name = "Raiz"
	_vp.add_child(_raiz)
	var quadril: Node2D = _novo_osso("Quadril", _raiz, Vector2(48, 66))
	# Ordem de desenho: perna e braço de trás, tronco e cabeça, perna e braço da frente.
	var coxa_t: Node2D = _novo_osso(
		"CoxaTras", quadril, Vector2(-2, 0), "coxa", Vector2(-3.5, -1), -1
	)
	_novo_osso("CanelaTras", coxa_t, Vector2(0, 10), "canela", Vector2(-3.5, -1), -1)
	var tronco: Node2D = _novo_osso("Tronco", quadril, Vector2(0, 1), "tronco", Vector2(-7, -18))
	var braco_t: Node2D = _novo_osso(
		"BracoTras", tronco, Vector2(-1, -15), "braco", Vector2(-3, -1), -2
	)
	_novo_osso("AntebracoTras", braco_t, Vector2(0, 9), "antebraco", Vector2(-3, -1), -2)
	var cabeca: Node2D = _novo_osso("Cabeca", tronco, Vector2(1, -16), "cabeca", Vector2(-7, -13))
	_pecas["cabeca"] = _nova_peca(cabeca, Vector2(0, -11), 2)
	_pecas["amuleto"] = _nova_peca(tronco, Vector2(1, -11), 1)
	var coxa_f: Node2D = _novo_osso(
		"CoxaFrente", quadril, Vector2(2, 0), "coxa", Vector2(-3.5, -1), 1
	)
	_novo_osso("CanelaFrente", coxa_f, Vector2(0, 10), "canela", Vector2(-3.5, -1), 1)
	var braco_f: Node2D = _novo_osso(
		"BracoFrente", tronco, Vector2(3, -15), "braco", Vector2(-3, -1), 3
	)
	var ante_f: Node2D = _novo_osso(
		"AntebracoFrente", braco_f, Vector2(0, 9), "antebraco", Vector2(-3, -1), 3
	)
	_pecas["arma"] = _nova_peca(ante_f, Vector2(2, 9), 4)
	for nome: String in ["CoxaTras", "CanelaTras", "BracoTras", "AntebracoTras"]:
		_partes[nome].modulate = Color(0.72, 0.68, 0.66)


func _novo_osso(
	nome: String,
	pai: Node2D,
	pos: Vector2,
	arquivo: String = "",
	deslocamento: Vector2 = Vector2.ZERO,
	z: int = 0
) -> Node2D:
	var o := Node2D.new()
	o.name = nome
	o.position = pos
	o.z_index = z
	o.z_as_relative = false
	pai.add_child(o)
	_ossos[nome] = o
	if arquivo != "":
		var s := Sprite2D.new()
		s.name = "Arte"
		s.centered = false
		s.offset = deslocamento
		s.texture = load(PARTES % arquivo) as Texture2D
		s.set_meta("base", PARTES % arquivo)
		o.add_child(s)
		_partes[nome] = s
	return o


func _nova_peca(pai: Node2D, pos: Vector2, z: int) -> Sprite2D:
	var s := Sprite2D.new()
	s.position = pos
	s.z_index = z
	s.z_as_relative = false
	pai.add_child(s)
	return s


func _por_textura(osso_nome: String, caminho: String) -> void:
	var s: Sprite2D = _partes[osso_nome]
	var usar: String = (
		caminho if caminho != "" and ResourceLoader.exists(caminho) else str(s.get_meta("base"))
	)
	s.texture = load(usar) as Texture2D


static func _arquivo_roupa(roupa: String, peca_nome: String) -> String:
	return "" if roupa == "" else ITENS % ("%s_%s" % [roupa, peca_nome])


func _marcar_brilho(slot: String, item: Variant, sprites: Array) -> void:
	var rar: int = int((item as Dictionary).get("rar", 0)) if item is Dictionary else 0
	_brilhos[slot] = "lendario" if rar >= 2 else "rara" if rar == 1 else ""
	for s: Sprite2D in sprites:
		s.self_modulate = RARA if rar == 1 else Color.WHITE
		s.set_meta("lendario", rar >= 2)


func _atualizar_pulso() -> void:
	if _pulso != null:
		_pulso.kill()
		_pulso = null
	var alvos: Array[Sprite2D] = []
	for s: Sprite2D in _pecas.values() + [_partes["Tronco"]]:
		if bool(s.get_meta("lendario", false)):
			alvos.append(s)
	if alvos.is_empty() or not is_inside_tree():
		for s: Sprite2D in alvos:
			s.self_modulate = LENDARIA
		return
	_pulso = create_tween().set_loops()
	for s: Sprite2D in alvos:
		_pulso.parallel().tween_property(s, "self_modulate", LENDARIA, 0.6)
	_pulso.chain()
	for s: Sprite2D in alvos:
		_pulso.parallel().tween_property(s, "self_modulate", Color.WHITE, 0.6)
