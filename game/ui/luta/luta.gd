class_name Luta
extends Control
## Palco de duelo por cima da aba: fundo com a pintura da lenda, chão, os dois lutadores de pé,
## placar com as vidas no topo e números de dano. Toca os eventos do núcleo (luta, golpe,
## critico, esquiva, fim): o atacante avança, golpeia e volta. Botões 1×/2×/4× e Pular.
## A luta já foi resolvida no núcleo: pular ou pausar o app não muda o resultado.

signal terminou(resultado: Dictionary)

## Duração de cada troca (corrida, golpe, pausa e volta), em 1×.
const INTERVALO_S: float = 1.0
const CHAO: float = 0.72
const POS_HEROI: float = 0.27
const POS_INIMIGO: float = 0.73
## Quanto os pés descem abaixo da linha do chão, para pisarem na faixa de capim e não em cima.
const PISO: float = 8.0
## Distância entre os centros dos dois no golpe quando não dá para medir o desenho (lenda só com
## a carta): o atacante para na frente do alvo.
const ALCANCE: float = 180.0
## Quanto o punho entra no corpo do alvo, para o golpe parecer contato.
const SOBREPOR: float = 8.0
## Fração da troca gasta na corrida até o contato.
const CORRIDA: float = 0.3
## Quanto o alvo recua no contato.
const RECUO: float = 16.0
const COR_DANO: Color = Color("efe7d4")
const COR_CRITICO: Color = Color("f2c14e")

var heroi: Lutador
var inimigo: Lutador
var terminada: bool = false
## Quantas vezes alguém avançou para golpear (os testes leem).
var avancos: int = 0
## Textos dos números de dano mostrados (os testes leem).
var numeros_mostrados: Array[String] = []
var _fila: Array[Dictionary] = []
var _velocidade: int = 1
var _nomes: Array[String] = ["", ""]
var _vitoria: bool = false
var _premios: Array[String] = []
## Impacto do golpe em andamento, aplicado quando o atacante encosta no alvo.
var _impacto: Callable = Callable()
var _timer: Timer
var _velocidade_b: Button
var _fundo: TextureRect
var _palco: Control
var _narracao: Label
var _resultado: PanelContainer
var _resultado_texto: Label
var _resultado_premios: Label
var _flash: ColorRect
var _placar_nomes: Array[Label] = []


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var base := ColorRect.new()
	base.color = Color("140d08")
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(base)
	_fundo = TextureRect.new()
	_fundo.name = "Fundo"
	_fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fundo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_fundo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_fundo.modulate = Color(0.3, 0.26, 0.23)
	add_child(_fundo)
	var chao := Chao.new()
	chao.name = "Chao"
	chao.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	chao.altura = CHAO
	add_child(chao)
	_palco = Control.new()
	_palco.name = "Palco"
	_palco.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_palco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_palco)
	heroi = Lutador.new()
	heroi.name = "Heroi"
	heroi.direcao = 1
	_palco.add_child(heroi)
	inimigo = Lutador.new()
	inimigo.name = "Inimigo"
	inimigo.direcao = -1
	_palco.add_child(inimigo)
	_montar_placar()
	_narracao = AbaBase.rotulo("", &"Valor", "Narracao")
	_narracao.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_narracao.anchor_left = 0.0
	_narracao.anchor_right = 1.0
	_narracao.anchor_top = 0.0
	_narracao.offset_top = 200
	_narracao.offset_left = 24
	_narracao.offset_right = -24
	add_child(_narracao)
	var pular_b := AbaBase.botao("Pular", "Pular")
	pular_b.anchor_left = 0.5
	pular_b.anchor_right = 0.5
	pular_b.anchor_top = 1.0
	pular_b.anchor_bottom = 1.0
	pular_b.offset_left = -120
	pular_b.offset_right = 120
	pular_b.offset_top = -130
	pular_b.offset_bottom = -42
	pular_b.pressed.connect(pular)
	add_child(pular_b)
	_velocidade_b = AbaBase.botao("Velocidade", "1×")
	_velocidade_b.anchor_left = 1.0
	_velocidade_b.anchor_right = 1.0
	_velocidade_b.anchor_top = 1.0
	_velocidade_b.anchor_bottom = 1.0
	_velocidade_b.offset_left = -150
	_velocidade_b.offset_right = -24
	_velocidade_b.offset_top = -130
	_velocidade_b.offset_bottom = -42
	_velocidade_b.pressed.connect(trocar_velocidade)
	add_child(_velocidade_b)
	_resultado = AbaBase.cartao()
	_resultado.name = "Resultado"
	_resultado.anchor_left = 0.0
	_resultado.anchor_right = 1.0
	_resultado.anchor_top = 1.0
	_resultado.anchor_bottom = 1.0
	_resultado.offset_left = 30
	_resultado.offset_right = -30
	_resultado.offset_top = -330
	_resultado.offset_bottom = -30
	# Com muitos prêmios o cartão cresce para cima, sem empurrar o Continuar para fora da tela.
	_resultado.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var rcaixa := VBoxContainer.new()
	_resultado.add_child(rcaixa)
	_resultado_texto = AbaBase.rotulo("", &"Titulo", "ResultadoTexto")
	_resultado_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_resultado_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rcaixa.add_child(_resultado_texto)
	_resultado_premios = AbaBase.rotulo("", &"Valor", "ResultadoPremios")
	_resultado_premios.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_resultado_premios.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rcaixa.add_child(_resultado_premios)
	var ok := AbaBase.botao("Fechar", "Continuar", true)
	ok.pressed.connect(fechar)
	rcaixa.add_child(ok)
	_resultado.hide()
	add_child(_resultado)
	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_flash)
	_timer = Timer.new()
	_timer.timeout.connect(_passo)
	add_child(_timer)
	resized.connect(_posicionar)


## Começa a tocar `eventos` (a partir do evento `luta`) na `velocidade` 1, 2 ou 4.
func tocar(eventos: Array[Dictionary], velocidade: int) -> void:
	_velocidade = clampi(velocidade, 1, 4)
	_velocidade_b.text = "%d×" % _velocidade
	_fila.clear()
	var achou: bool = false
	for ev: Dictionary in eventos:
		if str(ev.get("type", "")) == "luta":
			achou = true
		if achou:
			_fila.append(ev)
	if _fila.is_empty():
		terminada = true
		return
	_posicionar()
	_aplicar(_fila.pop_front())
	_timer.start(intervalo_s())


func intervalo_s() -> float:
	return INTERVALO_S / _velocidade


## Passa para a próxima velocidade (1× → 2× → 4× → 1×) e guarda a escolha nos Ajustes; vale a
## partir da próxima troca.
func trocar_velocidade() -> void:
	var i: int = Ajustes.VELOCIDADES.find(_velocidade)
	_velocidade = Ajustes.VELOCIDADES[(i + 1) % Ajustes.VELOCIDADES.size()]
	_velocidade_b.text = "%d×" % _velocidade
	Ajustes.definir_velocidade(_velocidade)
	if not _timer.is_stopped():
		_timer.wait_time = intervalo_s()


## Toca o resto de uma vez, sem animação, e mostra o resultado.
func pular() -> void:
	_descarregar()
	while not _fila.is_empty():
		_aplicar(_fila.pop_front(), false)
	_terminar()


func fechar() -> void:
	terminou.emit({"vitoria": _vitoria})
	queue_free()


func resultado_texto() -> String:
	if _premios.is_empty():
		return _resultado_texto.text
	return _resultado_texto.text + "\n" + _resultado_premios.text


func _passo() -> void:
	_descarregar()
	if _fila.is_empty():
		_terminar()
		return
	_aplicar(_fila.pop_front())


func _terminar() -> void:
	if terminada:
		return
	terminada = true
	_timer.stop()
	_velocidade_b.hide()
	_resultado_texto.text = "Vitória!" if _vitoria else "Derrota! Treine e tente de novo."
	_resultado_premios.text = "\n".join(_premios)
	_resultado_premios.visible = not _premios.is_empty()
	_resultado.show()


func _aplicar(ev: Dictionary, animado: bool = true) -> void:
	match str(ev.get("type", "")):
		"luta":
			_comecar(ev)
		"golpe", "critico":
			var a: int = int(ev["atacante"])
			var critico: bool = str(ev["type"]) == "critico"
			var hp: Array = ev["hp"]
			var dano: String = "−%d" % int(ev["dano"])
			_golpear(
				a,
				animado,
				"critico" if critico else "ataque",
				func() -> void:
					_lado(1 - a).animar("golpe")
					heroi.vida(int(hp[0]), animado)
					inimigo.vida(int(hp[1]), animado)
					_numero(_lado(1 - a), dano, critico, animado)
					if animado and critico:
						_tremor()
			)
			var texto: String = "%s acerta %s" % [_nomes[a], _nomes[1 - a]]
			_narracao.text = ("Golpe crítico! " + texto) if critico else texto
		"esquiva":
			var a2: int = int(ev["atacante"])
			_golpear(
				a2,
				animado,
				"ataque",
				func() -> void:
					_lado(1 - a2).animar("esquiva")
					_numero(_lado(1 - a2), "Esquivou!", false, animado)
			)
			_narracao.text = "%s esquiva" % _nomes[1 - a2]
		"fim":
			_vitoria = int(ev["vencedor"]) == 0
			_lado(1 if _vitoria else 0).animar("derrota")
			_lado(0 if _vitoria else 1).animar("vitoria")
		"vintens_ganhos":
			_premios.append("+%d vinténs" % int(ev["amount"]))
		"xp_ganho":
			_premios.append("+%d de experiência" % int(ev["amount"]))
		"muiraquitas_ganhas":
			_premios.append("+%d muiraquitãs" % int(ev["amount"]))
		"subiu_nivel":
			_premios.append("Subiu para o nível %d!" % int(ev["lvl"]))
		"item_ganho":
			_premios.append("Item novo: %s" % str(ev["nome"]))


func _comecar(ev: Dictionary) -> void:
	var h: Dictionary = ev["heroi"]
	var i: Dictionary = ev["inimigo"]
	_nomes = [str(h["nome"]), str(i["nome"])]
	var service: Node = get_node_or_null("/root/GameService")
	var state: GameState = null if service == null else service.call("get_state")
	var rules: RulesPack = null if service == null else service.call("get_rules")
	var equip: Dictionary = {} if state == null else state.equip
	heroi.preparar(_nomes[0], int(h["lvl"]), int(h["hp"]), null, "heroi", equip, rules)
	var lenda: String = str(i.get("legend_id", ""))
	var carta: Texture2D = CartaLib.textura(lenda)
	inimigo.preparar(_nomes[1], int(i["lvl"]), int(i["hp"]), carta, lenda)
	_fundo.texture = carta
	_placar_nomes[0].text = str(heroi.get_meta("nome"))
	_placar_nomes[1].text = str(inimigo.get_meta("nome"))
	_narracao.text = "%s enfrenta %s" % [_nomes[0], _nomes[1]]


func _montar_placar() -> void:
	var placar := HBoxContainer.new()
	placar.name = "Placar"
	placar.anchor_left = 0.0
	placar.anchor_right = 1.0
	placar.offset_left = 24
	placar.offset_right = -24
	placar.offset_top = 40
	placar.add_theme_constant_override("separation", 24)
	add_child(placar)
	for lado: int in 2:
		var caixa := VBoxContainer.new()
		caixa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		placar.add_child(caixa)
		var nome := AbaBase.rotulo("", &"Valor")
		nome.autowrap_mode = TextServer.AUTOWRAP_OFF
		nome.clip_text = true
		nome.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		nome.horizontal_alignment = (
			HORIZONTAL_ALIGNMENT_LEFT if lado == 0 else HORIZONTAL_ALIGNMENT_RIGHT
		)
		caixa.add_child(nome)
		_placar_nomes.append(nome)
		var barra := ProgressBar.new()
		barra.theme_type_variation = &"BarraVida"
		barra.show_percentage = false
		barra.custom_minimum_size = Vector2(0, 26)
		barra.fill_mode = (
			ProgressBar.FILL_BEGIN_TO_END if lado == 0 else ProgressBar.FILL_END_TO_BEGIN
		)
		caixa.add_child(barra)
		var pv := AbaBase.rotulo("", &"Dica")
		pv.horizontal_alignment = nome.horizontal_alignment
		caixa.add_child(pv)
		var l: Lutador = heroi if lado == 0 else inimigo
		l.barra = barra
		l.rotulo_pv = pv


func _posicionar() -> void:
	var w: float = size.x if size.x > 0 else 720.0
	var h: float = size.y if size.y > 0 else 1280.0
	heroi.position = Vector2(w * POS_HEROI, h * CHAO + PISO)
	inimigo.position = Vector2(w * POS_INIMIGO, h * CHAO + PISO)


func _lado(i: int) -> Lutador:
	return heroi if i == 0 else inimigo


## Um ataque: animado, o atacante corre até o alvo já golpeando (`acao`), com o punho esticado
## no contato, e `impacto` (reação do alvo, vida e número) acontece só no contato; sem animação,
## tudo é aplicado na hora.
func _golpear(a: int, animado: bool, acao: String, impacto: Callable) -> void:
	_descarregar()
	if not animado or not is_inside_tree():
		_lado(a).animar(acao)
		impacto.call()
		return
	_impacto = impacto
	_lado(a).animar(acao, intervalo_s() * CORRIDA)
	_avancar(_lado(a), _lado(1 - a))


## Aplica o impacto pendente, se houver (no contato, ao pular ou antes do próximo evento).
func _descarregar() -> void:
	if _impacto.is_valid():
		var f: Callable = _impacto
		_impacto = Callable()
		f.call()


## O atacante corre até a frente do alvo, golpeia, segura um instante e volta; o alvo recua no
## contato.
func _avancar(atacante: Lutador, alvo: Lutador) -> void:
	avancos += 1
	_posicionar()
	var origem: float = atacante.position.x
	var destino: float = alvo.position.x - distancia_golpe(atacante, alvo) * atacante.direcao
	var t: float = intervalo_s()
	var alvo_x: float = alvo.position.x
	var tw: Tween = create_tween()
	tw.tween_property(atacante, "position:x", destino, t * CORRIDA).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(_descarregar)
	tw.tween_property(alvo, "position:x", alvo_x - RECUO * alvo.direcao, t * 0.08)
	tw.tween_interval(t * 0.17)
	tw.tween_callback(atacante.recolher)
	tw.tween_property(atacante, "position:x", origem, t * 0.3).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(alvo, "position:x", alvo_x, t * 0.3).set_trans(Tween.TRANS_SINE)


## Distância entre os pés dos dois no golpe: o punho esticado do atacante encosta na frente do
## corpo do alvo, medidos nos desenhos. Sem desenho para medir, usa ALCANCE.
func distancia_golpe(atacante: Lutador, alvo: Lutador) -> float:
	var punho: float = atacante.alcance()
	var corpo: float = alvo.frente()
	if punho < 0 or corpo < 0:
		return ALCANCE
	return punho + corpo - SOBREPOR


func _numero(alvo: Lutador, texto: String, critico: bool, animado: bool) -> void:
	numeros_mostrados.append(texto)
	if not animado or not is_inside_tree():
		return
	var n := Label.new()
	n.text = texto
	n.add_theme_font_size_override("font_size", 64 if critico else 44)
	n.add_theme_color_override("font_color", COR_CRITICO if critico else COR_DANO)
	n.add_theme_color_override("font_outline_color", Color("140d08"))
	n.add_theme_constant_override("outline_size", 10)
	n.position = alvo.position + Vector2(-50, -420)
	_palco.add_child(n)
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(n, "position:y", n.position.y - 80.0, intervalo_s())
	tw.tween_property(n, "modulate:a", 0.0, intervalo_s()).set_delay(intervalo_s() * 0.4)
	tw.chain().tween_callback(n.queue_free)


func _tremor() -> void:
	if not is_inside_tree():
		return
	var tw: Tween = create_tween()
	for dx: float in [10.0, -10.0, 7.0, -7.0, 0.0]:
		tw.tween_property(_palco, "position:x", dx, 0.04)
	var fl: Tween = create_tween()
	fl.tween_property(_flash, "color:a", 0.55, 0.04)
	fl.tween_property(_flash, "color:a", 0.0, 0.1)


## Chão do palco: terra batida com uma faixa de capim, em blocos de pixel.
class Chao:
	extends Control

	var altura: float = 0.72

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var y: float = size.y * altura
		draw_rect(Rect2(0, y, size.x, size.y - y), Color("5a3d24"))
		draw_rect(Rect2(0, y, size.x, 10), Color("3f6b34"))
		var bloco: float = 8.0
		var i: int = 0
		var x: float = 0.0
		while x < size.x:
			var alto: float = bloco * float(1 + (i * 7) % 3)
			draw_rect(Rect2(x, y - alto + 4, bloco, alto), Color("4f8a3e"))
			draw_rect(
				Rect2(x + 3 * bloco, y + 40 + (i % 4) * 22, bloco * 2, bloco), Color("4a3220")
			)
			x += bloco * 5
			i += 1

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()
