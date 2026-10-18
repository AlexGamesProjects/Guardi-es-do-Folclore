class_name Defs
extends RefCounted
## Definições tipadas do pacote de regras. Todo `from_dict` converte os números lidos do JSON
## com `int()` (o Godot lê número de JSON como ponto flutuante) e assume um dicionário que já
## passou pelo `RulesValidator`.

const STAT_KEYS: PackedStringArray = ["for", "fol", "mal", "gin"]
const SLOT_KEYS: PackedStringArray = ["cabeca", "corpo", "arma", "amuleto"]


static func to_int_array(values: Array) -> Array[int]:
	var out: Array[int] = []
	for v: Variant in values:
		out.append(int(v))
	return out


## Copia recursivamente um valor de JSON trocando números inteiros por `int`.
static func normalize(value: Variant) -> Variant:
	if value is Dictionary:
		var src: Dictionary = value
		var out: Dictionary = {}
		for k: Variant in src:
			out[k] = normalize(src[k])
		return out
	if value is Array:
		var src_list: Array = value
		var out_list: Array = []
		for item: Variant in src_list:
			out_list.append(normalize(item))
		return out_list
	if typeof(value) == TYPE_FLOAT:
		return int(value)
	return value


## Lenda do folclore. `perf_pm` (permilagem por atributo) fica vazio nas aliadas.
class LegendDef:
	extends RefCounted
	var id: String = ""
	var nome: String = ""
	var lvl: int = 0
	var lugar: String = ""
	var ally: bool = false
	var perf_pm: Dictionary[String, int] = {}
	var tarefas: PackedStringArray = PackedStringArray()
	var lutas: PackedStringArray = PackedStringArray()
	var lore: String = ""

	static func from_dict(d: Dictionary) -> LegendDef:
		var out := LegendDef.new()
		out.id = str(d["id"])
		out.nome = str(d["nome"])
		out.lvl = int(d["lvl"])
		out.lugar = str(d["lugar"])
		out.ally = bool(d["ally"])
		var perf: Dictionary = d["perf_pm"]
		for k: Variant in perf:
			out.perf_pm[str(k)] = int(perf[k])
		out.tarefas = PackedStringArray(d["tarefas"])
		out.lutas = PackedStringArray(d["lutas"])
		out.lore = str(d["lore"])
		return out


class StageDef:
	extends RefCounted
	var nome: String = ""
	var legend_id: String = ""

	static func from_dict(d: Dictionary) -> StageDef:
		var out := StageDef.new()
		out.nome = str(d["nome"])
		out.legend_id = str(d["legend_id"])
		return out


## Ato da Torre dos Chefes. `de`/`ate` são os níveis do ato; a fase n (0 a 9) é de nível de+n.
class ActDef:
	extends RefCounted
	var nome: String = ""
	var de: int = 0
	var ate: int = 0
	var capa: String = ""
	var stages: Array[StageDef] = []

	static func from_dict(d: Dictionary) -> ActDef:
		var out := ActDef.new()
		out.nome = str(d["nome"])
		out.de = int(d["de"])
		out.ate = int(d["ate"])
		out.capa = str(d["capa"])
		var raw: Array = d["stages"]
		for s: Variant in raw:
			out.stages.append(StageDef.from_dict(s))
		return out


class RarityDef:
	extends RefCounted
	var nome: String = ""
	var mult_pm: int = 0

	static func from_dict(d: Dictionary) -> RarityDef:
		var out := RarityDef.new()
		out.nome = str(d["nome"])
		out.mult_pm = int(d["mult_pm"])
		return out


class RankDef:
	extends RefCounted
	var lvl: int = 0
	var nome: String = ""

	static func from_dict(d: Dictionary) -> RankDef:
		var out := RankDef.new()
		out.lvl = int(d["lvl"])
		out.nome = str(d["nome"])
		return out


## Constantes de ritmo e balanceamento. `curva[i]` é a força média no nível i + 1.
## `xp_table[nível]` e `train_cost[valor]` têm o índice 0 sem uso (valem 0). As seções
## `mission`, `stage`, `item`, `rival`, `start` e `bands` guardam só inteiros (e listas ou
## dicionários deles); as chaves estão em `balance.json`.
## Constantes do combate (seção `combat` do balance.json). Chances em pontos-base, variação em
## permilagem, dano base em décimos.
class CombatDef:
	extends RefCounted
	var hp_base: int = 0
	var hp_per_fol: int = 0
	var hp_per_lvl: int = 0
	var dmg_for_x10: int = 0
	var dmg_lvl_x10: int = 0
	var dmg_var_min_pm: int = 0
	var dmg_var_max_pm: int = 0
	var dodge_num: int = 0
	var dodge_min_bp: int = 0
	var dodge_max_bp: int = 0
	var crit_num: int = 0
	var crit_min_bp: int = 0
	var crit_max_bp: int = 0
	var crit_mult: int = 0
	var chance_pad: int = 0
	var initiative_roll_max: int = 0
	var max_turns: int = 0

	static func from_dict(d: Dictionary) -> CombatDef:
		var out := CombatDef.new()
		out.hp_base = int(d["hp_base"])
		out.hp_per_fol = int(d["hp_per_fol"])
		out.hp_per_lvl = int(d["hp_per_lvl"])
		out.dmg_for_x10 = int(d["dmg_for_x10"])
		out.dmg_lvl_x10 = int(d["dmg_lvl_x10"])
		out.dmg_var_min_pm = int(d["dmg_var_min_pm"])
		out.dmg_var_max_pm = int(d["dmg_var_max_pm"])
		out.dodge_num = int(d["dodge_num"])
		out.dodge_min_bp = int(d["dodge_min_bp"])
		out.dodge_max_bp = int(d["dodge_max_bp"])
		out.crit_num = int(d["crit_num"])
		out.crit_min_bp = int(d["crit_min_bp"])
		out.crit_max_bp = int(d["crit_max_bp"])
		out.crit_mult = int(d["crit_mult"])
		out.chance_pad = int(d["chance_pad"])
		out.initiative_roll_max = int(d["initiative_roll_max"])
		out.max_turns = int(d["max_turns"])
		return out


class BalanceDef:
	extends RefCounted
	var en_max: int = 0
	var en_ms: int = 0
	var co_max: int = 0
	var co_ms: int = 0
	var feira_ms: int = 0
	var mochila: int = 0
	var chefe_en: int = 0
	var chefe_espera_ms: int = 0
	var curva: PackedInt32Array = PackedInt32Array()
	var xp_table: PackedInt64Array = PackedInt64Array()
	var train_cost: PackedInt64Array = PackedInt64Array()
	var ranks: Array[RankDef] = []
	var combat: CombatDef = null
	var mission: Dictionary = {}
	var progress: Dictionary = {}
	var arena: Dictionary = {}
	var stage: Dictionary = {}
	var item: Dictionary = {}
	var rival: Dictionary = {}
	var start: Dictionary = {}
	var bands: Dictionary = {}

	static func from_dict(d: Dictionary) -> BalanceDef:
		var out := BalanceDef.new()
		out.en_max = int(d["en_max"])
		out.en_ms = int(d["en_ms"])
		out.co_max = int(d["co_max"])
		out.co_ms = int(d["co_ms"])
		out.feira_ms = int(d["feira_ms"])
		out.mochila = int(d["mochila"])
		out.chefe_en = int(d["chefe_en"])
		out.chefe_espera_ms = int(d["chefe_espera_ms"])
		out.curva = PackedInt32Array(Defs.to_int_array(d["curva"]))
		out.xp_table = PackedInt64Array(Defs.to_int_array(d["xp_table"]))
		out.train_cost = PackedInt64Array(Defs.to_int_array(d["train_cost"]))
		var raw_ranks: Array = d["ranks"]
		for r: Variant in raw_ranks:
			out.ranks.append(RankDef.from_dict(r))
		out.combat = CombatDef.from_dict(d["combat"])
		out.mission = Defs.normalize(d["mission"])
		out.progress = Defs.normalize(d["progress"])
		out.arena = Defs.normalize(d["arena"])
		out.stage = Defs.normalize(d["stage"])
		out.item = Defs.normalize(d["item"])
		out.rival = Defs.normalize(d["rival"])
		out.start = Defs.normalize(d["start"])
		out.bands = Defs.normalize(d["bands"])
		return out
