class_name Luta
extends Control
## Camada de luta sobre a aba: toca os eventos do núcleo (luta, golpe, critico, esquiva, fim)
## com animação e narração, depois mostra o resultado com as recompensas. Velocidade 1×/2×/4×
## e botão Pular. A luta já foi resolvida no núcleo: pular ou pausar o app não muda nada.

signal terminou(resultado: Dictionary)

const INTERVALO_S: float = 0.4

var heroi: Lutador
var inimigo: Lutador
var terminada: bool = false
var _fila: Array[Dictionary] = []
var _velocidade: int = 1
var _nomes: Array[String] = ["", ""]
var _vitoria: bool = false
var _premios: Array[String] = []
var _timer: Timer
var _narracao: Label
var _resultado: PanelContainer
var _resultado_texto: Label
var _flash: ColorRect


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var fundo := ColorRect.new()
	fundo.color = Color(0.07, 0.045, 0.03, 1.0)
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)
	var caixa := VBoxContainer.new()
	caixa.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	caixa.offset_left = 24
	caixa.offset_right = -24
	caixa.offset_top = 60
	caixa.offset_bottom = -40
	caixa.alignment = BoxContainer.ALIGNMENT_CENTER
	caixa.add_theme_constant_override("separation", 24)
	add_child(caixa)
	var lados := HBoxContainer.new()
	caixa.add_child(lados)
	heroi = Lutador.new()
	heroi.direcao = 1
	lados.add_child(heroi)
	inimigo = Lutador.new()
	inimigo.direcao = -1
	lados.add_child(inimigo)
	_narracao = Label.new()
	_narracao.name = "Narracao"
	_narracao.theme_type_variation = &"Valor"
	_narracao.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_narracao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_narracao.custom_minimum_size = Vector2(0, 90)
	caixa.add_child(_narracao)
	var pular_b := AbaBase.botao("Pular", "Pular")
	pular_b.pressed.connect(pular)
	caixa.add_child(pular_b)
	_resultado = AbaBase.cartao()
	_resultado.name = "Resultado"
	var rcaixa := VBoxContainer.new()
	_resultado.add_child(rcaixa)
	_resultado_texto = AbaBase.rotulo("", &"Titulo", "ResultadoTexto")
	_resultado_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rcaixa.add_child(_resultado_texto)
	var ok := AbaBase.botao("Fechar", "Continuar", true)
	ok.pressed.connect(fechar)
	rcaixa.add_child(ok)
	_resultado.hide()
	caixa.add_child(_resultado)
	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_flash)
	_timer = Timer.new()
	_timer.timeout.connect(_passo)
	add_child(_timer)


## Começa a tocar `eventos` (a partir do evento `luta`) na `velocidade` 1, 2 ou 4.
func tocar(eventos: Array[Dictionary], velocidade: int) -> void:
	_velocidade = clampi(velocidade, 1, 4)
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
	_aplicar(_fila.pop_front())
	_timer.start(intervalo_s())


func intervalo_s() -> float:
	return INTERVALO_S / _velocidade


## Toca o resto de uma vez, sem animação, e mostra o resultado.
func pular() -> void:
	while not _fila.is_empty():
		_aplicar(_fila.pop_front(), false)
	_terminar()


func fechar() -> void:
	terminou.emit({"vitoria": _vitoria})
	queue_free()


func resultado_texto() -> String:
	return _resultado_texto.text


func _passo() -> void:
	if _fila.is_empty():
		_terminar()
		return
	_aplicar(_fila.pop_front())


func _terminar() -> void:
	if terminada:
		return
	terminada = true
	_timer.stop()
	var linhas: Array[String] = ["Vitória!" if _vitoria else "Derrota! Treine e tente de novo."]
	linhas.append_array(_premios)
	_resultado_texto.text = "\n".join(linhas)
	_resultado.show()


func _aplicar(ev: Dictionary, animado: bool = true) -> void:
	match str(ev.get("type", "")):
		"luta":
			var h: Dictionary = ev["heroi"]
			var i: Dictionary = ev["inimigo"]
			_nomes = [str(h["nome"]), str(i["nome"])]
			heroi.preparar(_nomes[0], int(h["lvl"]), int(h["hp"]), null)
			var carta: Texture2D = CartaLib.textura(str(i.get("legend_id", "")))
			inimigo.preparar(_nomes[1], int(i["lvl"]), int(i["hp"]), carta)
			_narracao.text = "%s enfrenta %s" % [_nomes[0], _nomes[1]]
		"golpe", "critico":
			var a: int = int(ev["atacante"])
			var critico: bool = str(ev["type"]) == "critico"
			_lado(a).animar("critico" if critico else "ataque")
			_lado(1 - a).animar("golpe")
			var hp: Array = ev["hp"]
			heroi.vida(int(hp[0]))
			inimigo.vida(int(hp[1]))
			var texto: String = "%s acerta %s: −%d PV" % [_nomes[a], _nomes[1 - a], int(ev["dano"])]
			_narracao.text = ("Golpe crítico! " + texto) if critico else texto
			if critico and animado:
				_tremor()
		"esquiva":
			var a2: int = int(ev["atacante"])
			_lado(a2).animar("ataque")
			_lado(1 - a2).animar("esquiva")
			_narracao.text = "%s esquiva" % _nomes[1 - a2]
		"fim":
			_vitoria = int(ev["vencedor"]) == 0
			_lado(1 if _vitoria else 0).animar("derrota")
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


func _lado(i: int) -> Lutador:
	return heroi if i == 0 else inimigo


func _tremor() -> void:
	if not is_inside_tree():
		return
	var tw: Tween = create_tween()
	for dx: float in [8.0, -8.0, 6.0, -6.0, 0.0]:
		tw.tween_property(self, "position:x", dx, 0.04)
	var fl: Tween = create_tween()
	fl.tween_property(_flash, "color:a", 0.6, 0.04)
	fl.tween_property(_flash, "color:a", 0.0, 0.08)
