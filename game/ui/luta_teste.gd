extends Control
## Luta de teste: recebe a lista de eventos de um comando e mostra uma linha por evento, a cada
## `line_interval_ms`. Não calcula nada: nomes, dano e vida vêm prontos nos eventos do núcleo.

signal closed

const DIAGNOSTICO_SCENE: String = "res://ui/diagnostico.tscn"
const COR_HEROI: Color = Color("#efe7d4")
const COR_INIMIGO: Color = Color("#f0a08c")
const COR_CRITICO: Color = Color("#e8b860")
const COR_VITORIA: Color = Color("#5cc78c")
const COR_DERROTA: Color = Color("#f09078")
const COR_PREMIO: Color = Color("#b5a68a")

var line_interval_ms: int = 400

var _queue: Array[Dictionary] = []
var _names: Array[String] = ["", ""]
var _timer: Timer

@onready var _linhas: VBoxContainer = %Linhas
@onready var _rolagem: ScrollContainer = %Rolagem
@onready var _voltar: Button = %Voltar
@onready var _heroi_nome: Label = %HeroiNome
@onready var _heroi_pv: Label = %HeroiPV
@onready var _heroi_barra: ProgressBar = %HeroiBarra
@onready var _inimigo_nome: Label = %InimigoNome
@onready var _inimigo_pv: Label = %InimigoPV
@onready var _inimigo_barra: ProgressBar = %InimigoBarra


func _ready() -> void:
	_timer = Timer.new()
	_timer.timeout.connect(_next_line)
	add_child(_timer)
	_voltar.pressed.connect(_on_voltar)
	# Segue a última linha: o alcance da barra só muda depois que a linha nova é medida.
	_rolagem.get_v_scroll_bar().changed.connect(_scroll_to_end)


## Começa a mostrar os eventos. Os que não são de luta nem de prêmio são ignorados.
func play(events: Array[Dictionary]) -> void:
	_queue = events.duplicate()
	for child: Node in _linhas.get_children():
		child.queue_free()
	if _queue.is_empty():
		_add_line("Nenhuma luta para mostrar.", COR_PREMIO)
		return
	_timer.wait_time = line_interval_ms / 1000.0
	_next_line()
	_timer.start()


func is_playing() -> bool:
	return not _queue.is_empty()


func _next_line() -> void:
	while not _queue.is_empty():
		var e: Dictionary = _queue.pop_front()
		if _show(e):
			break
	if _queue.is_empty():
		_timer.stop()


## Mostra um evento. Devolve falso se ele não gera linha (então o próximo vem já).
func _show(e: Dictionary) -> bool:
	match str(e.get("type", "")):
		"luta":
			_start_fight(e)
		"golpe", "critico":
			_hit(e)
		"esquiva":
			var defensor: int = 1 - int(e["atacante"])
			_add_line("%s esquiva" % _names[defensor], _color_of(defensor))
		"fim":
			if int(e["vencedor"]) == 0:
				_add_line("Vitória!", COR_VITORIA, 40)
			else:
				_add_line("Derrota! Treine e tente de novo.", COR_DERROTA, 40)
		"vintens_ganhos":
			_add_line("+%d vinténs" % int(e["amount"]), COR_PREMIO)
		"xp_ganho":
			_add_line("+%d de experiência" % int(e["amount"]), COR_PREMIO)
		"muiraquitas_ganhas":
			_add_line("+%d muiraquitãs" % int(e["amount"]), COR_PREMIO)
		"subiu_nivel":
			_add_line("Subiu para o nível %d!" % int(e["lvl"]), COR_VITORIA)
		"fase_vencida":
			_add_line("Fase %d vencida!" % (int(e["n"]) + 1), COR_VITORIA)
		"ato_concluido":
			_add_line("Ato concluído!", COR_VITORIA)
		"item_ganho":
			_add_line("Item novo: %s" % str(e["nome"]), COR_CRITICO)
		_:
			return false
	return true


func _start_fight(e: Dictionary) -> void:
	var heroi: Dictionary = e["heroi"]
	var inimigo: Dictionary = e["inimigo"]
	_names = [str(heroi["nome"]), str(inimigo["nome"])]
	_heroi_nome.text = "%s · nível %d" % [_names[0], int(heroi["lvl"])]
	_inimigo_nome.text = "%s · nível %d" % [_names[1], int(inimigo["lvl"])]
	_set_bar(_heroi_barra, _heroi_pv, int(heroi["hp"]), int(heroi["hp"]))
	_set_bar(_inimigo_barra, _inimigo_pv, int(inimigo["hp"]), int(inimigo["hp"]))
	_add_line("%s enfrenta %s" % [_names[0], _names[1]], COR_PREMIO)


func _hit(e: Dictionary) -> void:
	var a: int = int(e["atacante"])
	var texto: String = "%s acerta %s: −%d PV" % [_names[a], _names[1 - a], int(e["dano"])]
	if str(e["type"]) == "critico":
		_add_line("Golpe crítico! " + texto, COR_CRITICO)
	else:
		_add_line(texto, _color_of(a))
	var hp: Array = e["hp"]
	_set_bar(_heroi_barra, _heroi_pv, int(hp[0]), int(_heroi_barra.max_value))
	_set_bar(_inimigo_barra, _inimigo_pv, int(hp[1]), int(_inimigo_barra.max_value))


static func _set_bar(barra: ProgressBar, rotulo: Label, hp: int, hp_max: int) -> void:
	barra.max_value = maxi(1, hp_max)
	barra.value = hp
	rotulo.text = "%d / %d PV" % [hp, hp_max]


func _color_of(lado: int) -> Color:
	return COR_HEROI if lado == 0 else COR_INIMIGO


func _add_line(texto: String, cor: Color, tamanho: int = 30) -> void:
	var rotulo := Label.new()
	rotulo.text = texto
	rotulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rotulo.add_theme_color_override("font_color", cor)
	rotulo.add_theme_font_size_override("font_size", tamanho)
	_linhas.add_child(rotulo)


func _scroll_to_end() -> void:
	_rolagem.scroll_vertical = int(_rolagem.get_v_scroll_bar().max_value)


func _on_voltar() -> void:
	_timer.stop()
	_queue.clear()
	closed.emit()
	if get_tree().current_scene == self:
		get_tree().change_scene_to_file(DIAGNOSTICO_SCENE)
	else:
		queue_free()
