extends SceneTree
## Prepara o guardião em camadas a partir das tiras do PixelLab (arte/pixellab/guardiao/):
## - cabeca.png: a cabeça do 1º quadro de "parado", com olho, sobrancelha e boca apagados (pele
##   lisa), para o rosto ser montado em blocos por cima;
## - <acao>.png: as tiras sem a cabeça (o corpo, lido pelo SpriteLib como id "guardiao");
## - pontos.json: por ação e quadro, [x, y, giro] do pescoço (onde a cabeça encaixa) e [x, y] da
##   mão da frente (onde vai a arma), em pixels do quadro.
## A cabeça de cada quadro é achada encaixando o molde (com giro) no desenho.
##
## Fica em tools/ (fora do jogo exportado); não é coberto por gdformat, gdlint nem
## tools/check_scripts.sh. Uso, da raiz do repositório:
##   godot --headless -s tools/preparar_guardiao.gd -- "$PWD/arte/pixellab/guardiao" \
##     "$PWD/game/assets/sprites/guardiao"

const ACOES: Array[String] = ["parado", "ataque", "golpe", "esquiva", "derrota"]
## Pescoço no 1º quadro de "parado": a cabeça gira em torno dele.
const PESCOCO: Vector2i = Vector2i(47, 40)
## A cabeça são os pixels até esta linha no 1º quadro (o ombro começa na 41).
const ULTIMA_LINHA: int = 40
## Pixels do rosto apagados no molde (viram pele lisa): sobrancelha, olho e boca.
const APAGAR: Array[Rect2i] = [
	Rect2i(51, 28, 5, 1), Rect2i(50, 29, 5, 4), Rect2i(53, 35, 2, 1),
]
const PELE_LISA: Color = Color("c59c7d")
## Busca: deslocamento (px) e giro (graus) em torno do quadro anterior.
const RAIO: int = 10
const GIRO_MAX: int = 35
const PASSO_GIRO: int = 5

var _molde: Array[Vector2i] = []
var _cores: Array[Color] = []


func _init() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	var origem: String = a[0]
	var destino: String = a[1]
	DirAccess.make_dir_recursive_absolute(destino)
	var parado: Image = _abrir("%s/parado.png" % origem)
	_montar_molde(parado)
	_salvar_cabeca(parado, destino)
	var pontos: Dictionary = {}
	for acao: String in ACOES:
		var tira: Image = _abrir("%s/%s.png" % [origem, acao])
		var lado: int = tira.get_height()
		var n: int = tira.get_width() / lado
		var lista: Array = []
		var atual := Vector3(PESCOCO.x, PESCOCO.y, 0)
		for i: int in n:
			var q: Image = tira.get_region(Rect2i(i * lado, 0, lado, lado))
			atual = _achar(q, atual, i == 0)
			_apagar_cabeca(q, atual)
			var mao: Vector2i = _mao(q, Vector2(atual.x, atual.y))
			tira.blit_rect(q, Rect2i(0, 0, lado, lado), Vector2i(i * lado, 0))
			lista.append([int(atual.x), int(atual.y), int(atual.z), mao.x, mao.y])
		_completar_maos(lista)
		for i: int in lista.size():
			var p: Array = lista[i]
			print("%s %d: pescoço (%d, %d) giro %d, mão (%d, %d)" % [acao, i, p[0], p[1], p[2], p[3], p[4]])
		tira.save_png("%s/%s.png" % [destino, acao])
		pontos[acao] = lista
	var f: FileAccess = FileAccess.open("%s/pontos.json" % destino, FileAccess.WRITE)
	f.store_string(JSON.stringify(pontos, "\t") + "\n")
	quit()


func _abrir(caminho: String) -> Image:
	var img: Image = Image.load_from_file(caminho)
	img.convert(Image.FORMAT_RGBA8)
	return img


func _montar_molde(parado: Image) -> void:
	var lado: int = parado.get_height()
	for y: int in ULTIMA_LINHA + 1:
		for x: int in lado:
			var c: Color = parado.get_pixel(x, y)
			if c.a >= 0.5:
				_molde.append(Vector2i(x, y) - PESCOCO)
				_cores.append(c)


## Molde em 32×32 com o pescoço em (16, 28), rosto liso.
func _salvar_cabeca(parado: Image, destino: String) -> void:
	var img: Image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for i: int in _molde.size():
		var p: Vector2i = _molde[i] + PESCOCO
		var c: Color = _cores[i]
		for r: Rect2i in APAGAR:
			if r.has_point(p):
				c = PELE_LISA
		img.set_pixelv(_molde[i] + Vector2i(16, 28), c)
	img.save_png("%s/cabeca.png" % destino)


## Melhor encaixe (x, y, giro) do molde no quadro, perto do anterior.
func _achar(q: Image, antes: Vector3, primeiro: bool) -> Vector3:
	var melhor := Vector3(antes)
	var nota: float = -INF
	var raio: int = RAIO if not primeiro else 6
	var giros: Array[int] = []
	var g0: int = 0 if primeiro else int(antes.z)
	for g: int in range(-GIRO_MAX, GIRO_MAX + 1, PASSO_GIRO):
		if absi(g0 + g) <= 100:
			giros.append(g0 + g)
	for g: int in giros:
		var rot: Array[Vector2i] = _girar(g)
		for dy: int in range(-raio, raio + 1):
			for dx: int in range(-raio, raio + 1):
				var base := Vector2i(int(antes.x) + dx, int(antes.y) + dy)
				var s: float = _nota(q, rot, base)
				# Empate: fica com o menor giro e o menor deslocamento.
				s -= absf(g) * 0.01 + (absi(dx) + absi(dy)) * 0.01
				if s > nota:
					nota = s
					melhor = Vector3(base.x, base.y, g)
	return melhor


func _girar(graus: int) -> Array[Vector2i]:
	var t: float = deg_to_rad(graus)
	var out: Array[Vector2i] = []
	for d: Vector2i in _molde:
		var v: Vector2 = Vector2(d).rotated(t)
		out.append(Vector2i(roundi(v.x), roundi(v.y)))
	return out


func _nota(q: Image, rot: Array[Vector2i], base: Vector2i) -> float:
	var s: float = 0.0
	var w: int = q.get_width()
	var h: int = q.get_height()
	for i: int in rot.size():
		var p: Vector2i = rot[i] + base
		if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h:
			s -= 1.0
			continue
		var c: Color = q.get_pixelv(p)
		if c.a < 0.5:
			s -= 1.0
		elif _perto(c, _cores[i]):
			s += 1.0
	return s


static func _perto(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) < 0.18


## Apaga do quadro os pixels cobertos pela cabeça encaixada, com folga de 2 px (3 px no contorno
## escuro), porque a cabeça desenhada em cada quadro varia um pouco. Abaixo do pescoço nada sai.
func _apagar_cabeca(q: Image, pos: Vector3) -> void:
	var t: float = deg_to_rad(pos.z)
	var centro := Vector2(pos.x, pos.y)
	var cobre: Dictionary = {}
	for d: Vector2i in _molde:
		cobre[d] = true
	for y: int in q.get_height():
		for x: int in q.get_width():
			if q.get_pixel(x, y).a < 0.5:
				continue
			var v: Vector2 = (Vector2(x, y) - centro).rotated(-t)
			var d := Vector2i(roundi(v.x), roundi(v.y))
			if d.y > -1:
				continue
			var folga: int = 3 if q.get_pixel(x, y).v < 0.15 else 2
			var apaga: bool = false
			for oy: int in range(-folga, folga + 1):
				for ox: int in range(-folga, folga + 1):
					if cobre.has(d + Vector2i(ox, oy)):
						apaga = true
			if apaga:
				q.set_pixel(x, y, Color(0, 0, 0, 0))


## Mão da frente: o grupo de pele (fora da cabeça, na altura do tronco: até 22 px abaixo do
## pescoço, para não pegar os pés descalços, e longe do toco do pescoço) que mais avança para a
## direita; devolve o meio da ponta dele. Sem nenhum (braço escondido), devolve (-1, -1).
func _mao(q: Image, pescoco: Vector2) -> Vector2i:
	var w: int = q.get_width()
	var h: int = q.get_height()
	var chao: int = q.get_used_rect().end.y
	var visto: Dictionary = {}
	var melhor := Vector2i(-1, -1)
	var melhor_x: int = -1
	for y: int in h:
		for x: int in w:
			var p := Vector2i(x, y)
			if visto.has(p) or not _pele(q.get_pixelv(p)):
				continue
			var grupo: Array[Vector2i] = []
			var fila: Array[Vector2i] = [p]
			visto[p] = true
			while not fila.is_empty():
				var c: Vector2i = fila.pop_back()
				grupo.append(c)
				for oy: int in [-1, 0, 1]:
					for ox: int in [-1, 0, 1]:
						var n := c + Vector2i(ox, oy)
						if n.x < 0 or n.y < 0 or n.x >= w or n.y >= h or visto.has(n):
							continue
						if _pele(q.get_pixelv(n)):
							visto[n] = true
							fila.append(n)
			var fundo: int = 0
			var frente: int = 0
			var meio_y: float = 0.0
			for c: Vector2i in grupo:
				fundo = maxi(fundo, c.y)
				frente = maxi(frente, c.x)
				meio_y += c.y
			meio_y /= grupo.size()
			if grupo.size() < 4 or fundo >= chao - 5 or meio_y > pescoco.y + 22:
				continue
			var ponta: Vector2i = _ponta(grupo, frente)
			if Vector2(ponta).distance_to(pescoco) < 6.0:
				continue
			if frente > melhor_x:
				melhor_x = frente
				melhor = ponta
	return melhor if melhor_x >= 0 else Vector2i(-1, -1)


## Meio dos pixels do grupo a até 3 px da frente.
static func _ponta(grupo: Array[Vector2i], frente: int) -> Vector2i:
	var soma := Vector2i.ZERO
	var n: int = 0
	for c: Vector2i in grupo:
		if c.x >= frente - 3:
			soma += c
			n += 1
	return soma / n


## Quadro sem mão visível copia a do quadro mais perto da mesma ação.
static func _completar_maos(lista: Array) -> void:
	var achados: Array[int] = []
	for i: int in lista.size():
		if int(lista[i][3]) >= 0:
			achados.append(i)
	if achados.is_empty():
		return
	for i: int in lista.size():
		if int(lista[i][3]) >= 0:
			continue
		var perto: int = achados[0]
		for j: int in achados:
			if absi(j - i) < absi(perto - i):
				perto = j
		lista[i][3] = lista[perto][3]
		lista[i][4] = lista[perto][4]


static func _pele(c: Color) -> bool:
	return c.a >= 0.5 and c.h >= 0.02 and c.h <= 0.11 and c.s >= 0.25 and c.v >= 0.25
