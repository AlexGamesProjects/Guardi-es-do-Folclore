extends GdUnitTestSuite
## Esqueleto único (#32): as lendas montadas das partes recortadas, as animações comuns e a
## comparação com a tira.

const OSSOS: Array[String] = ["Quadril", "Tronco", "Cabeca", "Bracos", "PernaFrente", "PernaTras"]
## Lenda → lado do quadro de origem.
const LADOS: Dictionary[String, int] = {
	"saci": 104,
	"curupira": 104,
	"cuca": 100,
	"iara": 112,
	"boto": 112,
	"mapinguari": 128,
}

var _log: MotorErros


func before_test() -> void:
	_log = MotorErros.new()
	OS.add_logger(_log)


func after_test() -> void:
	OS.remove_logger(_log)


func _saci() -> Esqueleto:
	var e := Esqueleto.new()
	add_child(e)
	assert_bool(e.montar("saci")).is_true()
	return e


func test_monta_os_seis_ossos_de_cada_lenda() -> void:
	for id: String in LADOS:
		var e := Esqueleto.new()
		add_child(e)
		assert_bool(e.montar(id)).override_failure_message(id).is_true()
		for nome: String in OSSOS:
			var o: Bone2D = e.osso(nome)
			assert_object(o).override_failure_message(id + " " + nome).is_not_null()
			assert_object(o.get_node("Arte").get("texture")).is_not_null()
		assert_int(e.lado).override_failure_message(id).is_equal(LADOS[id])
		e.queue_free()
	assert_array(_log.errors).is_empty()


func test_lenda_sem_montagem_nao_monta() -> void:
	assert_bool(Esqueleto.existe("saci")).is_true()
	assert_bool(Esqueleto.existe("boitata")).is_false()
	assert_bool(Esqueleto.existe("")).is_false()
	var e := Esqueleto.new()
	assert_bool(e.montar("boitata")).is_false()
	e.free()


func test_tem_todas_as_acoes_do_lutador() -> void:
	var e: Esqueleto = _saci()
	e.historico.clear()
	for acao: String in Lutador.ACOES:
		e.animar(acao)
		assert_str(e.acao_atual()).override_failure_message(acao).is_equal(acao)
	assert_array(e.historico).is_equal(Lutador.ACOES)
	assert_array(_log.errors).is_empty()
	e.queue_free()


func test_ataque_volta_para_parado() -> void:
	var e: Esqueleto = _saci()
	e.animar("ataque")
	await await_millis(800)
	assert_str(e.acao_atual()).is_equal("parado")
	e.queue_free()


func test_derrota_fica_caida() -> void:
	var e: Esqueleto = _saci()
	e.animar("derrota")
	await await_millis(1200)
	var corpo: Node2D = e.find_child("Corpo", true, false) as Node2D
	assert_float(rad_to_deg(corpo.rotation)).is_greater(80.0)
	e.queue_free()


func test_tela_de_comparacao_abre_com_botoes() -> void:
	var tela: Control = (load("res://ui/comparar_esqueleto.tscn") as PackedScene).instantiate()
	add_child(tela)
	await await_idle_frame()
	assert_object(tela.find_child("Esqueleto", true, false)).is_not_null()
	for acao: String in Lutador.ACOES:
		var b: Button = tela.find_child("Acao_" + acao, true, false) as Button
		assert_object(b).override_failure_message(acao).is_not_null()
		b.pressed.emit()
	assert_array(_log.errors).is_empty()
	tela.queue_free()


func test_tela_de_comparacao_troca_de_lenda() -> void:
	var tela: Control = (load("res://ui/comparar_esqueleto.tscn") as PackedScene).instantiate()
	add_child(tela)
	await await_idle_frame()
	for id: String in LADOS:
		(tela.find_child("Lenda_" + id, true, false) as Button).pressed.emit()
		await await_idle_frame()
		assert_str(tela.get("lenda")).is_equal(id)
		var e: Esqueleto = tela.find_child("Esqueleto", true, false) as Esqueleto
		assert_int(e.lado).override_failure_message(id).is_equal(LADOS[id])
		# Todos os botões cabem na tela, mesmo com a lenda maior.
		await await_idle_frame()
		var vis: Rect2 = tela.get_viewport_rect()
		for b: Node in tela.find_children("*_*", "Button", true, false):
			var r: Rect2 = (b as Control).get_global_rect()
			assert_bool(vis.encloses(r)).override_failure_message(id + " " + b.name).is_true()
		(tela.find_child("Acao_ataque", true, false) as Button).pressed.emit()
	assert_array(_log.errors).is_empty()
	tela.queue_free()
