class_name Guardiao
extends Control
## O guardião em camadas: corpo animado nas tiras do PixelLab (SpriteLib, id "guardiao"), com pele
## e roupa trocadas por shader, e a cabeça montada em blocos (GuardiaoRosto) encaixada no pescoço
## de cada quadro (`pontos.json`). O chapéu vai na cabeça, a arma na mão e o amuleto no peito.
## Tudo é desenhado num SubViewport em 1× e mostrado ampliado com filtro nearest, para a cabeça
## girar sem perder o pixel. Olha para a direita; os pés ficam na linha PES do quadro.

const ID: String = "guardiao"
const LADO: int = 100
## Linha do quadro onde ficam os pés (o corpo desce ou sobe para os pés ficarem nela).
const PES: int = 96
const PONTOS: String = "res://assets/sprites/guardiao/pontos.json"
const CORES: Shader = preload("res://ui/heroi/guardiao_cores.gdshader")
const ITENS: String = "res://assets/heroi/itens/%s.png"
const RARA: Color = Color(0.75, 1.0, 0.75)
const LENDARIA: Color = Color(1.35, 1.15, 0.55)
## Chapéu e amuleto em relação ao pescoço (a cabeça vai de -21 a 0 em y).
const POS_CHAPEU: Vector2 = Vector2(1, -19)
const POS_AMULETO: Vector2 = Vector2(2, 5)
## Cor da roupa de cada item do slot corpo (as roupas são troca de cor).
const ROUPA_ITEM: Dictionary[String, Color] = {
	"gibao_vaqueiro": Color("8c5c34"),
	"bata_algodao": Color("ece6d6"),
	"manto_folhas": Color("3f7c48"),
	"colete_couro": Color("603c24"),
	"poncho_la": Color("b43428"),
}

static var _pontos: Dictionary = {}

## Ampliação na tela.
@export var escala: int = 4
## Ações tocadas, em ordem (os testes leem).
var historico: Array[String] = []

var _visual: Dictionary = GuardiaoRosto.VISUAL_PADRAO.duplicate()
var _roupa_item: String = ""
var _vp: SubViewport
var _corpo: AnimatedSprite2D
var _cabeca: Sprite2D
var _pecas: Dictionary[String, Sprite2D] = {}
var _brilhos: Dictionary[String, String] = {}
var _pulso: Tween
var _tw_queda: Tween
## Quadro em que o ataque para até `recolher` (-1: nenhum).
var _segurar: int = -1


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
	_corpo = AnimatedSprite2D.new()
	_corpo.name = "Corpo"
	_corpo.centered = false
	_corpo.sprite_frames = SpriteLib.frames(ID)
	_corpo.material = ShaderMaterial.new()
	(_corpo.material as ShaderMaterial).shader = CORES
	_corpo.frame_changed.connect(_encaixar)
	_corpo.animation_changed.connect(_encaixar)
	_corpo.animation_finished.connect(_voltar_parado)
	_vp.add_child(_corpo)
	_cabeca = Sprite2D.new()
	_cabeca.name = "Cabeca"
	_cabeca.centered = false
	_cabeca.offset = -Vector2(GuardiaoRosto.PESCOCO)
	_vp.add_child(_cabeca)
	_pecas["cabeca"] = _nova_peca(_cabeca, POS_CHAPEU)
	_pecas["arma"] = _nova_peca(_vp, Vector2.ZERO)
	_pecas["amuleto"] = _nova_peca(_vp, Vector2.ZERO)
	_aplicar_cores()
	_tocar("parado")


func _ready() -> void:
	custom_minimum_size = Vector2(LADO * escala, LADO * escala)


## Sprite do item de um slot (cabeca, arma, amuleto).
func peca(slot: String) -> Sprite2D:
	return _pecas.get(slot)


func cabeca() -> Sprite2D:
	return _cabeca


func corpo() -> AnimatedSprite2D:
	return _corpo


## "" (comum), "rara" ou "lendario".
func brilho(slot: String) -> String:
	return _brilhos.get(slot, "")


## Visual normalizado em uso (pele, rosto, olhos, ..., roupa).
func visual() -> Dictionary:
	return _visual.duplicate()


## Troca o rosto e as cores (dicionário de índices; o que faltar fica no padrão).
func aplicar_visual(v: Dictionary) -> void:
	_visual = GuardiaoRosto.normalizar(v)
	_aplicar_cores()


## Veste os itens de `equip` (slot → item ou vazio): chapéu, arma e amuleto por cima; a roupa
## (slot corpo) troca a cor da roupa.
func vestir(equip: Dictionary, rules: RulesPack) -> void:
	var corpo_item: Variant = equip.get("corpo")
	_roupa_item = HeroiVisual.para_item(corpo_item, rules) if corpo_item is Dictionary else ""
	_marcar_brilho("corpo", corpo_item, [])
	for slot: String in ["cabeca", "arma", "amuleto"]:
		var item: Variant = equip.get(slot)
		var s: Sprite2D = _pecas[slot]
		var id: String = HeroiVisual.para_item(item, rules) if item is Dictionary else ""
		var caminho: String = ITENS % id
		var tem: bool = id != "" and ResourceLoader.exists(caminho)
		s.texture = load(caminho) as Texture2D if tem else null
		_marcar_brilho(slot, item, [s])
	_aplicar_cores()
	_atualizar_pulso()


## Cor da roupa em uso: a do item vestido ou a escolhida no visual.
func cor_roupa() -> Color:
	if ROUPA_ITEM.has(_roupa_item):
		return ROUPA_ITEM[_roupa_item]
	return GuardiaoRosto.ROUPAS[int(_visual["roupa"])]


## Toca uma ação: parado, ataque, critico, golpe, esquiva, derrota ou vitoria. Com `contato_s`
## > 0 num ataque, chega ao punho esticado nesse tempo e segura a pose até `recolher`.
func animar(acao: String, contato_s: float = 0.0) -> void:
	historico.append(acao)
	_tocar(acao)
	if contato_s > 0.0 and (acao == "ataque" or acao == "critico"):
		var pico: int = SpriteLib.pico(ID, "ataque", 1)
		if pico > 0:
			_corpo.speed_scale = pico / (SpriteLib.FPS * contato_s)
			_segurar = pico


## Solta a pose do golpe segurada por `animar(..., contato_s)` e volta ao parado.
func recolher() -> void:
	if _segurar < 0:
		return
	_segurar = -1
	_corpo.speed_scale = 1.0
	_voltar_parado()


func _tocar(acao: String) -> void:
	var nome: String = "ataque" if acao == "critico" else "parado" if acao == "vitoria" else acao
	if not _corpo.sprite_frames.has_animation(nome):
		return
	_segurar = -1
	_corpo.speed_scale = 1.0
	_corpo.play(nome)
	if _tw_queda != null:
		_tw_queda.kill()
	# Na derrota o corpo deitado tem outra folga embaixo: desce junto com a queda.
	if nome == "derrota" and is_inside_tree():
		var dur: float = _corpo.sprite_frames.get_frame_count(&"derrota") / SpriteLib.FPS
		_tw_queda = create_tween()
		_tw_queda.tween_property(_corpo, "position:y", _y("derrota", -1), dur)
		_tw_queda.parallel().tween_method(func(_t: float) -> void: _encaixar(), 0.0, 1.0, dur)
	else:
		_corpo.position.y = _y(nome, 0 if nome != "derrota" else -1)
	_encaixar()


## Volta ao parado no fim da ação, menos na derrota e com o golpe seguro (o pico pode ser o último
## quadro, que termina a animação).
func _voltar_parado() -> void:
	if _segurar >= 0:
		return
	if str(_corpo.animation) != "derrota" and str(_corpo.animation) != "parado":
		_corpo.speed_scale = 1.0
		_corpo.play("parado")
		_corpo.position.y = _y("parado", 0)
		_encaixar()


## Posição do corpo para os pés de um quadro ficarem na linha PES.
static func _y(acao: String, quadro: int) -> float:
	return float(PES - SpriteLib.pes(ID, acao, quadro))


## Põe cabeça, arma e amuleto no ponto do quadro atual; segura o ataque no pico.
func _encaixar() -> void:
	if _segurar >= 0 and _corpo.frame == _segurar:
		_corpo.pause()
	var p: Array = _ponto(str(_corpo.animation), _corpo.frame)
	if p.is_empty():
		return
	var base: Vector2 = _corpo.position
	var pescoco: Vector2 = base + Vector2(float(p[0]), float(p[1]))
	_cabeca.position = pescoco
	_cabeca.rotation_degrees = float(p[2])
	var arma: Sprite2D = _pecas["arma"]
	arma.position = base + Vector2(float(p[3]), float(p[4]))
	if arma.texture != null and arma.texture.get_width() > arma.texture.get_height():
		# Arma comprida na horizontal: o cabo fica no punho.
		arma.position.x += arma.texture.get_width() / 2.0 - 3.0
	# Caído, a arma some (a mão vira ponto solto).
	arma.visible = not (str(_corpo.animation) == "derrota" and _corpo.frame >= 2)
	_pecas["amuleto"].position = pescoco + POS_AMULETO.rotated(_cabeca.rotation)


static func _ponto(acao: String, quadro: int) -> Array:
	if _pontos.is_empty():
		_pontos = JSON.parse_string(FileAccess.get_file_as_string(PONTOS))
	var lista: Array = _pontos.get(acao, [])
	return lista[clampi(quadro, 0, lista.size() - 1)] if not lista.is_empty() else []


func _aplicar_cores() -> void:
	var m: ShaderMaterial = _corpo.material as ShaderMaterial
	m.set_shader_parameter("pele", GuardiaoRosto.cor_pele(_visual))
	m.set_shader_parameter("roupa", cor_roupa())
	_cabeca.texture = GuardiaoRosto.textura(_visual, _pecas["cabeca"].texture != null)


func _nova_peca(pai: Node, pos: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.position = pos
	pai.add_child(s)
	return s


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
	for s: Sprite2D in _pecas.values():
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
