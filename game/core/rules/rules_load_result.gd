class_name RulesLoadResult
extends RefCounted
## Resultado de `RulesLoader.load_dir`. Com `ok == false`, `pack` é nulo e `errors` traz todas
## as mensagens, no formato "<arquivo>: <caminho do campo>: <problema>".

var ok: bool = false
var errors: PackedStringArray = PackedStringArray()
var pack: RulesPack = null
