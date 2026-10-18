extends GdUnitTestSuite
## Balanceamento: o jogador típico de `BalanceSim`, agregado em 20 sementes, tem de cair nas
## faixas de `balance.json` (`bands`): vitória nas fases 1 a 9 no nível certo, vitória nos chefes
## e missões até o nível 30.

const SEEDS: int = 20

var _rules: RulesPack
var _agg: Dictionary = {}


func before() -> void:
	_rules = RulesLoader.load_dir("res://data/packs/base").pack
	var stage: int = 0
	var boss: int = 0
	var missions: int = 0
	for seed_value: int in range(1, SEEDS + 1):
		var r: Dictionary = BalanceSim.run(_rules, seed_value)
		stage += int(r["stage_win_bp"])
		boss += int(r["boss_win_bp"])
		missions += int(r["missions_to_30"])
	_agg = {
		"stage_win_bp": stage / SEEDS,
		"boss_win_bp": boss / SEEDS,
		"missions_to_30": missions / SEEDS,
	}
	print("balance: %s" % str(_agg))


func _assert_band(value: int, band_key: String) -> void:
	var band: Array = _rules.balance.bands[band_key]
	(
		assert_int(value)
		. override_failure_message(
			"%s = %d fora da faixa [%d, %d]" % [band_key, value, int(band[0]), int(band[1])]
		)
		. is_between(int(band[0]), int(band[1]))
	)


func test_stage_win_rate_in_band() -> void:
	_assert_band(int(_agg["stage_win_bp"]), "stage_win_bp")


func test_boss_win_rate_in_band() -> void:
	_assert_band(int(_agg["boss_win_bp"]), "boss_win_bp")


func test_missions_to_30_in_band() -> void:
	_assert_band(int(_agg["missions_to_30"]), "lvl30_missions")


func test_sim_is_deterministic() -> void:
	var a: Dictionary = BalanceSim.play(_rules, 3, [])
	var b: Dictionary = BalanceSim.play(_rules, 3, [])
	assert_int(int(a["commands"])).is_equal(int(b["commands"]))
	assert_int(int(a["missions_to_30"])).is_equal(int(b["missions_to_30"]))
	var sa: GameState = a["state"]
	var sb: GameState = b["state"]
	assert_dict(sa.to_dict()).is_equal(sb.to_dict())
