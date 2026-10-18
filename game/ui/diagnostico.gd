extends Control
## Tela de diagnóstico da casca: selo de modo, guardião, recursos com recarga ao vivo e três ações.
## Só lê o estado do `GameService` e envia comandos; a recarga vem pronta de `stamina_view()`.

const MENU_SCENE: String = "res://ui/menu.tscn"
const LUTA_SCENE: PackedScene = preload("res://ui/luta_teste.tscn")
const ESPERA_DELAY_S: float = 0.3
const STAMINA_POLL_S: float = 1.0
const ACT: int = 0

var _running: bool = false
## O ato acabou: veio `ato_concluido`, ou a fase atual respondeu FASE_BLOQUEADA.
var _act_done: bool = false
var _avisos_mostrados: Array[String] = []
var _espera_timer: Timer
var _stamina_timer: Timer
var _spin: Tween

@onready var _service: Node = get_node("/root/GameService")
@onready var _voltar: Button = %Voltar
@onready var _nome: LineEdit = %Nome
@onready var _salvar_nome: Button = %SalvarNome
@onready var _nivel: Label = %NivelValor
@onready var _vintens: Label = %VintensValor
@onready var _muir: Label = %MuirValor
@onready var _atributos: Label = %Atributos
@onready var _energia_valor: Label = %EnergiaValor
@onready var _energia_barra: ProgressBar = %EnergiaBarra
@onready var _energia_recarga: Label = %EnergiaRecarga
@onready var _coragem_valor: Label = %CoragemValor
@onready var _coragem_barra: ProgressBar = %CoragemBarra
@onready var _coragem_recarga: Label = %CoragemRecarga
@onready var _treinar: Button = %TreinarForca
@onready var _missao: Button = %MissaoRapida
@onready var _fase: Button = %EnfrentarFase
@onready var _espera: Control = %Espera
@onready var _giro: Control = %Giro
@onready var _mensagem: Label = %Mensagem
@onready var _avisos: VBoxContainer = %Avisos


func _ready() -> void:
	_espera_timer = Timer.new()
	_espera_timer.one_shot = true
	_espera_timer.wait_time = ESPERA_DELAY_S
	_espera_timer.timeout.connect(_show_espera)
	add_child(_espera_timer)
	_stamina_timer = Timer.new()
	_stamina_timer.wait_time = STAMINA_POLL_S
	_stamina_timer.timeout.connect(_refresh_stamina)
	add_child(_stamina_timer)
	_stamina_timer.start()
	_service.connect("state_changed", _on_state_changed)
	_service.connect("busy_changed", _on_busy_changed)
	_service.connect("warning", _on_warning)
	_voltar.pressed.connect(_on_voltar)
	_salvar_nome.pressed.connect(_on_salvar_nome)
	_nome.text_submitted.connect(_on_nome_submitted)
	_treinar.pressed.connect(_on_treinar)
	_missao.pressed.connect(_on_missao_rapida)
	_fase.pressed.connect(_on_enfrentar_fase)
	_espera.visible = false
	_mensagem.text = ""
	for code: String in Textos.avisos_do_boot():
		_on_warning(code)
	_refresh(_state())
	_sync_busy()


func _state() -> GameState:
	return _service.call("get_state") as GameState


# --- Leitura do estado ---------------------------------------------------------------------


func _on_state_changed(state: GameState) -> void:
	_refresh(state)


func _refresh(state: GameState) -> void:
	if state != null:
		if not _nome.has_focus():
			_nome.text = state.nome
		_nivel.text = str(state.lvl)
		_vintens.text = str(state.vint)
		_muir.text = str(state.muir)
		_atributos.text = (
			"Força %d · Fôlego %d · Malícia %d · Ginga %d"
			% [
				int(state.stats.get("for", 0)),
				int(state.stats.get("fol", 0)),
				int(state.stats.get("mal", 0)),
				int(state.stats.get("gin", 0)),
			]
		)
	_refresh_fase_label(state)
	_refresh_stamina()


func _refresh_fase_label(state: GameState) -> void:
	if _act_done:
		_fase.text = "Ato concluído"
	elif state != null and ACT < state.fases.size():
		_fase.text = "Enfrentar fase %d" % (state.fases[ACT] + 1)
	else:
		_fase.text = "Enfrentar fase 1"


func _refresh_stamina() -> void:
	var v: Dictionary = _service.call("stamina_view")
	if v.is_empty():
		for rotulo: Label in [_energia_valor, _coragem_valor, _energia_recarga, _coragem_recarga]:
			rotulo.text = "—"
		return
	_show_bar(_energia_barra, _energia_valor, _energia_recarga, v, "energia", "en")
	_show_bar(_coragem_barra, _coragem_valor, _coragem_recarga, v, "coragem", "co")


static func _show_bar(
	barra: ProgressBar, valor: Label, recarga: Label, v: Dictionary, key: String, prefix: String
) -> void:
	var cur: int = int(v[key])
	var cap: int = int(v[prefix + "_max"])
	var next_ms: int = int(v[prefix + "_next_ms"])
	barra.max_value = maxi(1, cap)
	barra.value = cur
	valor.text = "%d / %d" % [cur, cap]
	recarga.text = "Cheia" if next_ms <= 0 else "+1 em %s" % Textos.relogio(next_ms)


# --- Ocupado ---------------------------------------------------------------------------------


func _on_busy_changed(_busy: bool) -> void:
	_sync_busy()


func _is_busy() -> bool:
	return _running or bool(_service.call("is_busy"))


func _sync_busy() -> void:
	var busy: bool = _is_busy()
	for b: Button in [_salvar_nome, _treinar, _missao, _voltar]:
		b.disabled = busy
	_fase.disabled = busy or _act_done
	_nome.editable = not busy
	if busy:
		if not _espera.visible and _espera_timer.is_stopped():
			_espera_timer.start()
	else:
		_espera_timer.stop()
		_hide_espera()


func _show_espera() -> void:
	if not _is_busy():
		return
	_espera.visible = true
	_giro.pivot_offset = _giro.size / 2.0
	if _spin != null:
		_spin.kill()
	_spin = create_tween().set_loops()
	_spin.tween_property(_giro, "rotation", TAU, 0.8).from(0.0)


func _hide_espera() -> void:
	_espera.visible = false
	if _spin != null:
		_spin.kill()
		_spin = null


func _begin() -> void:
	_running = true
	_mensagem.text = ""
	_sync_busy()


func _end() -> void:
	_running = false
	_sync_busy()


## Envia um comando; em erro, mostra a frase em português e devolve null.
func _send(type: String, params: Dictionary = {}) -> CommandResult:
	var res: CommandResult = await _service.call("send", type, params)
	if res == null or not res.ok:
		_show_error(Textos.erro("ERRO_EXECUTOR" if res == null else res.error))
		return null
	return res


# --- Ações -----------------------------------------------------------------------------------


func _on_nome_submitted(_text: String) -> void:
	_on_salvar_nome()


func _on_salvar_nome() -> void:
	if _is_busy():
		return
	_begin()
	_nome.release_focus()
	var res: CommandResult = await _send("renomear", {"nome": _nome.text})
	if res != null:
		_nome.text = res.state.nome
		_show_ok("Nome salvo: %s." % res.state.nome)
	_end()


func _on_treinar() -> void:
	if _is_busy():
		return
	_begin()
	var res: CommandResult = await _send("treinar", {"stat": "for"})
	if res != null:
		_show_ok("Treino feito! Força agora é %d." % int(res.state.stats["for"]))
	_end()


## Missão rápida: começa a missão mais curta, acelera e conclui. Se já há uma em andamento,
## segue dela. Para no primeiro erro e mostra o motivo.
func _on_missao_rapida() -> void:
	if _is_busy():
		return
	_begin()
	await _missao_rapida()
	_end()


func _missao_rapida() -> void:
	var state: GameState = _state()
	if state.ativa.is_empty():
		var id: int = _shortest_offer(state)
		if id < 0:
			_show_error("Nenhuma missão disponível agora. Volte daqui a pouco.")
			return
		var started: CommandResult = await _send("iniciar_missao", {"mission_id": id})
		if started == null:
			return
	var boosted: CommandResult = await _send("acelerar_missao")
	if boosted == null:
		return
	var res: CommandResult = await _send("concluir_missao")
	if res == null:
		return
	var ganho: Dictionary = _sum_rewards(res.events)
	var venceu: bool = true
	for e: Dictionary in res.events:
		if e["type"] == "missao_concluida":
			venceu = bool(e["win"])
	if venceu:
		_show_ok(
			(
				"Missão concluída! +%d vinténs, +%d de experiência."
				% [ganho["vintens_ganhos"], ganho["xp_ganho"]]
			)
		)
	else:
		_show_error("A lenda venceu a luta da missão. Treine e tente de novo.")
	if _has_fight(res.events):
		_open_luta(res.events)


func _on_enfrentar_fase() -> void:
	if _is_busy() or _act_done:
		return
	_begin()
	var state: GameState = _state()
	var n: int = state.fases[ACT]
	var res: CommandResult = await _service.call("send", "enfrentar_fase", {"act": ACT, "n": n})
	if res == null or not res.ok:
		var code: String = "ERRO_EXECUTOR" if res == null else res.error
		if code == "FASE_BLOQUEADA":
			# `n` é a fase atual do estado: bloqueada só se o ato já terminou.
			_act_done = true
			_show_ok("Você já venceu todas as fases deste ato.")
		else:
			_show_error(Textos.erro(code))
	else:
		var venceu: bool = false
		for e: Dictionary in res.events:
			if e["type"] == "fase_vencida":
				venceu = true
			if e["type"] == "ato_concluido" and int(e["act"]) == ACT:
				_act_done = true
		if venceu:
			var ganho: Dictionary = _sum_rewards(res.events)
			_show_ok("Fase %d vencida! +%d vinténs." % [n + 1, ganho["vintens_ganhos"]])
		else:
			_show_error("Derrota na fase %d. Treine e tente de novo depois da espera." % (n + 1))
		_open_luta(res.events)
	_refresh_fase_label(_state())
	_end()


func _on_voltar() -> void:
	if _is_busy():
		return
	get_tree().change_scene_to_file(MENU_SCENE)


# --- Apoio -----------------------------------------------------------------------------------


## Escolhe a oferta de menor duração (empate: a primeira). Só lê o estado; -1 se não houver.
static func _shortest_offer(state: GameState) -> int:
	var best_id: int = -1
	var best_dur: int = 0
	for m: Dictionary in state.ofertas:
		var dur: int = int(m["dur"])
		if best_id < 0 or dur < best_dur:
			best_id = int(m["id"])
			best_dur = dur
	return best_id


static func _sum_rewards(events: Array[Dictionary]) -> Dictionary:
	var out: Dictionary = {"vintens_ganhos": 0, "xp_ganho": 0}
	for e: Dictionary in events:
		var t: String = str(e["type"])
		if out.has(t):
			out[t] = int(out[t]) + int(e["amount"])
	return out


static func _has_fight(events: Array[Dictionary]) -> bool:
	for e: Dictionary in events:
		if e["type"] == "luta":
			return true
	return false


func _open_luta(events: Array[Dictionary]) -> void:
	var luta: Control = LUTA_SCENE.instantiate() as Control
	add_child(luta)
	luta.call("play", events)


func _show_ok(texto: String) -> void:
	_mensagem.theme_type_variation = &"Sucesso"
	_mensagem.text = texto


func _show_error(texto: String) -> void:
	_mensagem.theme_type_variation = &"Erro"
	_mensagem.text = texto


func _on_warning(code: String) -> void:
	if _avisos_mostrados.has(code):
		return
	_avisos_mostrados.append(code)
	var painel := PanelContainer.new()
	painel.theme_type_variation = &"Aviso"
	var rotulo := Label.new()
	rotulo.text = Textos.aviso(code)
	rotulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rotulo.add_theme_font_size_override("font_size", 26)
	painel.add_child(rotulo)
	_avisos.add_child(painel)
