extends PanelContainer
## Selo de modo: fica no topo das telas de jogo e mostra em que modo o perfil está.

const ROTULOS: Dictionary[String, String] = {
	"offline": "Offline · Jornada Solo",
	"online": "Online · Roda Online",
}

@onready var _texto: Label = $Linha/Texto
@onready var _ponto: ColorRect = $Linha/Ponto


func _ready() -> void:
	var service: Node = get_node("/root/GameService")
	service.connect("state_changed", _on_state_changed)
	_refresh(service.call("get_state") as GameState)


func _on_state_changed(state: GameState) -> void:
	_refresh(state)


func _refresh(state: GameState) -> void:
	var mode: String = "offline" if state == null else state.mode
	_texto.text = ROTULOS.get(mode, "Modo: %s" % mode)
	_ponto.color = Color("#2f9a68") if mode == "offline" else Color("#d6a24a")
