extends Control
## Tela inicial: escolha do modo ("Jornada Solo" ativo, "Roda Online" em breve), avisos do
## carregamento e do `GameService` (ex.: `SAVE_FALHOU`) e o rótulo da versão, que abre o painel
## de desempenho com 5 toques em até 2 s.
## Avisa `GF_READY` uma única vez, depois do primeiro quadro desenhado (a CI procura essa linha).

const JOGO_SCENE: String = "res://ui/jogo.tscn"
const CRIACAO_SCENE: String = "res://ui/criacao.tscn"
const TAPS_TO_TOGGLE: int = 5
const TAP_WINDOW_MS: int = 2000

static var _ready_announced: bool = false

## Fonte do instante dos toques, em ms. Os testes trocam por um relógio de mentira.
var ticks_ms: Callable = Time.get_ticks_msec
var _taps: Array[int] = []
var _avisos_mostrados: Array[String] = []

@onready var _solo: Button = %JornadaSolo
@onready var _versao: Button = %Versao
@onready var _avisos: VBoxContainer = %Avisos


func _ready() -> void:
	var versao: String = str(ProjectSettings.get_setting("application/config/version"))
	_versao.text = "versão %s" % versao
	_versao.pressed.connect(_on_versao_pressed)
	_solo.pressed.connect(_on_solo_pressed)
	var service: Node = get_node_or_null("/root/GameService")
	if service != null:
		service.connect("warning", _on_warning)
	for code: String in Textos.avisos_do_boot():
		_on_warning(code)
	await _first_frame_drawn()
	if not _ready_announced:
		_ready_announced = true
		print("GF_READY")


## Sem tela (headless), o renderizador de mentira não emite `frame_post_draw`: espera um quadro.
func _first_frame_drawn() -> void:
	if DisplayServer.get_name() == "headless":
		await get_tree().process_frame
	else:
		await RenderingServer.frame_post_draw


## Mostra o aviso em português, uma vez por código.
func _on_warning(code: String) -> void:
	if _avisos_mostrados.has(code):
		return
	_avisos_mostrados.append(code)
	_avisos.add_child(_aviso(Textos.aviso(code)))


func _on_solo_pressed() -> void:
	get_tree().change_scene_to_file(destino_solo())


## Perfil sem origem passa pela criação do guardião; os outros vão direto ao jogo.
func destino_solo() -> String:
	var service: Node = get_node_or_null("/root/GameService")
	var state: GameState = null if service == null else service.call("get_state")
	if state != null and state.origem == "":
		return CRIACAO_SCENE
	return JOGO_SCENE


func _on_versao_pressed() -> void:
	var now: int = int(ticks_ms.call())
	_taps.append(now)
	while not _taps.is_empty() and now - _taps[0] > TAP_WINDOW_MS:
		_taps.pop_front()
	if _taps.size() >= TAPS_TO_TOGGLE:
		_taps.clear()
		get_node("/root/PerfOverlay").call("toggle")


static func _aviso(texto: String) -> PanelContainer:
	var painel := PanelContainer.new()
	painel.theme_type_variation = &"Aviso"
	var rotulo := Label.new()
	rotulo.text = texto
	rotulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rotulo.add_theme_font_size_override("font_size", 26)
	painel.add_child(rotulo)
	return painel
