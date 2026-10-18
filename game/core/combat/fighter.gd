class_name Fighter
extends RefCounted
## Combatente: o herói, um rival ou uma lenda inimiga. Atributos em inteiros.

var nome: String = ""
var lvl: int = 1
var stats: Dictionary[String, int] = {}
## Vazio para o herói ou um rival.
var legend_id: String = ""


static func make(
	nome_value: String, lvl_value: int, stats_value: Dictionary, legend_value: String = ""
) -> Fighter:
	var out := Fighter.new()
	out.nome = nome_value
	out.lvl = lvl_value
	for key: String in Defs.STAT_KEYS:
		out.stats[key] = int(stats_value.get(key, 0))
	out.legend_id = legend_value
	return out


func max_hp(cfg: Defs.CombatDef) -> int:
	return cfg.hp_base + stats["fol"] * cfg.hp_per_fol + lvl * cfg.hp_per_lvl
