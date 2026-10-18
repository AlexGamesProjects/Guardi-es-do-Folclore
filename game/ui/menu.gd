extends Control
## Menu inicial (provisório até a Tarefa 13). Avisa que o jogo está pronto, uma única vez.


func _ready() -> void:
	var versao: String = str(ProjectSettings.get_setting("application/config/version"))
	var rotulo := Label.new()
	rotulo.text = "Guardiões do Folclore %s" % versao
	rotulo.position = Vector2(40, 40)
	add_child(rotulo)
	print("GF_READY")
