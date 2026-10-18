extends Node2D
## Cena inicial: entrega o controle ao `Boot`, que valida as regras e abre o menu.


func _ready() -> void:
	# Adiado: a troca de cena não pode acontecer no meio do `_ready` da cena atual.
	var boot: Node = get_node("/root/Boot")
	boot.call_deferred("start")
