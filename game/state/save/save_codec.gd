class_name SaveCodec
extends RefCounted
## Envelope do save: `{save_version, rules_version, profile, state, hash}`.
## O hash é o SHA-256 do JSON canônico (chaves ordenadas) do envelope sem o campo `hash`.
## Isso pega corrupção e edição ingênua; não impede um jogador de editar e recalcular o hash.

const SAVE_VERSION: int = 1


static func encode(state: GameState, rules_version: String) -> String:
	var env: Dictionary = {
		"save_version": SAVE_VERSION,
		"rules_version": rules_version,
		"profile": {"id": state.profile_id, "mode": state.mode, "nome": state.nome},
		"state": state.to_dict(),
	}
	env["hash"] = _hash_of(env)
	return JSON.stringify(env, "", true)


## Devolve `{ok, error: "CORROMPIDO"|"VERSAO_FUTURA"|"", state: GameState}`.
static func decode(text: String, migrations: SaveMigrations) -> Dictionary:
	var json := JSON.new()
	if json.parse(text) != OK or not json.data is Dictionary:
		return _fail("CORROMPIDO")
	# O JSON do Godot só tem `float`: volta tudo a `int` antes de conferir o hash.
	var env: Dictionary = Defs.normalize(json.data)
	# A versão vem antes do hash: um save futuro pode usar outro esquema de hash e não é lixo.
	if not env.get("save_version") is int:
		return _fail("CORROMPIDO")
	var version: int = env["save_version"]
	if version > migrations.target():
		return _fail("VERSAO_FUTURA")
	var stored: Variant = env.get("hash")
	if not stored is String:
		return _fail("CORROMPIDO")
	env.erase("hash")
	if _hash_of(env) != stored or not env.get("state") is Dictionary:
		return _fail("CORROMPIDO")
	if version < 1:
		return _fail("CORROMPIDO")
	env = migrations.migrate(env)
	if env.is_empty() or not env.get("state") is Dictionary:
		return _fail("CORROMPIDO")
	var state: GameState = GameState.from_dict(env["state"])
	var profile: Variant = env.get("profile")
	if (
		not profile is Dictionary
		or str((profile as Dictionary).get("id")) != state.profile_id
		or str((profile as Dictionary).get("mode")) != state.mode
	):
		return _fail("CORROMPIDO")
	return {"ok": true, "error": "", "state": state}


static func _hash_of(env_without_hash: Dictionary) -> String:
	return JSON.stringify(env_without_hash, "", true).sha256_text()


static func _fail(error: String) -> Dictionary:
	return {"ok": false, "error": error, "state": null}
