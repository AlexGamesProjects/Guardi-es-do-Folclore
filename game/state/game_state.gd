class_name GameState
extends RefCounted
## Estado de um perfil. Só os handlers (via CommandRouter) o alteram, sempre num clone.
## Itens são {id, slot, nome, rar, st, preco}; `ativa` é a missão em curso (com `fim_ms`) ou {}.

const _INT_FIELDS: PackedStringArray = [
	"lvl",
	"xp",
	"vint",
	"muir",
	"energia",
	"en_upd_ms",
	"coragem",
	"co_upd_ms",
	"honra",
	"feira_upd_ms",
	"chefe_espera_ms",
	"uid",
	"missoes",
	"rng_seed",
	"cmd_counter",
]

var profile_id: String = ""
var mode: String = "offline"
var nome: String = ""
## Origem escolhida na criação ("" = ainda não criado; "legado" = perfil de antes da v0.4.0).
var origem: String = ""
## Rosto e cores do guardião, um índice por bloco (ver VisualRules).
var visual: Dictionary = VisualRules.PADRAO.duplicate()
var lvl: int = 1
var xp: int = 0
var vint: int = 0
var muir: int = 0
var energia: int = 0
var en_upd_ms: int = 0
var coragem: int = 0
var co_upd_ms: int = 0
var honra: int = 0
var stats: Dictionary[String, int] = {}
var equip: Dictionary[String, Variant] = {}
var mochila: Array[Dictionary] = []
var ofertas: Array[Dictionary] = []
var ativa: Dictionary = {}
var feira: Array[Dictionary] = []
var feira_upd_ms: int = 0
var rivais: Array[Dictionary] = []
var duelos: Array[Dictionary] = []
var vitorias: Dictionary[String, int] = {}
var vistos: Dictionary[String, bool] = {}
var fases: PackedInt32Array = PackedInt32Array([0, 0, 0])
var chefe_espera_ms: int = 0
var uid: int = 1
var missoes: int = 0
var rng_seed: int = 0
## O índice 0 de `derive_seed(rng_seed, n)` é do `new_game`; o primeiro comando usa 1.
var cmd_counter: int = 0


static func new_game(
	profile_value: String,
	mode_value: String,
	nome_value: String,
	seed_value: int,
	now_ms: int,
	rules: RulesPack
) -> GameState:
	var s := GameState.new()
	var start: Dictionary = rules.balance.start
	s.profile_id = profile_value
	s.mode = mode_value
	s.nome = NameRules.sanitize(nome_value, rules)
	s.vint = int(start["vint"])
	s.muir = int(start["muir"])
	s.energia = rules.balance.en_max
	s.en_upd_ms = now_ms
	s.coragem = rules.balance.co_max
	s.co_upd_ms = now_ms
	var base: Dictionary = start["stats"]
	for k: String in Defs.STAT_KEYS:
		s.stats[k] = int(base[k])
	for slot: String in Defs.SLOT_KEYS:
		s.equip[slot] = null
	var weapon: Dictionary = (start["weapon"] as Dictionary).duplicate(true)
	weapon["id"] = s.uid
	s.uid += 1
	s.equip[str(weapon["slot"])] = weapon
	s.rng_seed = seed_value
	s.cmd_counter = 1
	Refill.ensure(s, now_ms, Rng.new(Rng.derive_seed(seed_value, 0)), rules)
	return s


## Atributos base mais os do equipamento.
func total_stats() -> Dictionary:
	var out: Dictionary = {}
	for k: String in stats:
		out[k] = stats[k]
	for slot: String in equip:
		var item: Variant = equip[slot]
		if item is Dictionary:
			var bonus: Dictionary = (item as Dictionary)["st"]
			for k: String in bonus:
				out[k] = int(out.get(k, 0)) + int(bonus[k])
	return out


func clone() -> GameState:
	return GameState.from_dict(to_dict())


func to_dict() -> Dictionary:
	return {
		"profile_id": profile_id,
		"mode": mode,
		"nome": nome,
		"origem": origem,
		"visual": visual.duplicate(),
		"lvl": lvl,
		"xp": xp,
		"vint": vint,
		"muir": muir,
		"energia": energia,
		"en_upd_ms": en_upd_ms,
		"coragem": coragem,
		"co_upd_ms": co_upd_ms,
		"honra": honra,
		"stats": stats.duplicate(true),
		"equip": equip.duplicate(true),
		"mochila": mochila.duplicate(true),
		"ofertas": ofertas.duplicate(true),
		"ativa": ativa.duplicate(true),
		"feira": feira.duplicate(true),
		"feira_upd_ms": feira_upd_ms,
		"rivais": rivais.duplicate(true),
		"duelos": duelos.duplicate(true),
		"vitorias": vitorias.duplicate(true),
		"vistos": vistos.duplicate(true),
		"fases": Array(fases),
		"chefe_espera_ms": chefe_espera_ms,
		"uid": uid,
		"missoes": missoes,
		"rng_seed": rng_seed,
		"cmd_counter": cmd_counter,
	}


## Lê um estado de dicionário (por exemplo, vindo de JSON, onde todo número é `float`).
static func from_dict(d: Dictionary) -> GameState:
	var s := GameState.new()
	s.profile_id = str(d.get("profile_id", ""))
	s.mode = str(d.get("mode", "offline"))
	s.nome = str(d.get("nome", ""))
	s.origem = str(d.get("origem", ""))
	s.visual = VisualRules.sanitize(d.get("visual", {}))
	for key: String in _INT_FIELDS:
		s.set(key, int(d.get(key, s.get(key))))
	var st: Dictionary = d.get("stats", {})
	for k: String in st:
		s.stats[k] = int(st[k])
	var eq: Dictionary = d.get("equip", {})
	for slot: String in eq:
		s.equip[slot] = null if eq[slot] == null else Defs.normalize(eq[slot])
	s.mochila = _dict_list(d.get("mochila", []))
	s.ofertas = _dict_list(d.get("ofertas", []))
	s.feira = _dict_list(d.get("feira", []))
	s.rivais = _dict_list(d.get("rivais", []))
	s.duelos = _dict_list(d.get("duelos", []))
	var active: Variant = Defs.normalize(d.get("ativa", {}))
	s.ativa = active if active is Dictionary else {}
	var wins: Dictionary = d.get("vitorias", {})
	for k: String in wins:
		s.vitorias[k] = int(wins[k])
	var seen: Dictionary = d.get("vistos", {})
	for k: String in seen:
		s.vistos[k] = bool(seen[k])
	var phases: Array = d.get("fases", [0, 0, 0])
	s.fases = PackedInt32Array(Defs.to_int_array(phases))
	return s


static func _dict_list(raw: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for v: Variant in raw:
		out.append(Defs.normalize(v))
	return out
