class_name Jogo
extends Control
## Casca do jogo: topo fixo, miolo com a aba ativa e rodapé de abas. Cada aba é uma cena em
## `res://ui/abas/<id>.tscn`, criada na primeira abertura e guardada; aba sem cena mostra
## "Em breve". Erros e avisos aparecem no `Toast`.

signal luta_pedida(eventos: Array[Dictionary])

const CENA_ABA: String = "res://ui/abas/%s.tscn"

var aba_atual: String = ""
var _cache: Dictionary[String, Control] = {}
var _miolo: Control
var _abas: BarraAbas
var _treino: PainelTreino
var _toast: Toast


func _ready() -> void:
	var raiz := VBoxContainer.new()
	raiz.name = "Raiz"
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	raiz.add_theme_constant_override("separation", 0)
	add_child(raiz)
	var topo := Topo.new()
	raiz.add_child(topo)
	_miolo = Control.new()
	_miolo.name = "Miolo"
	_miolo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_miolo.clip_contents = true
	raiz.add_child(_miolo)
	_abas = BarraAbas.new()
	raiz.add_child(_abas)
	_treino = PainelTreino.new()
	_treino.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_treino.custom_minimum_size = Vector2(620, 0)
	add_child(_treino)
	_treino.hide()
	_toast = Toast.new()
	add_child(_toast)
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_toast.custom_minimum_size = Vector2(660, 0)
	_toast.position.y -= 140
	topo.heroi_tocado.connect(_abrir_treino)
	_abas.escolhida.connect(abrir_aba)
	var service: Node = get_node_or_null("/root/GameService")
	if service != null:
		service.connect(
			"warning", func(code: String) -> void: _toast.mostrar(Textos.aviso(code), "aviso")
		)
		service.connect("events_emitted", _on_eventos)
	abrir_aba("missoes")


func abrir_aba(id: String) -> void:
	if aba_atual == id:
		return
	if _cache.has(aba_atual):
		_cache[aba_atual].hide()
	aba_atual = id
	_abas.marcar(id)
	if not _cache.has(id):
		_cache[id] = _criar_aba(id)
		_miolo.add_child(_cache[id])
	_cache[id].show()


## Abre a camada de luta (Tarefa 4). Por enquanto só avisa quem escuta.
func mostrar_luta(eventos: Array[Dictionary]) -> void:
	luta_pedida.emit(eventos)


func _on_eventos(eventos: Array[Dictionary]) -> void:
	for ev: Dictionary in eventos:
		if str(ev.get("type", "")) == "luta":
			mostrar_luta(eventos)
			return


func _abrir_treino() -> void:
	_treino.atualizar()
	_treino.show()


static func _criar_aba(id: String) -> Control:
	var caminho: String = CENA_ABA % id
	var aba: Control
	if ResourceLoader.exists(caminho):
		aba = (load(caminho) as PackedScene).instantiate() as Control
	else:
		var aviso := Label.new()
		aviso.text = "Em breve"
		aviso.theme_type_variation = &"Titulo"
		aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		aviso.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		aba = aviso
	aba.name = "Aba" + id.capitalize()
	aba.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return aba
