class_name EditorVisual
extends VBoxContainer
## Escolha do visual do guardião: a prévia (Guardiao) e, para cada bloco, ◀ nome ▶. Não manda
## comando: quem usa lê `visual()` (ou ouve `mudou`) e salva.

signal mudou(visual: Dictionary)

const NOMES_BLOCO: Dictionary[String, String] = {
	"pele": "Pele",
	"rosto": "Rosto",
	"olhos": "Olhos",
	"cor_olhos": "Cor dos olhos",
	"sobrancelhas": "Sobrancelhas",
	"nariz": "Nariz",
	"boca": "Boca",
	"cabelo": "Cabelo",
	"cor_cabelo": "Cor do cabelo",
	"barba": "Barba",
	"roupa": "Roupa",
}

var _visual: Dictionary = VisualRules.PADRAO.duplicate()
var _previa: Guardiao
var _valores: Dictionary[String, Label] = {}


func _init() -> void:
	name = "EditorVisual"
	add_theme_constant_override("separation", 8)
	_previa = Guardiao.new()
	_previa.name = "PreviaGuardiao"
	_previa.escala = 3
	_previa.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_child(_previa)
	for bloco: String in GuardiaoRosto.OPCOES:
		var linha := HBoxContainer.new()
		linha.add_theme_constant_override("separation", 8)
		var nome := AbaBase.rotulo(NOMES_BLOCO[bloco], &"Dica")
		nome.custom_minimum_size = Vector2(220, 0)
		nome.autowrap_mode = TextServer.AUTOWRAP_OFF
		linha.add_child(nome)
		linha.add_child(_seta("Menos_" + bloco, "<", bloco, -1))
		var valor := AbaBase.rotulo("", &"Valor", "Valor_" + bloco)
		valor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		valor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		valor.autowrap_mode = TextServer.AUTOWRAP_OFF
		linha.add_child(valor)
		_valores[bloco] = valor
		linha.add_child(_seta("Mais_" + bloco, ">", bloco, 1))
		add_child(linha)
	var sortear := AbaBase.botao("Sortear", "Sortear visual")
	sortear.pressed.connect(sortear_visual)
	add_child(sortear)
	_mostrar()


func visual() -> Dictionary:
	return _visual.duplicate()


## Mostra um visual (saneado) sem avisar `mudou`.
func definir(v: Dictionary) -> void:
	_visual = VisualRules.sanitize(v)
	_mostrar()


## Veste a prévia com o equipamento (só para ver; não muda o visual).
func vestir(equip: Dictionary, rules: RulesPack) -> void:
	_previa.vestir(equip, rules)


func previa() -> Guardiao:
	return _previa


## Passa o bloco para a opção seguinte (`passo` 1) ou anterior (-1), dando a volta.
func trocar(bloco: String, passo: int) -> void:
	var n: int = VisualRules.BLOCOS[bloco]
	_visual[bloco] = posmod(int(_visual[bloco]) + passo, n)
	_mostrar()
	mudou.emit(visual())


func sortear_visual() -> void:
	for bloco: String in VisualRules.BLOCOS:
		_visual[bloco] = randi() % VisualRules.BLOCOS[bloco]
	_mostrar()
	mudou.emit(visual())


func _seta(nome: String, texto: String, bloco: String, passo: int) -> Button:
	var b := AbaBase.botao(nome, texto)
	b.custom_minimum_size = Vector2(88, 72)
	b.pressed.connect(trocar.bind(bloco, passo))
	return b


func _mostrar() -> void:
	_previa.aplicar_visual(_visual)
	for bloco: String in _valores:
		_valores[bloco].text = str(GuardiaoRosto.OPCOES[bloco][int(_visual[bloco])])
