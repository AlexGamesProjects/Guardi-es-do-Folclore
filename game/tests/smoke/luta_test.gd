extends GdUnitTestSuite
## A camada de luta toca os eventos do núcleo: animação certa por evento, pular e velocidade.

const EVENTOS: Array[Dictionary] = [
	{
		"type": "luta",
		"contexto": "fase",
		"heroi": {"nome": "Jaci", "lvl": 1, "hp": 100},
		"inimigo": {"nome": "Saci Ligeiro", "lvl": 1, "hp": 80, "legend_id": "saci"},
	},
	{"type": "golpe", "atacante": 0, "dano": 10, "hp": [100, 70]},
	{"type": "critico", "atacante": 1, "dano": 20, "hp": [80, 70]},
	{"type": "esquiva", "atacante": 0},
	{"type": "fim", "vencedor": 0},
	{"type": "vintens_ganhos", "amount": 50, "origem": "fase"},
]


func _luta() -> Luta:
	var luta := Luta.new()
	add_child(luta)
	return luta


func _esperar(luta: Luta) -> void:
	for i: int in 60:
		if luta.terminada:
			return
		await get_tree().create_timer(0.05).timeout


func test_cada_evento_chama_animacao_certa() -> void:
	var luta: Luta = _luta()
	luta.tocar(EVENTOS, 4)
	await _esperar(luta)
	assert_array(luta.heroi.historico).is_equal(["parado", "ataque", "golpe", "ataque", "vitoria"])
	luta.queue_free()


func test_inimigo_recebe_golpe_e_ataca_critico() -> void:
	var luta: Luta = _luta()
	luta.tocar(EVENTOS, 4)
	await _esperar(luta)
	assert_array(luta.inimigo.historico).is_equal(
		["parado", "golpe", "critico", "esquiva", "derrota"]
	)
	luta.queue_free()


func test_pular_vai_ao_resultado() -> void:
	var luta: Luta = _luta()
	luta.tocar(EVENTOS, 1)
	luta.pular()
	assert_bool(luta.terminada).is_true()
	assert_str(luta.resultado_texto()).contains("Vitória")
	assert_str(luta.resultado_texto()).contains("+50 vinténs")
	luta.queue_free()


func test_velocidade_4x_mais_rapida() -> void:
	var luta: Luta = _luta()
	luta.tocar(EVENTOS, 4)
	assert_float(luta.intervalo_s()).is_equal_approx(Luta.INTERVALO_S / 4.0, 0.001)
	luta.queue_free()


func test_luta_pular_apos_pause_mostra_resultado() -> void:
	var luta: Luta = _luta()
	luta.tocar(EVENTOS, 1)
	luta.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	luta.pular()
	assert_bool(luta.terminada).is_true()
	assert_bool((luta.find_child("Resultado", true, false) as Control).visible).is_true()
	luta.queue_free()


func test_terminou_emitido_ao_fechar() -> void:
	var luta: Luta = _luta()
	luta.tocar(EVENTOS, 4)
	luta.pular()
	var recebidos: Array[Dictionary] = []
	luta.terminou.connect(func(r: Dictionary) -> void: recebidos.append(r))
	luta.fechar()
	assert_array(recebidos).is_equal([{"vitoria": true}])


func test_atacante_avanca_e_volta() -> void:
	var luta: Luta = _luta()
	luta.size = Vector2(720, 1280)
	luta.tocar(EVENTOS, 4)
	await get_tree().process_frame
	var inicio: float = luta.heroi.position.x
	await _esperar(luta)
	await get_tree().create_timer(0.3).timeout
	assert_float(luta.heroi.position.x).is_equal_approx(inicio, 1.0)
	assert_int(luta.avancos).is_greater_equal(2)
	luta.queue_free()


func test_numero_de_dano_mostra_valor() -> void:
	var luta: Luta = _luta()
	luta.tocar(EVENTOS, 1)
	await get_tree().create_timer(Luta.INTERVALO_S + 0.15).timeout
	assert_array(luta.numeros_mostrados).contains(["−10"])
	luta.pular()
	assert_array(luta.numeros_mostrados).contains(["−20"])
	luta.queue_free()


func test_heroi_usa_boneco_articulado() -> void:
	var luta: Luta = _luta()
	luta.tocar(EVENTOS, 4)
	assert_object(luta.heroi.find_child("Boneco", true, false)).is_not_null()
	luta.queue_free()
