extends AbaBase
## Aba Torre dos Chefes: 3 atos de 10 fases. Só a próxima fase de cada ato pode ser enfrentada;
## cadeado por nível e espera depois de perder para um chefe.

var _espera: Label
var _botoes: Dictionary[String, Button] = {}


func _montar(corpo: VBoxContainer) -> void:
	contexto = "torre"
	corpo.add_child(rotulo("Torre dos Chefes", &"Titulo"))
	_espera = rotulo("", &"Erro", "Espera")
	corpo.add_child(_espera)
	var r: RulesPack = regras()
	if r == null:
		return
	for a: int in r.acts.size():
		var ato: Defs.ActDef = r.acts[a]
		var painel := cartao()
		painel.name = "Ato_%d" % a
		var caixa := VBoxContainer.new()
		painel.add_child(caixa)
		caixa.add_child(rotulo("%s · níveis %d a %d" % [ato.nome, ato.de, ato.ate], &"Valor"))
		var grade := GridContainer.new()
		grade.columns = 2
		caixa.add_child(grade)
		for n: int in ato.stages.size():
			var b := botao("Fase_%d_%d" % [a, n], "")
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			b.pressed.connect(func() -> void: enviar("enfrentar_fase", {"act": a, "n": n}))
			grade.add_child(b)
			_botoes["%d_%d" % [a, n]] = b
		corpo.add_child(painel)
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(atualizar)
	add_child(timer)


func atualizar() -> void:
	var s: GameState = estado()
	var r: RulesPack = regras()
	if s == null or r == null or _espera == null:
		return
	var agora: int = agora_ms()
	var falta: int = s.chefe_espera_ms - agora
	_espera.visible = falta > 0
	_espera.text = "Recuperando da última derrota: %s" % Textos.relogio(falta)
	var busy: bool = ocupado()
	for a: int in r.acts.size():
		var stages: Array[Defs.StageDef] = r.acts[a].stages
		var proxima: int = s.fases[a] if a < s.fases.size() else 0
		for n: int in stages.size():
			var b: Button = _botoes.get("%d_%d" % [a, n])
			if b == null:
				continue
			var nivel: int = Stages.required_level(a, n, r)
			var chefe: String = "Chefe: " if Stages.is_boss(a, n, r) else ""
			if n < proxima:
				b.text = "Vencida · %s%s" % [chefe, stages[n].nome]
				b.disabled = true
			elif n > proxima:
				b.text = "Fechada · %s%s" % [chefe, stages[n].nome]
				b.disabled = true
			elif s.lvl < nivel:
				b.text = "Fechada · %s%s · Nível %d" % [chefe, stages[n].nome, nivel]
				b.disabled = true
			else:
				b.text = "%s%s · enfrentar" % [chefe, stages[n].nome]
				b.disabled = busy or falta > 0
