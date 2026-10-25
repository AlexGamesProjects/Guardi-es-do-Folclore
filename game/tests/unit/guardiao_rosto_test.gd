extends GdUnitTestSuite
## Rosto em blocos: opções mínimas, visual normalizado, cabeça montada e troca de cor.


func test_opcoes_minimas_por_bloco() -> void:
	for bloco: String in ["rosto", "olhos", "sobrancelhas", "nariz", "boca", "cabelo", "barba"]:
		var n: int = GuardiaoRosto.OPCOES[bloco].size()
		assert_int(n).override_failure_message(bloco).is_greater_equal(3)
	assert_int(GuardiaoRosto.PELES.size()).is_greater_equal(4)
	assert_int(GuardiaoRosto.PELES.size()).is_equal(GuardiaoRosto.OPCOES["pele"].size())
	var cores_cabelo: int = GuardiaoRosto.OPCOES["cor_cabelo"].size()
	assert_int(GuardiaoRosto.CORES_CABELO.size()).is_equal(cores_cabelo)
	assert_int(GuardiaoRosto.CORES_OLHOS.size()).is_equal(GuardiaoRosto.OPCOES["cor_olhos"].size())
	assert_int(GuardiaoRosto.ROUPAS.size()).is_equal(GuardiaoRosto.OPCOES["roupa"].size())


func test_normalizar_completa_e_corrige_indices() -> void:
	var v: Dictionary = GuardiaoRosto.normalizar({"pele": 3, "cabelo": 99, "olhos": -1})
	assert_int(int(v["pele"])).is_equal(3)
	assert_int(int(v["cabelo"])).is_equal(0)
	assert_int(int(v["olhos"])).is_equal(0)
	assert_int(v.size()).is_equal(GuardiaoRosto.OPCOES.size())


func test_toda_combinacao_de_um_bloco_monta_sem_magenta() -> void:
	for bloco: String in GuardiaoRosto.OPCOES:
		for i: int in GuardiaoRosto.OPCOES[bloco].size():
			var v: Dictionary = {bloco: i}
			for chapeu: bool in [false, true]:
				var img: Image = GuardiaoRosto.montar(v, chapeu)
				var magenta: int = 0
				for y: int in 32:
					for x: int in 32:
						if img.get_pixel(x, y) == Color.MAGENTA:
							magenta += 1
				assert_int(magenta).override_failure_message("%s %d" % [bloco, i]).is_equal(0)


func test_blocos_mudam_a_cabeca() -> void:
	for bloco: String in ["rosto", "olhos", "sobrancelhas", "nariz", "boca", "cabelo", "barba"]:
		var base: Image = GuardiaoRosto.montar({bloco: 0})
		for i: int in range(1, GuardiaoRosto.OPCOES[bloco].size()):
			var img: Image = GuardiaoRosto.montar({bloco: i})
			var msg: String = "%s %d igual à opção 0" % [bloco, i]
			assert_bool(img.get_data() != base.get_data()).override_failure_message(msg).is_true()


func test_troca_de_pele_mantem_luz_e_contorno() -> void:
	var pele: Color = GuardiaoRosto.PELES[0]
	var media: Color = GuardiaoRosto.trocar(GuardiaoRosto.PELE_BASE, pele, Color.TRANSPARENT)
	assert_float(media.r).is_equal_approx(pele.r, 0.01)
	var sombra: Color = GuardiaoRosto.trocar(Color("a6765e"), pele, Color.TRANSPARENT)
	assert_float(sombra.get_luminance()).is_less(media.get_luminance())
	var contorno: Color = Color("0b0a0a")
	assert_object(GuardiaoRosto.trocar(contorno, pele, Color.RED)).is_equal(contorno)
	# Sem cor de roupa, os cinzas ficam.
	var cinza: Color = Color("b9b8b9")
	assert_object(GuardiaoRosto.trocar(cinza, pele, Color.TRANSPARENT)).is_equal(cinza)
