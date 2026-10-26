class_name SaveMigrations
extends RefCounted
## Migrações do save, um passo por versão. `steps` mapeia `from_version: int` a um
## `Callable(envelope: Dictionary) -> Dictionary` que devolve o envelope já na versão seguinte.
## Sem `steps`, usa a tabela de produção (`PRODUCAO`).

var _steps: Dictionary = {}
var _target: int = 0


## `target_version` negativo significa `SaveCodec.SAVE_VERSION`. Só os testes usam outro valor.
func _init(steps: Dictionary = {}, target_version: int = -1) -> void:
	_steps = (
		steps
		if not steps.is_empty()
		else {1: SaveMigrations.v1_para_v2, 2: SaveMigrations.v2_para_v3}
	)
	_target = target_version


## 1→2 (v0.4.0): o guardião ganha `origem`; perfis antigos ficam "legado" e pulam a criação.
static func v1_para_v2(env: Dictionary) -> Dictionary:
	var out: Dictionary = env.duplicate(true)
	var st: Variant = out.get("state")
	if st is Dictionary:
		(st as Dictionary)["origem"] = "legado"
	return out


## 2→3 (v0.4.1): o guardião ganha `visual` (rosto e cores); perfis antigos ficam com o padrão.
static func v2_para_v3(env: Dictionary) -> Dictionary:
	var out: Dictionary = env.duplicate(true)
	var st: Variant = out.get("state")
	if st is Dictionary:
		(st as Dictionary)["visual"] = VisualRules.PADRAO.duplicate()
	return out


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
