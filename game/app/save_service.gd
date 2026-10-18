class_name SaveService
extends RefCounted
## Grava e lê os perfis em `<root>/<id>.json`, com duas cópias de reserva (`.bak1`, `.bak2`).
## A gravação vai primeiro para `<id>.tmp` e só então troca o arquivo; se falhar, o anterior fica.

const _ID_PATTERN: String = "^[A-Za-z0-9_-]{1,64}\\z"
const _COPIES: PackedStringArray = ["json", "bak1", "bak2"]

var _io: FileIO
var _root: String
var _migrations: SaveMigrations


func _init(io: FileIO, root: String = "user://profiles", migrations: SaveMigrations = null) -> void:
	_io = io
	_root = root
	_migrations = migrations if migrations != null else SaveMigrations.new()


## `true` se gravou. Em qualquer falha o `.json` anterior (e as reservas) continuam válidos.
func save(state: GameState, rules_version: String, schema_version: int = 0) -> bool:
	if not _valid_id(state.profile_id):
		return false
	var id: String = state.profile_id
	var text: String = SaveCodec.encode(state, rules_version, schema_version)
	var tmp: String = _path(id, "tmp")
	# Confere o que ficou no disco antes de mexer em qualquer cópia boa.
	if not _io.write(tmp, text) or _io.read(tmp) != text:
		_io.remove(tmp)
		return false
	var main: String = _path(id, "json")
	var bak1: String = _path(id, "bak1")
	var bak2: String = _path(id, "bak2")
	# Uma cópia inválida nunca empurra uma válida para fora da fila.
	var main_ok: bool = _decode(main)["ok"]
	if main_ok:
		if _decode(bak1)["ok"] and not _io.rename(bak1, bak2):
			_io.remove(tmp)
			return false
		if not _io.rename(main, bak1):
			_io.remove(tmp)
			return false
	if not _io.rename(tmp, main):
		if main_ok:
			_io.rename(bak1, main)
		_io.remove(tmp)
		return false
	return true


## Devolve `{state, warning: ""|"RESERVA_USADA"|"SAVE_RECRIADO"}`. Tenta `.json`, `.bak1`, `.bak2`.
## Uma cópia de outro perfil ou de outro modo conta como inválida: perfis não se misturam.
## Sem nenhuma cópia boa, `fresh` (Callable() -> GameState) cria o perfil novo; o id e o modo
## pedidos valem sempre. Cópias de versão futura são postas de lado (`.futuro`), não apagadas.
func load(profile_id: String, mode: String, fresh: Callable = Callable()) -> Dictionary:
	if not _valid_id(profile_id):
		return {"state": _fresh_state(fresh, profile_id, mode), "warning": "SAVE_RECRIADO"}
	var found: GameState = null
	var warning: String = ""
	for ext: String in _COPIES:
		var res: Dictionary = _decode(_path(profile_id, ext))
		if res["error"] == "VERSAO_FUTURA":
			_io.rename(_path(profile_id, ext), _path(profile_id, ext + ".futuro"))
			continue
		if found != null or not res["ok"]:
			continue
		var s: GameState = res["state"]
		if s.profile_id == profile_id and s.mode == mode:
			found = s
			warning = "" if ext == "json" else "RESERVA_USADA"
	if found != null:
		return {"state": found, "warning": warning}
	return {"state": _fresh_state(fresh, profile_id, mode), "warning": "SAVE_RECRIADO"}


func _fresh_state(fresh: Callable, profile_id: String, mode: String) -> GameState:
	var state: GameState = null
	if fresh.is_valid():
		state = fresh.call() as GameState
	if state == null:
		state = GameState.new()
	state.profile_id = profile_id
	state.mode = mode
	return state


## Um item `{id, mode, nome, lvl}` por perfil, na ordem do id, lido da primeira cópia boa.
func list_profiles() -> Array[Dictionary]:
	var ids: Array[String] = []
	for file: String in _io.list(_root):
		var id: String = file.get_basename()
		if file.get_extension() in _COPIES and _valid_id(id) and not ids.has(id):
			ids.append(id)
	ids.sort()
	var out: Array[Dictionary] = []
	for id: String in ids:
		for ext: String in _COPIES:
			var res: Dictionary = _decode(_path(id, ext))
			if res["ok"]:
				var s: GameState = res["state"]
				out.append({"id": s.profile_id, "mode": s.mode, "nome": s.nome, "lvl": s.lvl})
				break
	return out


func _decode(path: String) -> Dictionary:
	var text: String = _io.read(path)
	if text.is_empty():
		return {"ok": false, "error": "AUSENTE", "state": null, "schema_version": 0}
	return SaveCodec.decode(text, _migrations)


func _path(id: String, ext: String) -> String:
	return "%s/%s.%s" % [_root, id, ext]


func _valid_id(id: String) -> bool:
	var re := RegEx.new()
	re.compile(_ID_PATTERN)
	return re.search(id) != null
