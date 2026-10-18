extends AbaBase
## Ajustes: velocidade da luta, painel de desempenho, diagnóstico, versão clássica e versão.

const LINK_V02: String = "../v02/"


func _montar(corpo: VBoxContainer) -> void:
	corpo.add_child(rotulo("Ajustes", &"Titulo"))
	corpo.add_child(rotulo("Velocidade da luta", &"Subtitulo"))
	var linha := HBoxContainer.new()
	corpo.add_child(linha)
	for v: int in Ajustes.VELOCIDADES:
		var b := botao("Velocidade_%d" % v, "%d×" % v)
		b.toggle_mode = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_velocidade.bind(v))
		linha.add_child(b)
	var painel := botao("PainelDesempenho", "Painel de desempenho")
	painel.pressed.connect(func() -> void: get_node("/root/PerfOverlay").call("toggle"))
	corpo.add_child(painel)
	var diag := botao("Diagnostico", "Diagnóstico")
	diag.pressed.connect(
		func() -> void: get_tree().change_scene_to_file("res://ui/diagnostico.tscn")
	)
	corpo.add_child(diag)
	if OS.has_feature("web"):
		var v02 := botao("VersaoClassica", "Versão clássica (v0.2)")
		v02.pressed.connect(func() -> void: OS.shell_open(LINK_V02))
		corpo.add_child(v02)
	var versao: String = str(ProjectSettings.get_setting("application/config/version"))
	corpo.add_child(rotulo("Guardiões do Folclore · versão %s" % versao, &"Dica", "VersaoAjustes"))


func atualizar() -> void:
	var atual: int = Ajustes.velocidade()
	for v: int in Ajustes.VELOCIDADES:
		var b: Button = find_child("Velocidade_%d" % v, true, false) as Button
		if b != null:
			b.set_pressed_no_signal(v == atual)


func _velocidade(v: int) -> void:
	Ajustes.definir_velocidade(v)
	atualizar()
