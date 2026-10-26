class_name GuardiaoRosto
extends RefCounted
## Monta a cabeça do guardião em blocos sobre o molde `cabeca.png` (32×32, pescoço em (16, 28),
## de perfil olhando para a direita): formato, olhos, sobrancelhas, nariz, boca, cabelo e barba,
## nas cores de pele, olhos e cabelo do visual. Cabelo e barba saem da forma da própria cabeça.
## Também guarda a troca de cor de pele e roupa usada no corpo (mesma conta do shader).

const MOLDE: String = "res://assets/sprites/guardiao/cabeca.png"
const PESCOCO: Vector2i = Vector2i(16, 28)
## Tom de pele e de roupa do desenho original; o resto é luz e sombra em volta deles.
const PELE_BASE: Color = Color("c59c7d")
const ROUPA_BASE: Color = Color("b9b8b9")

## Nome de cada opção, por bloco (o índice é o que fica no visual).
const OPCOES: Dictionary[String, Array] = {
	"pele": ["Clara", "Parda", "Morena", "Indígena", "Retinta"],
	"rosto": ["Oval", "Quadrado", "Comprido"],
	"olhos": ["Atentos", "Semicerrados", "Redondos"],
	"cor_olhos": ["Castanhos", "Pretos", "Verdes", "Azuis"],
	"sobrancelhas": ["Retas", "Grossas", "Arqueadas"],
	"nariz": ["Pequeno", "Médio", "Grande"],
	"boca": ["Reta", "Sorriso", "Carnuda"],
	"cabelo": ["Careca", "Curto", "Crespo", "Comprido", "Moicano"],
	"cor_cabelo": ["Preto", "Castanho", "Ruivo", "Loiro", "Grisalho"],
	"barba": ["Sem barba", "Cavanhaque", "Cheia", "Bigode"],
	"roupa": ["Cinza", "Terra", "Anil", "Mata", "Urucum"],
}
const PELES: Array[Color] = [
	Color("eec39c"), Color("c99a72"), Color("a8714f"), Color("b9835a"), Color("6e4630")
]
const CORES_OLHOS: Array[Color] = [
	Color("4a2a16"), Color("181214"), Color("3f6e34"), Color("3a5f9a")
]
## [principal, sombra, luz] de cada cor de cabelo.
const CORES_CABELO: Array[Array] = [
	[Color("2a211e"), Color("16100e"), Color("453631")],
	[Color("5e3b22"), Color("3d2514"), Color("7c5434")],
	[Color("a4512a"), Color("773519"), Color("c86d3c")],
	[Color("d6ad5e"), Color("a5803a"), Color("f0d08e")],
	[Color("a9a5a1"), Color("767270"), Color("d2cec9")],
]
const ROUPAS: Array[Color] = [
	Color("b9b8b9"), Color("b08a5e"), Color("6a7fb0"), Color("6f9a5a"), Color("c0583c")
]
const VISUAL_PADRAO: Dictionary = VisualRules.PADRAO

const CONTORNO: Color = Color("0b0a0a")
const BRANCO_OLHO: Color = Color("e4e0dd")
## Peças: [x, y] do canto e as linhas; "." deixa, "x" apaga, K contorno, S/D/E/M pele (média,
## sombra, escura, luz), R lábio, W branco do olho, P pupila, H/h/G cabelo (principal, sombra,
## luz).
const PECAS_ROSTO: Array = [
	[],
	[[17, 22], ["........K", "SSSSSSSSK", "SSSSSSSSK", "SSSSSSSSK", "..SSSSSSK", "..KKKKKKK"]],
	[[19, 26], ["SSSSSK", "DSSSSK", "DSSSK.", ".KKK.."]],
]
const PECAS_OLHOS: Array = [
	[[19, 17], ["KEEKM", "..WPW", "..WPW", "...M."]],
	[[19, 17], [".EEKM", "..KKK", "..WPW", "...M."]],
	[[19, 16], ["..KKK", ".KWPW", ".KWPP", "..KKK"]],
]
const PECAS_SOBRANCELHAS: Array = [
	[[20, 16], ["hhhhh"]],
	[[20, 15], [".hhhh", "hhhhh"]],
	[[20, 15], [".hhh.", "h...h"]],
]
const PECAS_NARIZ: Array = [
	[],
	[[25, 19], ["SK", "SK"]],
	[[25, 18], ["SK.", "SSK", "SSK", "DKK"]],
]
const PECAS_BOCA: Array = [
	[[22, 23], ["KK"]],
	[[20, 22], ["K...", ".KKK"]],
	[[21, 23], ["KKKK", ".RRR"]],
]
const PECAS_BIGODE: Array = [[20, 21], ["..hHH", ".hHHH", "h...h"]]

static var _molde: Image
static var _cache: Dictionary[String, ImageTexture] = {}


## Visual completo: o padrão com o que vier em `v` por cima (ver VisualRules.sanitize).
static func normalizar(v: Dictionary) -> Dictionary:
	return VisualRules.sanitize(v)


static func cor_pele(v: Dictionary) -> Color:
	return PELES[int(normalizar(v)["pele"])]


## Textura da cabeça montada (cache por visual). `com_chapeu` corta o cabelo acima da aba.
static func textura(v: Dictionary, com_chapeu: bool = false) -> ImageTexture:
	var n: Dictionary = normalizar(v)
	var chave: String = JSON.stringify(n) + str(com_chapeu)
	if not _cache.has(chave):
		_cache[chave] = ImageTexture.create_from_image(montar(n, com_chapeu))
	return _cache[chave]


static func montar(v: Dictionary, com_chapeu: bool = false) -> Image:
	var n: Dictionary = normalizar(v)
	if _molde == null:
		_molde = (load(MOLDE) as Texture2D).get_image()
		_molde.convert(Image.FORMAT_RGBA8)
	var img: Image = _molde.duplicate()
	var olho: Color = CORES_OLHOS[int(n["cor_olhos"])]
	var cab: Array = CORES_CABELO[int(n["cor_cabelo"])]
	_peca(img, PECAS_ROSTO[int(n["rosto"])], olho, cab)
	_peca(img, PECAS_NARIZ[int(n["nariz"])], olho, cab)
	_peca(img, PECAS_BOCA[int(n["boca"])], olho, cab)
	_peca(img, PECAS_OLHOS[int(n["olhos"])], olho, cab)
	var pele: Color = PELES[int(n["pele"])]
	for y: int in img.get_height():
		for x: int in img.get_width():
			img.set_pixel(x, y, trocar(img.get_pixel(x, y), pele, Color.TRANSPARENT))
	var cabeca: Image = img.duplicate()
	_cabelo(img, cabeca, int(n["cabelo"]), cab, com_chapeu)
	_barba(img, cabeca, int(n["barba"]), cab)
	_peca(img, PECAS_SOBRANCELHAS[int(n["sobrancelhas"])], olho, cab)
	return img


## A mesma troca do shader do corpo: pele (tons quentes) vira `pele` e roupa (cinzas) vira
## `roupa`, mantendo a luz de cada pixel. Roupa transparente = não troca roupa.
static func trocar(c: Color, pele: Color, roupa: Color) -> Color:
	if c.a < 0.5 or c.v < 0.12:
		return c
	if c.h >= 0.02 and c.h <= 0.11 and c.s >= 0.25 and c.v >= 0.25:
		return _tingir(c, pele, PELE_BASE)
	if roupa.a > 0.0 and c.s < 0.25:
		return _tingir(c, roupa, ROUPA_BASE)
	return c


static func _tingir(c: Color, alvo: Color, base: Color) -> Color:
	var k: float = c.get_luminance() / base.get_luminance()
	return Color(minf(alvo.r * k, 1.0), minf(alvo.g * k, 1.0), minf(alvo.b * k, 1.0), c.a)


static func _peca(img: Image, peca: Array, olho: Color, cab: Array) -> void:
	if peca.is_empty():
		return
	var canto: Array = peca[0]
	var linhas: Array = peca[1]
	for dy: int in linhas.size():
		var linha: String = linhas[dy]
		for dx: int in linha.length():
			var p := Vector2i(int(canto[0]) + dx, int(canto[1]) + dy)
			var ch: String = linha[dx]
			if ch == ".":
				continue
			img.set_pixelv(p, Color.TRANSPARENT if ch == "x" else _cor(ch, olho, cab))


static func _cor(ch: String, olho: Color, cab: Array) -> Color:
	match ch:
		"K":
			return CONTORNO
		"S":
			return PELE_BASE
		"D":
			return Color("a6765e")
		"E":
			return Color("986f5a")
		"M":
			return Color("ba8e73")
		"W":
			return BRANCO_OLHO
		"R":
			return Color("9d5f49")
		"P":
			return olho
		"H":
			return cab[0]
		"h":
			return cab[1]
		"G":
			return cab[2]
	return Color.MAGENTA


## Linha do cabelo: o cabelo cobre a cabeça acima dela, descendo da testa (x = 25) à nuca (x = 8).
static func _linha(x: int, testa: float, nuca: float) -> float:
	return lerpf(nuca, testa, clampf((x - 8) / 17.0, 0.0, 1.0))


## Pixels do cabelo de um estilo (Vector2i → true).
static func _area_cabelo(cabeca: Image, estilo: int) -> Dictionary:
	var area: Dictionary = {}
	for y: int in 32:
		for x: int in 32:
			var na_cabeca: bool = cabeca.get_pixel(x, y).a >= 0.5 or _vizinho(cabeca, x, y)
			var sim: bool = false
			match estilo:
				1:
					sim = na_cabeca and y <= _linha(x, 10.0, 16.0)
				2:
					# Crespo: volume oval em volta do alto da cabeça.
					var v := Vector2((x - 15.5) / 11.5, (y - 10.0) / 9.5)
					sim = (na_cabeca or v.length() <= 1.0) and y <= _linha(x, 11.0, 18.0)
				3:
					# Comprido: cai atrás da orelha até o ombro, afinando na ponta.
					var cortina: bool = y >= 10 and y <= 27 and x <= 11
					cortina = cortina and x >= 5 + (y - 10) / 6 + maxi(0, y - 24)
					sim = (na_cabeca and y <= _linha(x, 10.0, 16.0)) or cortina
				4:
					# Moicano: crista no meio do alto da cabeça.
					var meio: int = absi(x - 16)
					sim = meio <= 3 and y <= 12 and y >= 2 + meio and (na_cabeca or y <= 9)
			if sim:
				area[Vector2i(x, y)] = true
	return area


static func _cabelo(img: Image, cabeca: Image, estilo: int, cab: Array, com_chapeu: bool) -> void:
	if estilo == 0:
		return
	var area: Dictionary = _area_cabelo(cabeca, estilo)
	if com_chapeu:
		for p: Vector2i in area.keys():
			if p.y < 11:
				area.erase(p)
	for p: Vector2i in area:
		var topo: bool = not area.has(p + Vector2i.UP)
		var embaixo: bool = not area.has(p + Vector2i.DOWN) or not area.has(p + Vector2i.LEFT)
		var cor: Color = cab[0]
		match estilo:
			2:
				if (p.x * 3 + p.y * 5) % 9 == 0 and p.y <= 12:
					cor = cab[2]
				elif (p.x * 5 + p.y * 3) % 7 == 0 or embaixo:
					cor = cab[1]
			3:
				if p.x <= 11 and p.y >= 12 and p.x % 3 == 0:
					cor = cab[1]
				elif topo and p.x >= 12:
					cor = cab[2]
				elif embaixo:
					cor = cab[1]
			4:
				if absi(p.x - 16) == 3:
					cor = cab[1]
				elif p.x == 16 and p.y <= 6:
					cor = cab[2]
			_:
				if topo and p.x >= 12 and p.x <= 20:
					cor = cab[2]
				elif embaixo:
					cor = cab[1]
		img.set_pixelv(p, cor)
	# Contorno por fora do cabelo, onde não é cabeça.
	for p: Vector2i in area:
		for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var q: Vector2i = p + d
			if q.x < 0 or q.y < 0 or q.x >= 32 or q.y >= 32 or area.has(q):
				continue
			if cabeca.get_pixelv(q).a < 0.5:
				img.set_pixelv(q, CONTORNO)


static func _vizinho(img: Image, x: int, y: int) -> bool:
	for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var q := Vector2i(x, y) + d
		if q.x >= 0 and q.y >= 0 and q.x < 32 and q.y < 32 and img.get_pixelv(q).a >= 0.5:
			return true
	return false


static func _barba(img: Image, cabeca: Image, estilo: int, cab: Array) -> void:
	match estilo:
		1:
			for y: int in range(24, 29):
				for x: int in range(19, 26):
					if cabeca.get_pixel(x, y).a >= 0.5 and (x >= 20 or y >= 26):
						img.set_pixel(x, y, cab[0] if (x + y) % 3 != 0 else cab[1])
		2:
			for y: int in range(18, 29):
				for x: int in range(12, 26):
					# Abaixo da linha que vai da costeleta (orelha) ao canto da boca.
					var limite: float = lerpf(18.0, 23.0, (x - 12) / 13.0)
					var pele: bool = cabeca.get_pixel(x, y).a >= 0.5
					if pele and y >= limite and not (y == 23 and x >= 21 and x <= 23):
						var fio: bool = (x * 3 + y * 2) % 11 == 0 or y == 28
						img.set_pixel(x, y, cab[1] if fio else cab[0])
		3:
			_peca(img, PECAS_BIGODE, Color.BLACK, cab)
