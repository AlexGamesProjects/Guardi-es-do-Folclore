extends GdUnitTestSuite
## Guardião articulado: ossos, roupa por item, animações e brilho por raridade.

const OSSOS: Array[String] = [
	"Quadril",
	"Tronco",
	"Cabeca",
	"BracoTras",
	"AntebracoTras",
	"BracoFrente",
	"AntebracoFrente",
	"CoxaTras",
	"CanelaTras",
	"CoxaFrente",
	"CanelaFrente",
]

var _rules: RulesPack
var _log: MotorErros


func before() -> void:
	_rules = Fx.rules()


func before_test() -> void:
	_log = MotorErros.new()
	OS.add_logger(_log)


func after_test() -> void:
	OS.remove_logger(_log)


func _boneco() -> Boneco:
	var b := Boneco.new()
	add_child(b)
	return b


func _caminho(sprite: Sprite2D) -> String:
	return "" if sprite.texture == null else sprite.texture.resource_path


func test_onze_ossos() -> void:
	var b: Boneco = _boneco()
	for nome: String in OSSOS:
		assert_object(b.osso(nome)).override_failure_message(nome).is_not_null()
	b.queue_free()


func test_chapeu_vai_na_cabeca() -> void:
	var b: Boneco = _boneco()
	b.vestir({"cabeca": {"nome": "Chapéu de Couro do Pampa", "slot": "cabeca", "rar": 0}}, _rules)
	assert_str(_caminho(b.peca("cabeca"))).ends_with("itens/chapeu_couro.png")
	b.queue_free()


func test_roupa_troca_tronco_e_bracos() -> void:
	var b: Boneco = _boneco()
	assert_str(_caminho(b.parte("Tronco"))).ends_with("partes/tronco.png")
	b.vestir({"corpo": {"nome": "Poncho de Lã", "slot": "corpo", "rar": 0}}, _rules)
	assert_str(_caminho(b.parte("Tronco"))).ends_with("itens/poncho_la_tronco.png")
	assert_str(_caminho(b.parte("BracoFrente"))).ends_with("itens/poncho_la_braco.png")
	b.vestir({}, _rules)
	assert_str(_caminho(b.parte("Tronco"))).ends_with("partes/tronco.png")
	b.queue_free()


func test_arma_e_amuleto() -> void:
	var b: Boneco = _boneco()
	(
		b
		. vestir(
			{
				"arma": {"nome": "Facão de Aroeira", "slot": "arma", "rar": 1},
				"amuleto": {"nome": "Patuá", "slot": "amuleto", "rar": 0},
			},
			_rules
		)
	)
	assert_str(_caminho(b.peca("arma"))).ends_with("itens/facao.png")
	assert_str(_caminho(b.peca("amuleto"))).ends_with("itens/patua.png")
	b.queue_free()


func test_lendario_liga_brilho() -> void:
	var b: Boneco = _boneco()
	b.vestir({"arma": {"nome": "Peixeira", "slot": "arma", "rar": 2}}, _rules)
	assert_str(b.brilho("arma")).is_equal("lendario")
	b.vestir({"arma": {"nome": "Peixeira", "slot": "arma", "rar": 0}}, _rules)
	assert_str(b.brilho("arma")).is_equal("")
	b.queue_free()


func test_cada_animacao_toca_sem_erro() -> void:
	var b: Boneco = _boneco()
	for acao: String in [
		"parado", "ataque", "critico", "golpe", "esquiva", "derrota", "vitoria", "andar"
	]:
		b.animar(acao)
		await get_tree().process_frame
	assert_array(b.historico).contains(["ataque", "derrota", "vitoria"])
	assert_array(_log.errors).is_empty()
	b.queue_free()


func test_item_sem_visual_nao_da_erro() -> void:
	var b: Boneco = _boneco()
	b.vestir({"arma": {"nome": "Espada Laser", "slot": "arma", "rar": 0}}, _rules)
	assert_object(b.peca("arma").texture).is_null()
	assert_array(_log.errors).is_empty()
	b.queue_free()
