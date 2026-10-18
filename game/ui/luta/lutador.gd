class_name Lutador
extends VBoxContainer
## Um lado da luta: retrato (carta da lenda, ou um quadro com a inicial), nome e vida.
## `animar` é a única porta que a pixel art troca (Tarefa 10).

const ACOES: Array[String] = ["parado", "ataque", "critico", "golpe", "esquiva", "derrota"]

## Ações tocadas, em ordem (os testes leem).
var historico: Array[String] = []
## +1 se avança para a direita (herói), -1 para a esquerda (inimigo).
var direcao: int = 1
var _retrato: Control
var _nome: Label
var _barra: ProgressBar
var _pv: Label


func _ready() -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_retrato = PanelContainer.new()
	_retrato.theme_type_variation = &"Cartao"
	_retrato.custom_minimum_size = Vector2(260, 340)
	add_child(_retrato)
	_nome = Label.new()
	_nome.theme_type_variation = &"Valor"
	_nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_nome.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_nome)
	_barra = ProgressBar.new()
	_barra.theme_type_variation = &"BarraVida"
	_barra.show_percentage = false
	_barra.custom_minimum_size = Vector2(0, 22)
	add_child(_barra)
	_pv = Label.new()
	_pv.theme_type_variation = &"Dica"
	_pv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_pv)


## Prepara o lado: nome, nível, vida e retrato (`textura` pode ser null).
func preparar(nome: String, lvl: int, hp: int, textura: Texture2D) -> void:
	_nome.text = "%s · nível %d" % [nome, lvl]
	_barra.max_value = maxi(1, hp)
	vida(hp)
	for filho: Node in _retrato.get_children():
		filho.queue_free()
	if textura != null:
		var img := TextureRect.new()
		img.texture = textura
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		_retrato.add_child(img)
	else:
		var inicial := Label.new()
		inicial.text = nome.left(1)
		inicial.theme_type_variation = &"Titulo"
		inicial.add_theme_font_size_override("font_size", 120)
		inicial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		inicial.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_retrato.add_child(inicial)
	animar("parado")


func vida(hp: int) -> void:
	_barra.value = hp
	_pv.text = "%d PV" % hp


## Toca uma ação: parado, ataque, critico, golpe, esquiva ou derrota.
func animar(acao: String) -> void:
	if not ACOES.has(acao):
		return
	historico.append(acao)
	if not is_inside_tree():
		return
	var tw: Tween = create_tween()
	match acao:
		"ataque", "critico":
			var passo: float = 24.0 * (2.0 if acao == "critico" else 1.0) * direcao
			tw.tween_property(_retrato, "position:x", _retrato.position.x + passo, 0.08)
			tw.tween_property(_retrato, "position:x", _retrato.position.x, 0.12)
		"golpe":
			tw.tween_property(_retrato, "modulate", Color(1, 0.35, 0.35), 0.06)
			tw.tween_property(_retrato, "modulate", Color.WHITE, 0.14)
		"esquiva":
			tw.tween_property(_retrato, "modulate:a", 0.5, 0.08)
			tw.tween_property(_retrato, "modulate:a", 1.0, 0.16)
		"derrota":
			tw.tween_property(_retrato, "modulate:a", 0.15, 0.4)
		_:
			tw.kill()
