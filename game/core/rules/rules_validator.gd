class_name RulesValidator
extends RefCounted
## Valida o conteúdo bruto (JSON já lido) de um pacote de regras e acumula todos os erros.
## Formato da mensagem: "<arquivo>: <caminho do campo>: <problema>".

const SUPPORTED_SCHEMA: int = 1
const PERF_MIN: int = 500
const PERF_MAX: int = 2000
const XP_TABLE_SIZE: int = 41
const TRAIN_COST_SIZE: int = 201
const CURVA_SIZE: int = 31
const BP_FULL: int = 10000
const MIN_RARITIES: int = 3
const ALLY_FIGHT_ERROR: String = "aliada não pode ter lutas"

## Esquema do balance.json. Textos: "pos" (> 0), "nonneg" (>= 0), "int", "str", "str_arr",
## "pos_arr:N", "int_arr:N", "range" (par [min, max]), "stat_map", "primary_map", "slot".
const BALANCE_SPEC: Dictionary = {
	"en_max": "pos",
	"en_ms": "pos",
	"co_max": "pos",
	"co_ms": "pos",
	"feira_ms": "pos",
	"mochila": "pos",
	"chefe_en": "pos",
	"chefe_espera_ms": "pos",
	"curva": "pos_arr:31",
	"combat":
	{
		"hp_base": "pos",
		"hp_per_fol": "pos",
		"hp_per_lvl": "pos",
		"dmg_for_x10": "pos",
		"dmg_lvl_x10": "pos",
		"dmg_var_min_pm": "pos",
		"dmg_var_max_pm": "pos",
		"dodge_num": "pos",
		"dodge_min_bp": "pos",
		"dodge_max_bp": "pos",
		"crit_num": "pos",
		"crit_min_bp": "pos",
		"crit_max_bp": "pos",
		"crit_mult": "pos",
		"chance_pad": "pos",
		"initiative_roll_max": "pos",
		"max_turns": "pos",
	},
	"mission":
	{
		"dur_s": "pos_arr:3",
		"energia": "pos_arr:3",
		"dif_pm": "pos_arr:3",
		"luta_pm": "pos",
		"lenda_pm_por_lvl": "nonneg",
		"luta_chance_bp": "nonneg",
		"enemy_pm": "pos_arr:3",
		"enemy_noise_min_pm": "pos",
		"enemy_noise_max_pm": "pos",
		"enemy_stat_min": "pos",
		"xp_base": "pos",
		"xp_lvl": "pos",
		"vint_base": "pos",
		"vint_lvl": "pos",
	},
	"stage":
	{
		"mult_base_pm": "pos",
		"mult_step_pm": "pos",
		"boss_pm": "pos",
		"xp_pm": "pos",
		"boss_xp_pm": "pos",
		"vint_base": "pos",
		"vint_lvl": "pos",
		"boss_vint_mult": "pos",
		"boss_muir": "nonneg",
		"boss_rarity_min": "nonneg",
		"boss_legendary_bp": "nonneg",
	},
	"item":
	{
		"pts_base": "pos",
		"pts_lvl_pm": "pos",
		"prim_pm": "pos",
		"price_pt": "pos",
		"price_lvl_pm": "nonneg",
		"rare_bp": "pos",
		"legendary_bp": "pos",
		"shop_size": "pos",
		"primary": "primary_map",
	},
	"rival":
	{
		"count": "pos",
		"lvl_delta_min": "int",
		"lvl_delta_max": "int",
		"factor_min_pm": "pos",
		"factor_max_pm": "pos",
		"lvl_gap_pm": "nonneg",
		"noise_min_pm": "pos",
		"noise_max_pm": "pos",
		"stat_min": "pos",
		"honra_min_pm": "pos",
		"honra_max_pm": "pos",
		"honra_add_max": "nonneg",
		"colors": "str_arr",
	},
	"start":
	{
		"nome": "str",
		"nome_max": "pos",
		"vint": "nonneg",
		"muir": "nonneg",
		"stats": {"for": "pos", "fol": "pos", "mal": "pos", "gin": "pos"},
		"weapon":
		{"slot": "slot", "nome": "str", "rar": "nonneg", "st": "stat_map", "preco": "pos"},
	},
	"bands":
	{
		"stage_win_bp": "range",
		"boss_win_bp": "range",
		"lvl30_missions": "range",
	},
}


static func validate(files: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	if files.has("manifest.json"):
		_check_manifest(errors, files["manifest.json"])
	var legend_info: Dictionary = {}
	if files.has("legends.json"):
		legend_info = _check_legends(errors, files["legends.json"])
	if files.has("balance.json"):
		_check_balance(errors, files["balance.json"])
	if files.has("acts.json"):
		_check_acts(errors, files["acts.json"], legend_info)
	if files.has("items.json"):
		_check_items(errors, files["items.json"])
	if files.has("rivals.json"):
		_check_rivals(errors, files["rivals.json"])
	return errors


# ---------- Utilitários ----------


static func _err(errors: PackedStringArray, file: String, path: String, message: String) -> void:
	errors.append("%s: %s: %s" % [file, path, message])


static func _join(base: String, key: String) -> String:
	return key if base.is_empty() else "%s.%s" % [base, key]


static func _is_int(v: Variant) -> bool:
	if typeof(v) == TYPE_INT:
		return true
	return typeof(v) == TYPE_FLOAT and v == int(v)


static func _show(v: Variant) -> String:
	if _is_int(v):
		return str(int(v))
	return str(v)


static func _root(errors: PackedStringArray, file: String, data: Variant) -> Variant:
	if data is Dictionary:
		return data
	_err(errors, file, "(raiz)", "deve ser um objeto")
	return null


## Devolve a lista em `d[key]`, ou vazia (com erro) se faltar ou não for lista.
static func _list(
	errors: PackedStringArray, file: String, path: String, d: Dictionary, key: String
) -> Array:
	var where: String = _join(path, key)
	if not d.has(key):
		_err(errors, file, where, "campo ausente")
		return []
	if not d[key] is Array:
		_err(errors, file, where, "deve ser uma lista")
		return []
	return d[key]


static func _check_int(
	errors: PackedStringArray, file: String, path: String, v: Variant, kind: String
) -> void:
	if not _is_int(v):
		_err(errors, file, path, "deve ser um número inteiro (recebido %s)" % str(v))
	elif kind == "pos" and int(v) <= 0:
		_err(errors, file, path, "deve ser maior que 0 (recebido %s)" % _show(v))
	elif kind == "nonneg" and int(v) < 0:
		_err(errors, file, path, "não pode ser negativo (recebido %s)" % _show(v))


static func _check_str(errors: PackedStringArray, file: String, path: String, v: Variant) -> void:
	if not v is String or (v as String).strip_edges().is_empty():
		_err(errors, file, path, "deve ser um texto não vazio")


static func _check_str_list(
	errors: PackedStringArray, file: String, path: String, v: Variant, allow_empty: bool
) -> void:
	if not v is Array:
		_err(errors, file, path, "deve ser uma lista de textos")
		return
	var items: Array = v
	if items.is_empty() and not allow_empty:
		_err(errors, file, path, "não pode ser vazia")
	for i: int in items.size():
		_check_str(errors, file, "%s[%d]" % [path, i], items[i])


## Campo de texto obrigatório de um dicionário.
static func _need_str(
	errors: PackedStringArray, file: String, path: String, d: Dictionary, key: String
) -> void:
	if not d.has(key):
		_err(errors, file, _join(path, key), "campo ausente")
		return
	_check_str(errors, file, _join(path, key), d[key])


## Campo inteiro obrigatório de um dicionário.
static func _need_int(
	errors: PackedStringArray, file: String, path: String, d: Dictionary, key: String, kind: String
) -> void:
	if not d.has(key):
		_err(errors, file, _join(path, key), "campo ausente")
		return
	_check_int(errors, file, _join(path, key), d[key], kind)


# ---------- manifest.json ----------


static func _check_manifest(errors: PackedStringArray, data: Variant) -> void:
	var file: String = "manifest.json"
	var root: Variant = _root(errors, file, data)
	if root == null:
		return
	var d: Dictionary = root
	if not d.has("schema_version"):
		_err(errors, file, "schema_version", "campo ausente")
	elif not _is_int(d["schema_version"]):
		_err(errors, file, "schema_version", "deve ser um número inteiro")
	elif int(d["schema_version"]) != SUPPORTED_SCHEMA:
		_err(
			errors,
			file,
			"schema_version",
			"versão %s não suportada (esperado %d)" % [_show(d["schema_version"]), SUPPORTED_SCHEMA]
		)
	_need_str(errors, file, "", d, "rules_version")


# ---------- legends.json ----------


## Devolve id -> {"lvl": int, "ally": bool} das lendas, para as checagens cruzadas.
static func _check_legends(errors: PackedStringArray, data: Variant) -> Dictionary:
	var file: String = "legends.json"
	var info: Dictionary = {}
	var root: Variant = _root(errors, file, data)
	if root == null:
		return info
	var d: Dictionary = root
	var legends: Array = _list(errors, file, "", d, "legends")
	for i: int in legends.size():
		var path: String = "legends[%d]" % i
		if not legends[i] is Dictionary:
			_err(errors, file, path, "deve ser um objeto")
			continue
		var legend: Dictionary = legends[i]
		_check_legend(errors, path, legend)
		if legend.has("id") and legend["id"] is String:
			if info.has(legend["id"]):
				_err(errors, file, _join(path, "id"), "id '%s' repetido" % legend["id"])
			var lvl: int = int(legend["lvl"]) if _is_int(legend.get("lvl")) else 0
			info[legend["id"]] = {"lvl": lvl, "ally": legend.get("ally") == true}
	return info


static func _check_legend(errors: PackedStringArray, path: String, legend: Dictionary) -> void:
	var file: String = "legends.json"
	_need_str(errors, file, path, legend, "id")
	_need_str(errors, file, path, legend, "nome")
	_need_str(errors, file, path, legend, "lugar")
	_need_str(errors, file, path, legend, "lore")
	_need_int(errors, file, path, legend, "lvl", "pos")
	var ally: bool = false
	if not legend.has("ally"):
		_err(errors, file, _join(path, "ally"), "campo ausente")
	elif typeof(legend["ally"]) != TYPE_BOOL:
		_err(errors, file, _join(path, "ally"), "deve ser verdadeiro ou falso")
	else:
		ally = legend["ally"]
	if legend.get("id") == "negrinho" and not ally:
		_err(errors, file, _join(path, "ally"), "o Negrinho do Pastoreio deve ser aliado")
	_check_perf(errors, path, legend, ally)
	_check_phrases(errors, path, legend, ally)


static func _check_perf(
	errors: PackedStringArray, path: String, legend: Dictionary, ally: bool
) -> void:
	var file: String = "legends.json"
	var where: String = _join(path, "perf_pm")
	if not legend.has("perf_pm"):
		_err(errors, file, where, "campo ausente")
		return
	if not legend["perf_pm"] is Dictionary:
		_err(errors, file, where, "deve ser um objeto")
		return
	if ally:
		return
	var perf: Dictionary = legend["perf_pm"]
	for stat: String in Defs.STAT_KEYS:
		if not perf.has(stat):
			_err(errors, file, _join(where, stat), "campo ausente")
		elif not _is_int(perf[stat]):
			_err(errors, file, _join(where, stat), "deve ser um número inteiro")
		elif int(perf[stat]) < PERF_MIN or int(perf[stat]) > PERF_MAX:
			_err(
				errors,
				file,
				_join(where, stat),
				"fora de %d a %d (recebido %s)" % [PERF_MIN, PERF_MAX, _show(perf[stat])]
			)


static func _check_phrases(
	errors: PackedStringArray, path: String, legend: Dictionary, ally: bool
) -> void:
	var file: String = "legends.json"
	for key: String in ["tarefas", "lutas"]:
		var where: String = _join(path, key)
		if not legend.has(key):
			_err(errors, file, where, "campo ausente")
			continue
		var must_fill: bool = key == "tarefas" or not ally
		_check_str_list(errors, file, where, legend[key], not must_fill)
		if (
			key == "lutas"
			and ally
			and legend[key] is Array
			and not (legend[key] as Array).is_empty()
		):
			_err(errors, file, where, ALLY_FIGHT_ERROR)


# ---------- acts.json ----------


static func _check_acts(errors: PackedStringArray, data: Variant, legend_info: Dictionary) -> void:
	var file: String = "acts.json"
	var root: Variant = _root(errors, file, data)
	if root == null:
		return
	var d: Dictionary = root
	var acts: Array = _list(errors, file, "", d, "acts")
	if acts.is_empty() and d.has("acts"):
		_err(errors, file, "acts", "não pode ser vazia")
	for i: int in acts.size():
		var path: String = "acts[%d]" % i
		if not acts[i] is Dictionary:
			_err(errors, file, path, "deve ser um objeto")
			continue
		_check_act(errors, path, acts[i], legend_info)


static func _check_act(
	errors: PackedStringArray, path: String, act: Dictionary, legend_info: Dictionary
) -> void:
	var file: String = "acts.json"
	_need_str(errors, file, path, act, "nome")
	_need_int(errors, file, path, act, "de", "pos")
	_need_int(errors, file, path, act, "ate", "pos")
	var ate: int = int(act["ate"]) if _is_int(act.get("ate")) else 0
	var de: int = int(act["de"]) if _is_int(act.get("de")) else 0
	if ate > 0 and de > 0:
		if ate < de:
			_err(errors, file, _join(path, "ate"), "menor que 'de' (%d)" % de)
		elif ate > CURVA_SIZE:
			_err(errors, file, _join(path, "ate"), "acima da curva (%d níveis)" % CURVA_SIZE)
	_need_str(errors, file, path, act, "capa")
	if act.has("capa") and act["capa"] is String and not legend_info.has(act["capa"]):
		_err(errors, file, _join(path, "capa"), "lenda '%s' não existe" % act["capa"])
	var stages: Array = _list(errors, file, path, act, "stages")
	if ate >= de and de > 0 and not stages.is_empty() and stages.size() != ate - de + 1:
		_err(
			errors,
			file,
			_join(path, "stages"),
			(
				"esperadas %d fases (níveis %d a %d), recebidas %d"
				% [ate - de + 1, de, ate, stages.size()]
			)
		)
	for j: int in stages.size():
		_check_stage(errors, "%s.stages[%d]" % [path, j], stages[j], legend_info, ate)


static func _check_stage(
	errors: PackedStringArray, path: String, stage: Variant, legend_info: Dictionary, act_end: int
) -> void:
	var file: String = "acts.json"
	if not stage is Dictionary:
		_err(errors, file, path, "deve ser um objeto")
		return
	var s: Dictionary = stage
	_need_str(errors, file, path, s, "nome")
	_need_str(errors, file, path, s, "legend_id")
	if not (s.has("legend_id") and s["legend_id"] is String):
		return
	var id: String = s["legend_id"]
	var where: String = _join(path, "legend_id")
	if not legend_info.has(id):
		_err(errors, file, where, "lenda '%s' não existe" % id)
		return
	var info: Dictionary = legend_info[id]
	if info["ally"]:
		_err(errors, file, where, "lenda '%s' é aliada e não pode ser inimiga" % id)
	elif act_end > 0 and int(info["lvl"]) > act_end:
		_err(
			errors,
			file,
			where,
			(
				"lenda '%s' (nível %d) só aparece depois do fim do ato (nível %d)"
				% [id, info["lvl"], act_end]
			)
		)


# ---------- balance.json ----------


static func _check_balance(errors: PackedStringArray, data: Variant) -> void:
	var file: String = "balance.json"
	var root: Variant = _root(errors, file, data)
	if root == null:
		return
	var d: Dictionary = root
	_check_spec(errors, file, "", d, BALANCE_SPEC)
	_check_table(errors, d, "xp_table", XP_TABLE_SIZE)
	_check_table(errors, d, "train_cost", TRAIN_COST_SIZE)
	_check_ranks(errors, d)
	_check_balance_relations(errors, d)


static func _check_spec(
	errors: PackedStringArray, file: String, path: String, d: Dictionary, spec: Dictionary
) -> void:
	for key: String in spec:
		var where: String = _join(path, key)
		if not d.has(key):
			_err(errors, file, where, "campo ausente")
		elif spec[key] is Dictionary:
			if d[key] is Dictionary:
				_check_spec(errors, file, where, d[key], spec[key])
			else:
				_err(errors, file, where, "deve ser um objeto")
		else:
			_check_kind(errors, file, where, d[key], spec[key])


static func _check_kind(
	errors: PackedStringArray, file: String, path: String, v: Variant, kind: String
) -> void:
	if kind == "pos" or kind == "nonneg" or kind == "int":
		_check_int(errors, file, path, v, kind)
	elif kind == "str":
		_check_str(errors, file, path, v)
	elif kind == "str_arr":
		_check_str_list(errors, file, path, v, false)
	elif kind.begins_with("pos_arr:") or kind.begins_with("int_arr:"):
		_check_int_list(errors, file, path, v, kind)
	elif kind == "range":
		_check_range(errors, file, path, v)
	elif kind == "slot":
		if not (v is String and Defs.SLOT_KEYS.has(v)):
			_err(errors, file, path, "deve ser um dos espaços: %s" % ", ".join(Defs.SLOT_KEYS))
	elif kind == "stat_map" or kind == "primary_map":
		_check_stat_map(errors, file, path, v, kind == "primary_map")


static func _check_int_list(
	errors: PackedStringArray, file: String, path: String, v: Variant, kind: String
) -> void:
	if not v is Array:
		_err(errors, file, path, "deve ser uma lista")
		return
	var items: Array = v
	var parts: PackedStringArray = kind.split(":")
	var expected: int = int(parts[1])
	if items.size() != expected:
		_err(errors, file, path, "esperados %d valores, recebidos %d" % [expected, items.size()])
	var item_kind: String = "pos" if parts[0] == "pos_arr" else "int"
	for i: int in items.size():
		_check_int(errors, file, "%s[%d]" % [path, i], items[i], item_kind)


static func _check_range(errors: PackedStringArray, file: String, path: String, v: Variant) -> void:
	if not v is Array or (v as Array).size() != 2:
		_err(errors, file, path, "deve ser um par [mínimo, máximo]")
		return
	var pair: Array = v
	var ok: bool = _is_int(pair[0]) and _is_int(pair[1])
	if not ok:
		_err(errors, file, path, "deve ter dois números inteiros")
	elif int(pair[0]) < 0 or int(pair[0]) > int(pair[1]):
		_err(errors, file, path, "intervalo inválido [%s, %s]" % [_show(pair[0]), _show(pair[1])])


## Mapa de atributos (for, fol, mal, gin) para inteiros positivos, ou, com `primary`,
## de espaços de equipamento para o atributo principal.
static func _check_stat_map(
	errors: PackedStringArray, file: String, path: String, v: Variant, primary: bool
) -> void:
	if not v is Dictionary or (v as Dictionary).is_empty():
		_err(errors, file, path, "deve ser um objeto não vazio")
		return
	var m: Dictionary = v
	if primary:
		for slot: String in Defs.SLOT_KEYS:
			if not m.has(slot):
				_err(errors, file, _join(path, slot), "campo ausente")
	for key: Variant in m:
		var where: String = _join(path, str(key))
		if primary:
			if not Defs.SLOT_KEYS.has(str(key)):
				_err(errors, file, where, "espaço desconhecido")
			elif not (m[key] is String and Defs.STAT_KEYS.has(m[key])):
				_err(errors, file, where, "deve ser um atributo: %s" % ", ".join(Defs.STAT_KEYS))
		elif not Defs.STAT_KEYS.has(str(key)):
			_err(errors, file, where, "atributo desconhecido")
		else:
			_check_int(errors, file, where, m[key], "pos")


## Tabelas com índice 0 sem uso: tamanho fixo, índice 0 igual a 0 e o resto > 0.
static func _check_table(
	errors: PackedStringArray, d: Dictionary, key: String, expected_size: int
) -> void:
	var file: String = "balance.json"
	var table: Array = _list(errors, file, "", d, key)
	if table.is_empty():
		return
	if table.size() != expected_size:
		_err(
			errors, file, key, "esperados %d valores, recebidos %d" % [expected_size, table.size()]
		)
	for i: int in table.size():
		var where: String = "%s[%d]" % [key, i]
		if i == 0:
			if not _is_int(table[i]) or int(table[i]) != 0:
				_err(errors, file, where, "o índice 0 deve valer 0")
		else:
			_check_int(errors, file, where, table[i], "pos")


static func _check_ranks(errors: PackedStringArray, d: Dictionary) -> void:
	var file: String = "balance.json"
	var ranks: Array = _list(errors, file, "", d, "ranks")
	if ranks.is_empty() and d.has("ranks"):
		_err(errors, file, "ranks", "não pode ser vazia")
	var previous: int = 0
	for i: int in ranks.size():
		var path: String = "ranks[%d]" % i
		if not ranks[i] is Dictionary:
			_err(errors, file, path, "deve ser um objeto")
			continue
		var r: Dictionary = ranks[i]
		_need_str(errors, file, path, r, "nome")
		_need_int(errors, file, path, r, "lvl", "pos")
		if _is_int(r.get("lvl")):
			if int(r["lvl"]) <= previous:
				_err(errors, file, _join(path, "lvl"), "deve crescer em relação ao posto anterior")
			previous = int(r["lvl"])


## Seção `combat` completa (tipos e relações), com o mesmo formato de mensagem do balance.json.
static func check_combat(errors: PackedStringArray, combat: Dictionary) -> void:
	_check_spec(errors, "balance.json", "combat", combat, BALANCE_SPEC["combat"])
	_check_combat_relations(errors, combat)


static func _check_combat_relations(errors: PackedStringArray, combat: Dictionary) -> void:
	for pair: Array in [
		["dmg_var_min_pm", "dmg_var_max_pm"],
		["dodge_min_bp", "dodge_max_bp"],
		["crit_min_bp", "crit_max_bp"],
	]:
		if _is_int(combat.get(pair[0])) and _is_int(combat.get(pair[1])):
			if int(combat[pair[0]]) > int(combat[pair[1]]):
				_err(errors, "balance.json", _join("combat", pair[0]), "maior que %s" % pair[1])


## Relações entre campos que o esquema por tipo não cobre.
static func _check_balance_relations(errors: PackedStringArray, d: Dictionary) -> void:
	var file: String = "balance.json"
	if d.get("combat") is Dictionary:
		_check_combat_relations(errors, d["combat"])
	if d.get("item") is Dictionary:
		var item: Dictionary = d["item"]
		var rare: Variant = item.get("rare_bp")
		var legendary: Variant = item.get("legendary_bp")
		if _is_int(rare) and _is_int(legendary):
			if int(legendary) > int(rare) or int(rare) > BP_FULL:
				_err(errors, file, "item.rare_bp", "deve ficar entre legendary_bp e %d" % BP_FULL)
	if d.get("stage") is Dictionary:
		var boss_bp: Variant = (d["stage"] as Dictionary).get("boss_legendary_bp")
		if _is_int(boss_bp) and int(boss_bp) > BP_FULL:
			_err(errors, file, "stage.boss_legendary_bp", "deve ficar entre 0 e %d" % BP_FULL)
	if d.get("mission") is Dictionary:
		var mission: Dictionary = d["mission"]
		if (
			_is_int(mission.get("enemy_noise_min_pm"))
			and _is_int(mission.get("enemy_noise_max_pm"))
		):
			if int(mission["enemy_noise_min_pm"]) > int(mission["enemy_noise_max_pm"]):
				_err(errors, file, "mission.enemy_noise_min_pm", "maior que enemy_noise_max_pm")
	if d.get("rival") is Dictionary:
		var rival: Dictionary = d["rival"]
		for pair: Array in [
			["lvl_delta_min", "lvl_delta_max"],
			["factor_min_pm", "factor_max_pm"],
			["noise_min_pm", "noise_max_pm"],
			["honra_min_pm", "honra_max_pm"],
		]:
			if _is_int(rival.get(pair[0])) and _is_int(rival.get(pair[1])):
				if int(rival[pair[0]]) > int(rival[pair[1]]):
					_err(errors, file, _join("rival", pair[0]), "maior que %s" % pair[1])
	if d.get("start") is Dictionary:
		var start: Dictionary = d["start"]
		var name_value: Variant = start.get("nome")
		if name_value is String and _is_int(start.get("nome_max")):
			if (name_value as String).length() > int(start["nome_max"]):
				_err(
					errors, file, "start.nome", "maior que nome_max (%s)" % _show(start["nome_max"])
				)


# ---------- items.json e rivals.json ----------


static func _check_items(errors: PackedStringArray, data: Variant) -> void:
	var file: String = "items.json"
	var root: Variant = _root(errors, file, data)
	if root == null:
		return
	var d: Dictionary = root
	if not d.has("item_names"):
		_err(errors, file, "item_names", "campo ausente")
	elif not d["item_names"] is Dictionary:
		_err(errors, file, "item_names", "deve ser um objeto")
	else:
		var names: Dictionary = d["item_names"]
		for slot: String in Defs.SLOT_KEYS:
			if names.has(slot):
				_check_str_list(errors, file, "item_names." + slot, names[slot], false)
			else:
				_err(errors, file, "item_names." + slot, "campo ausente")
	if d.has("epithets"):
		_check_str_list(errors, file, "epithets", d["epithets"], false)
	else:
		_err(errors, file, "epithets", "campo ausente")
	var rarities: Array = _list(errors, file, "", d, "rarities")
	if d.has("rarities") and rarities.size() < MIN_RARITIES:
		_err(errors, file, "rarities", "esperadas ao menos %d raridades" % MIN_RARITIES)
	for i: int in rarities.size():
		var path: String = "rarities[%d]" % i
		if not rarities[i] is Dictionary:
			_err(errors, file, path, "deve ser um objeto")
			continue
		_need_str(errors, file, path, rarities[i], "nome")
		_need_int(errors, file, path, rarities[i], "mult_pm", "pos")


static func _check_rivals(errors: PackedStringArray, data: Variant) -> void:
	var file: String = "rivals.json"
	var root: Variant = _root(errors, file, data)
	if root == null:
		return
	var d: Dictionary = root
	for key: String in ["first", "last"]:
		if d.has(key):
			_check_str_list(errors, file, key, d[key], false)
		else:
			_err(errors, file, key, "campo ausente")
