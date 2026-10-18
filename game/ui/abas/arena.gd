extends AbaBase
## Aba Arena: rivais da roda, desafio (gasta coragem), honra e últimos duelos.

var _honra: Label
var _rivais: VBoxContainer
var _historico: Label


func _montar(corpo: VBoxContainer) -> void:
	contexto = "arena"
	corpo.add_child(rotulo("Arena", &"Titulo"))
	_honra = rotulo("", &"Valor", "Honra")
	corpo.add_child(_honra)
	_rivais = VBoxContainer.new()
	_rivais.add_theme_constant_override("separation", 12)
	corpo.add_child(_rivais)
	corpo.add_child(rotulo("Últimos duelos", &"Subtitulo"))
	_historico = rotulo("", &"Dica", "Historico")
	corpo.add_child(_historico)


func atualizar() -> void:
	var s: GameState = estado()
	var r: RulesPack = regras()
	if s == null or r == null or _rivais == null:
		return
	_honra.text = (
		"Honra: %d · cada desafio custa %d de coragem" % [s.honra, int(r.balance.arena["coragem"])]
	)
	for filho: Node in _rivais.get_children():
		_rivais.remove_child(filho)
		filho.queue_free()
	var busy: bool = ocupado()
	for i: int in s.rivais.size():
		var rv: Dictionary = s.rivais[i]
		var painel := cartao()
		var caixa := VBoxContainer.new()
		painel.add_child(caixa)
		caixa.add_child(rotulo("%s · nível %d" % [str(rv["nome"]), int(rv["lvl"])], &"Valor"))
		caixa.add_child(rotulo("Vale %d de honra" % int(rv["honra"]), &"Dica"))
		var b := botao("Desafiar_%d" % i, "Desafiar", true)
		b.disabled = busy
		b.pressed.connect(func() -> void: enviar("desafiar", {"rival_id": int(rv["id"])}))
		caixa.add_child(b)
		_rivais.add_child(painel)
	var linhas: Array[String] = []
	for d: Dictionary in s.duelos:
		var delta: int = int(d["honra"])
		linhas.append(
			(
				"%s %s · %s%d de honra"
				% [
					"Venceu" if bool(d["win"]) else "Perdeu para",
					str(d["nome"]),
					"+" if delta >= 0 else "",
					delta
				]
			)
		)
	_historico.text = "Nenhum duelo ainda." if linhas.is_empty() else "\n".join(linhas)
