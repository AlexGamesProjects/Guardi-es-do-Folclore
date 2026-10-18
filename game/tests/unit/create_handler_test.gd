extends GdUnitTestSuite
## `criar_guardiao`: nome e origem, uma vez só, com o bônus da origem nos atributos base.

const BASE: String = "res://data/packs/base"

var _rules: RulesPack


func before() -> void:
	_rules = Fx.rules()


func test_criar_aplica_bonus_sertao() -> void:
	var s: GameState = Fx.game(_rules)
	var fol: int = s.stats["fol"]
	var res: CommandResult = Fx.run(
		s, "criar_guardiao", {"nome": "Iracema", "origem": "sertao"}, _rules
	)
	assert_bool(res.ok).is_true()
	assert_str(res.state.origem).is_equal("sertao")
	assert_str(res.state.nome).is_equal("Iracema")
	assert_int(res.state.stats["fol"]).is_equal(fol + 2)


func test_cada_origem_da_dois_pontos() -> void:
	for origem: String in ["mata_atlantica", "sertao", "amazonia", "pampa"]:
		var s: GameState = Fx.game(_rules)
		var antes: int = 0
		for k: String in Defs.STAT_KEYS:
			antes += s.stats[k]
		var res: CommandResult = Fx.run(
			s, "criar_guardiao", {"nome": "Jaci", "origem": origem}, _rules
		)
		var depois: int = 0
		for k: String in Defs.STAT_KEYS:
			depois += res.state.stats[k]
		assert_int(depois - antes).is_equal(2)


func test_criar_duas_vezes_ja_criado() -> void:
	var s: GameState = Fx.game(_rules)
	var r1: CommandResult = Fx.run(s, "criar_guardiao", {"nome": "Jaci", "origem": "pampa"}, _rules)
	var r2: CommandResult = Fx.run(
		r1.state, "criar_guardiao", {"nome": "Jaci", "origem": "pampa"}, _rules
	)
	assert_bool(r2.ok).is_false()
	assert_str(r2.error).is_equal("JA_CRIADO")
	assert_int(r2.state.stats["for"]).is_equal(r1.state.stats["for"])


func test_origem_invalida_mantem_estado() -> void:
	var s: GameState = Fx.game(_rules)
	var antes: Dictionary = s.to_dict()
	var res: CommandResult = Fx.run(s, "criar_guardiao", {"nome": "Jaci", "origem": "lua"}, _rules)
	assert_str(res.error).is_equal("ORIGEM_INVALIDA")
	assert_dict(res.state.to_dict()).is_equal(antes)


func test_nome_e_saneado_como_no_renomear() -> void:
	var s: GameState = Fx.game(_rules)
	var res: CommandResult = Fx.run(
		s, "criar_guardiao", {"nome": "  ", "origem": "amazonia"}, _rules
	)
	assert_str(res.state.nome).is_equal(NameRules.sanitize("  ", _rules))


func test_validator_reprova_origem_sem_bonus() -> void:
	var files: Dictionary = {}
	for f: String in DirAccess.get_files_at(BASE):
		if f.ends_with(".json"):
			files[f] = JSON.parse_string(FileAccess.get_file_as_string(BASE + "/" + f))
	assert_array(RulesValidator.validate(files)).is_empty()
	files["balance.json"]["origens"]["lua"] = {"nome": "Lua"}
	var erros: PackedStringArray = RulesValidator.validate(files)
	assert_bool(" ".join(erros).contains("origens")).is_true()
