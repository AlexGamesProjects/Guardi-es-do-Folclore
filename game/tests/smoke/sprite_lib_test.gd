extends GdUnitTestSuite
## SpriteLib monta SpriteFrames a partir de tiras PNG em res://assets/sprites/<id>/<acao>.png;
## sem sprite, o Lutador cai no retrato (carta ou inicial) sem erro.

const PASTA_TESTE: String = "user://sprites_teste"

var _log: MotorErros


func before_test() -> void:
	_log = MotorErros.new()
	OS.add_logger(_log)


func after_test() -> void:
	OS.remove_logger(_log)
	SpriteLib.raiz = SpriteLib.RAIZ_PADRAO
	SpriteLib.limpar_cache()


func _tira(acao: String, quadros: int, lado: int = 8) -> void:
	DirAccess.make_dir_recursive_absolute(PASTA_TESTE + "/teste")
	var img := Image.create(lado * quadros, lado, false, Image.FORMAT_RGBA8)
	img.fill(Color.RED)
	img.save_png("%s/teste/%s.png" % [PASTA_TESTE, acao])


func test_spritelib_monta_animacoes_das_tiras() -> void:
	_tira("parado", 4)
	_tira("ataque", 6)
	SpriteLib.raiz = PASTA_TESTE
	var frames: SpriteFrames = SpriteLib.frames("teste")
	assert_object(frames).is_not_null()
	assert_int(frames.get_frame_count("parado")).is_equal(4)
	assert_int(frames.get_frame_count("ataque")).is_equal(6)
	assert_bool(frames.get_animation_loop("parado")).is_true()
	assert_bool(frames.get_animation_loop("ataque")).is_false()


func test_spritelib_fallback_para_carta() -> void:
	assert_object(SpriteLib.frames("mula_sem_cabeca")).is_null()
	assert_object(SpriteLib.frames("")).is_null()
	assert_array(_log.errors).is_empty()


func test_lutador_com_sprite_toca_animacao() -> void:
	_tira("parado", 4)
	_tira("ataque", 6)
	SpriteLib.raiz = PASTA_TESTE
	var l := Lutador.new()
	add_child(l)
	l.preparar("Teste", 1, 50, null, "teste")
	l.animar("ataque")
	var spr: AnimatedSprite2D = l.find_child("Sprite", true, false) as AnimatedSprite2D
	assert_object(spr).is_not_null()
	assert_str(str(spr.animation)).is_equal("ataque")
	l.queue_free()


func test_tamanho_sprites_abaixo_200kb() -> void:
	var raiz: String = SpriteLib.RAIZ_PADRAO
	if not DirAccess.dir_exists_absolute(raiz):
		return
	for pasta: String in DirAccess.get_directories_at(raiz):
		for arq: String in DirAccess.get_files_at(raiz + "/" + pasta):
			if arq.ends_with(".png"):
				var f := FileAccess.open("%s/%s/%s" % [raiz, pasta, arq], FileAccess.READ)
				assert_int(f.get_length()).is_less(200_000)


func test_toda_lenda_inimiga_tem_as_cinco_tiras() -> void:
	var rules: RulesPack = Fx.rules()
	for id: String in rules.legends:
		if (rules.legends[id] as Defs.LegendDef).ally:
			continue
		var frames: SpriteFrames = SpriteLib.frames(id)
		assert_object(frames).override_failure_message(id).is_not_null()
		for acao: String in SpriteLib.ACOES:
			var tem: bool = frames.has_animation(acao)
			assert_bool(tem).override_failure_message("%s/%s" % [id, acao]).is_true()
