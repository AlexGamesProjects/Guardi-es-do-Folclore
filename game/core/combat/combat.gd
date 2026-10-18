class_name Combat
extends RefCounted
## Simulação de combate determinística, só com inteiros. Mesmas sementes dão os mesmos eventos.

const BP_FULL: int = 10000
const X10_ROUND: int = 5000


## Chance de esquiva do defensor, em pontos-base.
static func dodge_bp(attacker: Fighter, defender: Fighter, cfg: Defs.CombatDef) -> int:
	var gin: int = defender.stats["gin"]
	var denom: int = gin + attacker.stats["for"] + cfg.chance_pad
	return clampi(gin * cfg.dodge_num / denom, cfg.dodge_min_bp, cfg.dodge_max_bp)


## Chance de crítico do atacante, em pontos-base.
static func crit_bp(attacker: Fighter, defender: Fighter, cfg: Defs.CombatDef) -> int:
	var mal: int = attacker.stats["mal"]
	var denom: int = mal + defender.stats["fol"] + cfg.chance_pad
	return clampi(mal * cfg.crit_num / denom, cfg.crit_min_bp, cfg.crit_max_bp)


## Dano base multiplicado por 10.
static func base_damage_x10(attacker: Fighter, cfg: Defs.CombatDef) -> int:
	return attacker.stats["for"] * cfg.dmg_for_x10 + attacker.lvl * cfg.dmg_lvl_x10


static func simulate(a: Fighter, b: Fighter, rng: Rng, cfg: Defs.CombatDef) -> CombatResult:
	var fighters: Array[Fighter] = [a, b]
	var max_hp: Array[int] = [a.max_hp(cfg), b.max_hp(cfg)]
	var hp: Array[int] = [max_hp[0], max_hp[1]]
	var result := CombatResult.new()
	var roll_a: int = rng.range_int(0, cfg.initiative_roll_max)
	var roll_b: int = rng.range_int(0, cfg.initiative_roll_max)
	var turn: int = 0 if a.stats["gin"] + roll_a >= b.stats["gin"] + roll_b else 1
	var swings: int = 0
	while swings < cfg.max_turns and hp[0] > 0 and hp[1] > 0:
		var atk: Fighter = fighters[turn]
		var def: Fighter = fighters[1 - turn]
		var kind: String = "golpe"
		var damage: int = 0
		if rng.roll_bp(dodge_bp(atk, def, cfg)):
			kind = "esquiva"
		else:
			var variation: int = rng.range_int(cfg.dmg_var_min_pm, cfg.dmg_var_max_pm)
			damage = maxi(1, (base_damage_x10(atk, cfg) * variation + X10_ROUND) / BP_FULL)
			if rng.roll_bp(crit_bp(atk, def, cfg)):
				kind = "critico"
				damage *= cfg.crit_mult
			hp[1 - turn] = maxi(0, hp[1 - turn] - damage)
		result.events.append({"type": kind, "atacante": turn, "dano": damage, "hp": [hp[0], hp[1]]})
		turn = 1 - turn
		swings += 1
	var a_wins: bool = hp[1] <= 0 or (hp[0] > 0 and hp[0] * max_hp[1] >= hp[1] * max_hp[0])
	result.win = a_wins
	result.hp_final = PackedInt32Array([hp[0], hp[1]])
	result.events.append({"type": "fim", "vencedor": 0 if a_wins else 1})
	return result
