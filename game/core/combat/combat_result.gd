class_name CombatResult
extends RefCounted
## Resultado de `Combat.simulate`. `win` é do ponto de vista do primeiro combatente.
## Eventos: {"type": "golpe"|"critico"|"esquiva", "atacante": 0|1, "dano": int, "hp": [int, int]}
## e, ao final, {"type": "fim", "vencedor": 0|1}.

var win: bool = false
var hp_final: PackedInt32Array = PackedInt32Array()
var events: Array[Dictionary] = []
