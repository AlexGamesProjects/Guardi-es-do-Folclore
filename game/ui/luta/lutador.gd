class_name Lutador
extends Control
## Um corpo no palco de duelo, de pé sobre o chão (a origem deste nó fica nos pés).
## O herói é o guardião articulado (Boneco, vestindo o que está equipado); a lenda usa o sprite
## do PixelLab (SpriteLib) e, sem ele, a carta recortada de pé. A barra de vida fica no placar
## do palco e é ligada em `barra`. `animar` é a porta única para as animações.

const ACOES: Array[String] = [
	"parado", "ataque", "critico", "golpe", "esquiva", "derrota", "vitoria"
]
const ALTURA_CARTA: float = 300.0
const ESCALA_HEROI: int = 6
const ESCALA_SPRITE: int = 4
## Tempo da barra de vida descendo depois de um golpe.
const VIDA_S: float = 0.35

## Ações tocadas, em ordem (os testes leem).
var historico: Array[String] = []
## +1 olha para a direita (herói), -1 para a esquerda (inimigo).
var direcao: int = 1
## Barra de vida e rótulo de PV do placar (o palco liga).
var barra: ProgressBar
var rotulo_pv: Label
var _corpo: Control
var _boneco: Boneco
var _sprite: AnimatedSprite2D
var _tw_vida: Tween


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_corpo = Control.new()
	_corpo.name = "Corpo"
	_corpo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_corpo)


## Prepara o corpo. `equip`/`rules` vestem o herói; `textura` é a carta da lenda (ou null).
func preparar(
	nome: String,
	lvl: int,
	hp: int,
	textura: Texture2D,
	sprite_id: String = "",
	equip: Dictionary = {},
	rules: RulesPack = null
) -> void:
	set_meta("nome", "%s · nível %d" % [nome, lvl])
	if barra != null:
		barra.max_value = maxi(1, hp)
	vida(hp)
	for filho: Node in _corpo.get_children():
		_corpo.remove_child(filho)
		filho.queue_free()
	_boneco = null
	_sprite = null
	if sprite_id == "heroi":
		_boneco = Boneco.new()
		_boneco.name = "Boneco"
		_boneco.escala = ESCALA_HEROI
		_boneco.size = Vector2(Boneco.LADO, Boneco.LADO) * ESCALA_HEROI
		# Os pés do boneco ficam em y = 88 do quadro de 96.
		_boneco.position = Vector2(-Boneco.LADO / 2.0, -88.0) * ESCALA_HEROI
		_corpo.add_child(_boneco)
		_boneco.vestir(equip, rules)
	else:
		var frames: SpriteFrames = SpriteLib.frames(sprite_id)
		if frames != null:
			_sprite = AnimatedSprite2D.new()
			_sprite.name = "Sprite"
			_sprite.sprite_frames = frames
			_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			_sprite.scale = Vector2(ESCALA_SPRITE, ESCALA_SPRITE)
			_sprite.set_meta("id", sprite_id)
			_sprite.position = Vector2(0, _y_no_chao("parado", 0))
			_corpo.add_child(_sprite)
		else:
			var carta := TextureRect.new()
			carta.name = "Carta"
			carta.texture = textura
			carta.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			carta.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			carta.size = Vector2(ALTURA_CARTA * 0.72, ALTURA_CARTA)
			carta.position = Vector2(-carta.size.x / 2, -ALTURA_CARTA)
			_corpo.add_child(carta)
			if textura == null:
				var inicial := Label.new()
				inicial.text = nome.left(1)
				inicial.theme_type_variation = &"Titulo"
				inicial.add_theme_font_size_override("font_size", 140)
				inicial.position = Vector2(-50, -ALTURA_CARTA * 0.8)
				_corpo.add_child(inicial)
	animar("parado")


## Atualiza a vida; `animado` faz a barra descer aos poucos.
func vida(hp: int, animado: bool = false) -> void:
	if barra != null:
		if _tw_vida != null:
			_tw_vida.kill()
			_tw_vida = null
		if animado and barra.is_inside_tree():
			_tw_vida = barra.create_tween()
			_tw_vida.tween_property(barra, "value", float(hp), VIDA_S).set_trans(Tween.TRANS_QUAD)
		else:
			barra.value = hp
	if rotulo_pv != null:
		rotulo_pv.text = "%d PV" % hp


## Toca uma ação: parado, ataque, critico, golpe, esquiva, derrota ou vitoria.
func animar(acao: String) -> void:
	if not ACOES.has(acao):
		return
	historico.append(acao)
	if _boneco != null:
		_boneco.animar(acao)
		return
	if _sprite != null:
		_tocar_sprite(acao)
	if not is_inside_tree():
		return
	var tw: Tween = create_tween()
	match acao:
		"golpe":
			tw.tween_property(_corpo, "modulate", Color(1, 0.4, 0.4), 0.06)
			tw.tween_property(_corpo, "modulate", Color.WHITE, 0.14)
		"esquiva":
			tw.tween_property(_corpo, "modulate:a", 0.5, 0.08)
			tw.tween_property(_corpo, "modulate:a", 1.0, 0.16)
		"derrota":
			if _sprite == null:
				tw.tween_property(_corpo, "rotation_degrees", -80.0 * direcao, 0.35)
			else:
				tw.kill()
		"vitoria":
			tw.tween_property(_corpo, "position:y", -30.0, 0.18)
			tw.tween_property(_corpo, "position:y", 0.0, 0.18)
		_:
			tw.kill()


## Altura do sprite (centrado) para a linha dos pés de um quadro ficar no chão.
func _y_no_chao(acao: String, quadro: int) -> float:
	var sf: SpriteFrames = _sprite.sprite_frames
	var lado: float = sf.get_frame_texture(sf.get_animation_names()[0], 0).get_height()
	var pes: int = SpriteLib.pes(str(_sprite.get_meta("id")), acao, quadro)
	return (lado / 2.0 - pes) * ESCALA_SPRITE


func _tocar_sprite(acao: String) -> void:
	var nome: String = "ataque" if acao == "critico" else "parado" if acao == "vitoria" else acao
	if _sprite.sprite_frames.has_animation(nome):
		_sprite.play(nome)
		# Na derrota o corpo deitado tem outra folga embaixo: desce junto com a queda.
		var y: float = _y_no_chao("derrota", -1) if nome == "derrota" else _y_no_chao("parado", 0)
		if nome == "derrota" and is_inside_tree():
			var dur: float = _sprite.sprite_frames.get_frame_count(&"derrota") / SpriteLib.FPS
			create_tween().tween_property(_sprite, "position:y", y, dur)
		else:
			_sprite.position.y = y
		if nome != "parado" and nome != "derrota" and _sprite.sprite_frames.has_animation("parado"):
			if not _sprite.animation_finished.is_connected(_voltar_parado):
				_sprite.animation_finished.connect(_voltar_parado)


func _voltar_parado() -> void:
	if _sprite != null and str(_sprite.animation) != "derrota":
		_sprite.play("parado")
