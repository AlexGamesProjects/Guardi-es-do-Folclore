class_name SaveMigrations
extends RefCounted
## Migrações do save, um passo por versão. `steps` mapeia `from_version: int` a um
## `Callable(envelope: Dictionary) -> Dictionary` que devolve o envelope já na versão seguinte.
## A tabela de produção começa vazia: a versão 1 é a primeira.

var _steps: Dictionary = {}
var _target: int = 0


## `target_version` negativo significa `SaveCodec.SAVE_VERSION`. Só os testes usam outro valor.
func _init(steps: Dictionary = {}, target_version: int = -1) -> void:
	_steps = steps
	_target = target_version


func target() -> int:
	return SaveCodec.SAVE_VERSION if _target < 0 else _target


## Aplica os passos em sequência até a versão-alvo. Devolve uma cópia; `{}` se faltar um passo
## ou se um passo devolver algo que não seja um envelope.
func migrate(envelope: Dictionary) -> Dictionary:
	var env: Dictionary = envelope.duplicate(true)
	var version: int = int(env.get("save_version", 0))
	while version < target():
		if not _steps.has(version):
			return {}
		var step: Callable = _steps[version]
		var out: Variant = step.call(env)
		if not out is Dictionary:
			return {}
		env = out
		version += 1
		env["save_version"] = version
	return env
