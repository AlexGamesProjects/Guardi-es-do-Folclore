extends CanvasLayer
## Autoload `PerfOverlay`: painel de desempenho escondido (5 toques na versão, no menu).
## A cada 500 ms mostra FPS (atual e o mínimo da janela), tempo médio por quadro, memória estática,
## modo, `save_version`, `rules_version` e a `schema_version` do pacote de regras.
## Só mede no aparelho; nada sai dele.
## A memória estática só é contada em builds de depuração; na de lançamento aparece indisponível.

const INTERVAL_S: float = 0.5
const THEME_PATH: String = "res://ui/theme.tres"
const BYTES_PER_MB: float = 1048576.0

var _panel: PanelContainer
var _texto: Label
var _timer: Timer
var _frames: int = 0
var _sum_delta: float = 0.0
var _max_delta: float = 0.0


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = PanelContainer.new()
	_panel.name = "Painel"
	_panel.theme = load(THEME_PATH) as Theme
	_panel.theme_type_variation = &"PainelPerf"
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.position = Vector2(16, 96)
	_texto = Label.new()
	_texto.name = "Texto"
	_texto.theme_type_variation = &"PerfTexto"
	_texto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_texto)
	add_child(_panel)
	_timer = Timer.new()
	_timer.wait_time = INTERVAL_S
	_timer.timeout.connect(_refresh)
	add_child(_timer)
	set_open(false)


func toggle() -> void:
	set_open(not is_open())


func is_open() -> bool:
	return _panel != null and _panel.visible


func set_open(value: bool) -> void:
	if _panel == null:
		return
	_panel.visible = value
	set_process(value)
	if value:
		_reset_window()
		_refresh()
		_timer.start()
	else:
		_timer.stop()


func _process(delta: float) -> void:
	_frames += 1
	_sum_delta += delta
	_max_delta = maxf(_max_delta, delta)


func _refresh() -> void:
	var fps: float = Performance.get_monitor(Performance.TIME_FPS)
	var frame_ms: float = 0.0
	var worst_fps: float = fps
	if _frames > 0:
		frame_ms = _sum_delta / _frames * 1000.0
	if _max_delta > 0.0:
		worst_fps = 1.0 / _max_delta
	var mem_mb: float = Performance.get_monitor(Performance.MEMORY_STATIC) / BYTES_PER_MB
	var service: Node = get_node_or_null("/root/GameService")
	var mode: String = "—"
	var rules_version: String = ""
	var schema_version: int = 0
	if service != null:
		var state: GameState = service.call("get_state") as GameState
		if state != null:
			mode = state.mode
		rules_version = str(service.call("get_rules_version"))
		schema_version = int(service.call("get_schema_version"))
	var lines: PackedStringArray = [
		"FPS %d (mín. %d)" % [roundi(fps), roundi(worst_fps)],
		"Quadro %.1f ms" % frame_ms if _frames > 0 else "Quadro —",
		"Memória %.1f MB" % mem_mb if mem_mb > 0.0 else "Memória indisponível nesta build",
		"Modo %s" % mode,
		(
			"Save v%d · Regras %s · Esquema %s"
			% [
				SaveCodec.SAVE_VERSION,
				rules_version if rules_version else "—",
				str(schema_version) if schema_version > 0 else "—",
			]
		),
	]
	_texto.text = "\n".join(lines)
	_reset_window()


func _reset_window() -> void:
	_frames = 0
	_sum_delta = 0.0
	_max_delta = 0.0
