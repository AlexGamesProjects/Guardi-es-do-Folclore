extends Node2D

const TITULO: String = "Guardiões do Folclore"


func _ready() -> void:
	var versao: String = str(ProjectSettings.get_setting("application/config/version"))
	var rotulo := Label.new()
	rotulo.text = "%s %s" % [TITULO, versao]
	rotulo.position = Vector2(40, 40)
	add_child(rotulo)
	print("GF_READY")
