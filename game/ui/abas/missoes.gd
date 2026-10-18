extends AbaBase
## Aba Missões: 3 ofertas, missão em andamento com tempo restante, acelerar, concluir e renovar.

const DIFICULDADE: Array[String] = ["Fácil", "Média", "Difícil"]

var _ofertas: VBoxContainer
var _ativa: PanelContainer
var _ativa_texto: Label
var _tempo: Label
var _acelerar: Button
var _concluir: Button
var _renovar: Button


func _montar(corpo: VBoxContainer) -> void:
	contexto = "missao"
	corpo.add_child(rotulo("Missões", &"Titulo"))
	_ativa = cartao()
	_ativa.name = "Ativa"
	var caixa := VBoxContainer.new()
	_ativa.add_child(caixa)
	_ativa_texto = rotulo("", &"Valor")
	caixa.add_child(_ativa_texto)
	_tempo = rotulo("", &"Dica", "TempoRestante")
	caixa.add_child(_tempo)
	_acelerar = botao("Acelerar", "Acelerar (1 muiraquitã)")
	_acelerar.pressed.connect(func() -> void: enviar("acelerar_missao"))
	caixa.add_child(_acelerar)
	_concluir = botao("Concluir", "Concluir missão", true)
	_concluir.pressed.connect(func() -> void: enviar("concluir_missao"))
	caixa.add_child(_concluir)
	corpo.add_child(_ativa)
	_ofertas = VBoxContainer.new()
	_ofertas.add_theme_constant_override("separation", 12)
	corpo.add_child(_ofertas)
	_renovar = botao("Renovar", "Novas missões (1 muiraquitã)")
	_renovar.pressed.connect(func() -> void: enviar("renovar_missoes"))
	corpo.add_child(_renovar)
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_atualizar_tempo)
	add_child(timer)


func atualizar() -> void:
	var s: GameState = estado()
	var r: RulesPack = regras()
	if s == null or r == null or _ofertas == null:
		return
	var busy: bool = ocupado()
	_ativa.visible = not s.ativa.is_empty()
	if _ativa.visible:
		_ativa_texto.text = _frase(s.ativa, r)
	for filho: Node in _ofertas.get_children():
		_ofertas.remove_child(filho)
		filho.queue_free()
	for i: int in s.ofertas.size():
		_ofertas.add_child(_oferta(i, s.ofertas[i], r, busy or _ativa.visible))
	_renovar.disabled = busy or _ativa.visible
	_acelerar.disabled = busy
	_concluir.disabled = busy
	_atualizar_tempo()


func _atualizar_tempo() -> void:
	var s: GameState = estado()
	if s == null or s.ativa.is_empty():
		return
	var falta: int = int(s.ativa["fim_ms"]) - agora_ms()
	_concluir.visible = falta <= 0
	_acelerar.visible = falta > 0
	_tempo.text = "Pronta!" if falta <= 0 else "Termina em %s" % Textos.relogio(falta)


func _oferta(i: int, m: Dictionary, r: RulesPack, travado: bool) -> PanelContainer:
	var painel := cartao()
	var caixa := VBoxContainer.new()
	painel.add_child(caixa)
	caixa.add_child(rotulo(_frase(m, r), &"Valor"))
	(
		caixa
		. add_child(
			rotulo(
				(
					"%s · %s · %d de energia · +%d XP · +%d vinténs%s"
					% [
						DIFICULDADE[clampi(int(m["d"]), 0, 2)],
						Textos.relogio(int(m["dur"]) * 1000),
						int(m["en"]),
						int(m["xp"]),
						int(m["vint"]),
						" · luta" if bool(m["luta"]) else "",
					]
				),
				&"Dica"
			)
		)
	)
	var b := botao("Iniciar_%d" % i, "Começar", true)
	b.disabled = travado
	b.pressed.connect(func() -> void: enviar("iniciar_missao", {"mission_id": int(m["id"])}))
	caixa.add_child(b)
	return painel


static func _frase(m: Dictionary, r: RulesPack) -> String:
	var lenda: Defs.LegendDef = r.legends.get(str(m["c"]))
	if lenda == null:
		return "Missão"
	var lista: PackedStringArray = lenda.lutas if bool(m["luta"]) else lenda.tarefas
	var f: int = int(m["f"])
	var frase: String = lista[f] if f >= 0 and f < lista.size() else ""
	return "%s — %s" % [lenda.nome, frase]
