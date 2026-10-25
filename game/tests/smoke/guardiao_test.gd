extends GdUnitTestSuite
## Guardião em camadas: corpo nas tiras, cabeça em blocos no pescoço de cada quadro, itens por
## cima, cores de pele e roupa, e animações.

var _rules: RulesPack
var _log: MotorErros


func before() -> void:
	_rules = Fx.rules()


func before_test() -> void:
	_log = MotorErros.new()
	OS.add_logger(_log)


func after_test() -> void:
	OS.remove_logger(_log)


func _guardiao() -> Guardiao:
	var g: Guardiao = auto_free(Guardiao.new())
	add_child(g)
	return g


func _caminho(sprite: Sprite2D) -> String:
	return "" if sprite.texture == null else sprite.texture.resource_path


func test_corpo_tem_as_cinco_tiras_e_pontos_em_cada_quadro() -> void:
	var g: Guardiao = _guardiao()
	var sf: SpriteFrames = g.corpo().sprite_frames
	var pontos: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Guardiao.PONTOS))
	for acao: String in SpriteLib.ACOES:
		assert_bool(sf.has_animation(acao)).override_failure_message(acao).is_true()
		var lista: Array = pontos[acao]
		assert_int(lista.size()).is_equal(sf.get_frame_count(acao))


func test_cabeca_segue_o_pescoco_do_quadro() -> void:
	var g: Guardiao = _guardiao()
	var pontos: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Guardiao.PONTOS))
	g.animar("golpe")
	g.corpo().frame = 3
	g.corpo().frame_changed.emit()
	var p: Array = pontos["golpe"][3]
	var esperado: Vector2 = g.corpo().position + Vector2(float(p[0]), float(p[1]))
	assert_vector(g.cabeca().position).is_equal(esperado)
	assert_float(g.cabeca().rotation_degrees).is_equal_approx(float(p[2]), 0.01)


func test_pes_ficam_na_linha_dos_pes() -> void:
	var g: Guardiao = _guardiao()
	var pes: int = SpriteLib.pes(Guardiao.ID, "parado", 0)
	assert_float(g.corpo().position.y + pes).is_equal(float(Guardiao.PES))


func test_chapeu_arma_e_amuleto() -> void:
	var g: Guardiao = _guardiao()
	(
		g
		. vestir(
			{
				"cabeca": {"nome": "Chapéu de Couro do Pampa", "slot": "cabeca", "rar": 0},
				"arma": {"nome": "Facão de Aroeira", "slot": "arma", "rar": 1},
				"amuleto": {"nome": "Patuá", "slot": "amuleto", "rar": 0},
			},
			_rules
		)
	)
	assert_str(_caminho(g.peca("cabeca"))).ends_with("itens/chapeu_couro.png")
	assert_str(_caminho(g.peca("arma"))).ends_with("itens/facao.png")
	assert_str(_caminho(g.peca("amuleto"))).ends_with("itens/patua.png")
	assert_str(g.brilho("arma")).is_equal("rara")
	# O chapéu é filho da cabeça: gira com ela.
	assert_object(g.peca("cabeca").get_parent()).is_same(g.cabeca())


func test_roupa_do_item_troca_a_cor() -> void:
	var g: Guardiao = _guardiao()
	assert_object(g.cor_roupa()).is_equal(GuardiaoRosto.ROUPAS[0])
	g.vestir({"corpo": {"nome": "Poncho de Lã", "slot": "corpo", "rar": 0}}, _rules)
	assert_object(g.cor_roupa()).is_equal(Guardiao.ROUPA_ITEM["poncho_la"])
	g.vestir({}, _rules)
	assert_object(g.cor_roupa()).is_equal(GuardiaoRosto.ROUPAS[0])


func test_visual_troca_rosto_e_pele() -> void:
	var g: Guardiao = _guardiao()
	var antes: Texture2D = g.cabeca().texture
	g.aplicar_visual({"pele": 4, "cabelo": 2, "barba": 2})
	assert_object(g.cabeca().texture).is_not_same(antes)
	var m: ShaderMaterial = g.corpo().material as ShaderMaterial
	assert_object(m.get_shader_parameter("pele")).is_equal(GuardiaoRosto.PELES[4])
	assert_int(int(g.visual()["cabelo"])).is_equal(2)


func test_lendario_liga_brilho() -> void:
	var g: Guardiao = _guardiao()
	g.vestir({"arma": {"nome": "Peixeira", "slot": "arma", "rar": 2}}, _rules)
	assert_str(g.brilho("arma")).is_equal("lendario")
	g.vestir({"arma": {"nome": "Peixeira", "slot": "arma", "rar": 0}}, _rules)
	assert_str(g.brilho("arma")).is_equal("")


func test_cada_animacao_toca_sem_erro() -> void:
	var g: Guardiao = _guardiao()
	for acao: String in ["parado", "ataque", "critico", "golpe", "esquiva", "derrota", "vitoria"]:
		g.animar(acao)
		await get_tree().process_frame
	assert_array(g.historico).contains(["ataque", "derrota", "vitoria"])
	assert_array(_log.errors).is_empty()


func test_ataque_segura_o_punho_ate_recolher() -> void:
	var g: Guardiao = _guardiao()
	g.animar("ataque", 0.1)
	await get_tree().create_timer(0.4).timeout
	assert_str(str(g.corpo().animation)).is_equal("ataque")
	assert_int(g.corpo().frame).is_equal(SpriteLib.pico(Guardiao.ID, "ataque", 1))
	g.recolher()
	assert_str(str(g.corpo().animation)).is_equal("parado")


func test_item_sem_visual_nao_da_erro() -> void:
	var g: Guardiao = _guardiao()
	g.vestir({"arma": {"nome": "Espada Laser", "slot": "arma", "rar": 0}}, _rules)
	assert_object(g.peca("arma").texture).is_null()
	assert_array(_log.errors).is_empty()
