class_name VisualRules
extends RefCounted
## Visual do guardião no estado: um índice por bloco (pele, rosto, olhos, ..., roupa). Aqui só
## ficam quantas opções cada bloco tem e o padrão; os desenhos e os nomes são da UI
## (GuardiaoRosto.OPCOES, que precisa ter o mesmo tamanho por bloco).

const BLOCOS: Dictionary[String, int] = {
	"pele": 5,
	"rosto": 3,
	"olhos": 3,
	"cor_olhos": 4,
	"sobrancelhas": 3,
	"nariz": 3,
	"boca": 3,
	"cabelo": 5,
	"cor_cabelo": 5,
	"barba": 4,
	"roupa": 5,
}
const PADRAO: Dictionary = {
	"pele": 1,
	"rosto": 0,
	"olhos": 0,
	"cor_olhos": 0,
	"sobrancelhas": 0,
	"nariz": 0,
	"boca": 0,
	"cabelo": 1,
	"cor_cabelo": 0,
	"barba": 0,
	"roupa": 0,
}


## Visual completo: o padrão com o que vier em `v` por cima. Índice fora da lista (ou que não
## seja número) volta ao 0; blocos desconhecidos saem.
static func sanitize(v: Variant) -> Dictionary:
	var out: Dictionary = PADRAO.duplicate()
	if not v is Dictionary:
		return out
	var d: Dictionary = v
	for bloco: String in BLOCOS:
		if not d.has(bloco):
			continue
		var x: Variant = d[bloco]
		var i: int = int(x) if x is int or x is float else -1
		out[bloco] = i if i >= 0 and i < BLOCOS[bloco] else 0
	return out
