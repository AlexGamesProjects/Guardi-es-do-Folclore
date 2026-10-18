extends Control
## Tela de erro: lista os problemas do pacote de regras. O `Boot` preenche `errors` antes de abrir.

var errors: PackedStringArray = PackedStringArray()


func _ready() -> void:
	var rotulo := Label.new()
	rotulo.text = "Não foi possível iniciar: regras inválidas\n\n" + "\n".join(errors)
	rotulo.position = Vector2(40, 40)
	rotulo.size = Vector2(640, 1200)
	rotulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(rotulo)
	push_error("Regras inválidas:\n" + "\n".join(errors))
