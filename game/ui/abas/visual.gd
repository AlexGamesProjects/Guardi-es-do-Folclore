extends AbaBase
## Visual do guardião (Mais → Guardião): troca rosto, cabelo e cores a qualquer hora, de graça.
## A prévia veste o que está equipado; "Salvar" manda `mudar_visual`.

var _editor: EditorVisual
var _salvar: Button
## Há mudança ainda não salva (o estado não sobrescreve a escolha em andamento).
var _mexido: bool = false


func _montar(corpo: VBoxContainer) -> void:
	contexto = "visual"
	corpo.add_child(rotulo("Seu guardião", &"Titulo"))
	_editor = EditorVisual.new()
	_editor.mudou.connect(func(_v: Dictionary) -> void: _mexer(true))
	corpo.add_child(_editor)
	_salvar = botao("SalvarVisual", "Salvar visual", true)
	_salvar.pressed.connect(salvar)
	corpo.add_child(_salvar)


func atualizar() -> void:
	var s: GameState = estado()
	if _editor == null or s == null:
		return
	if not _mexido:
		_editor.definir(s.visual)
	_editor.vestir(s.equip, regras())
	_salvar.disabled = not _mexido or ocupado()


func salvar() -> void:
	var res: CommandResult = await enviar("mudar_visual", {"visual": _editor.visual()})
	if res != null and res.ok:
		_mexer(false)
		Toast.avisar(self, "Visual salvo.", "ok")


func _mexer(sim: bool) -> void:
	_mexido = sim
	atualizar()
