class_name SpriteLib
extends RefCounted
## Sprites em pixel art das lendas e do herói: tiras horizontais de quadros quadrados em
## `<raiz>/<id>/<acao>.png` (acao: parado, ataque, golpe, esquiva, derrota). Sem nenhuma tira,
## devolve null e o Lutador usa o retrato.

const RAIZ_PADRAO: String = "res://assets/sprites"
const ACOES: Array[String] = ["parado", "ataque", "golpe", "esquiva", "derrota"]
const FPS: float = 10.0

## Pasta onde procurar (os testes trocam).
static var raiz: String = RAIZ_PADRAO
static var _cache: Dictionary[String, SpriteFrames] = {}


static func frames(id: String) -> SpriteFrames:
	if id == "":
		return null
	var chave: String = raiz + "/" + id
	if _cache.has(chave):
		return _cache[chave]
	var sf := SpriteFrames.new()
	sf.remove_animation(&"default")
	var achou: bool = false
	for acao: String in ACOES:
		var tex: Texture2D = _textura("%s/%s.png" % [chave, acao])
		if tex == null:
			continue
		achou = true
		var lado: int = tex.get_height()
		sf.add_animation(acao)
		sf.set_animation_loop(acao, acao == "parado")
		sf.set_animation_speed(acao, FPS)
		for i: int in maxi(1, tex.get_width() / lado):
			var quadro := AtlasTexture.new()
			quadro.atlas = tex
			quadro.region = Rect2(i * lado, 0, lado, lado)
			sf.add_frame(acao, quadro)
	var out: SpriteFrames = sf if achou else null
	_cache[chave] = out
	return out


## Linha logo abaixo dos pés num quadro (o fundo dos pixels opacos), para pôr a lenda no chão:
## cada tira tem uma folga diferente embaixo. Padrão: primeiro quadro de "parado"; `quadro` -1 é
## o último. Sem sprite, devolve -1.
static func pes(id: String, acao: String = "parado", quadro: int = 0) -> int:
	var sf: SpriteFrames = frames(id)
	if sf == null:
		return -1
	var nome: StringName = StringName(acao)
	if not sf.has_animation(nome):
		nome = &"parado" if sf.has_animation(&"parado") else sf.get_animation_names()[0]
	var n: int = sf.get_frame_count(nome)
	var i: int = clampi(quadro if quadro >= 0 else n - 1, 0, n - 1)
	var tex: Texture2D = sf.get_frame_texture(nome, i)
	var img: Image = tex.get_image()
	if img == null:
		return tex.get_height()
	var uso: Rect2i = img.get_used_rect()
	return uso.end.y if uso.size.y > 0 else tex.get_height()


## Até onde o desenho vai à frente do centro do quadro, em pixels do quadro, no quadro que mais
## avança da ação (o punho esticado no ataque). `frente` 1 olha para a direita, -1 para a
## esquerda. Sem sprite ou sem a ação, devolve -1.
static func alcance(id: String, acao: String, frente: int) -> int:
	return _ponta(id, acao, frente).x


## Índice do quadro que mais avança da ação (o do punho esticado); -1 sem sprite ou sem a ação.
static func pico(id: String, acao: String, frente: int) -> int:
	return _ponta(id, acao, frente).y


## (alcance, quadro) do quadro que mais avança à frente do centro.
static func _ponta(id: String, acao: String, frente: int) -> Vector2i:
	var sf: SpriteFrames = frames(id)
	var nome: StringName = StringName(acao)
	if sf == null or not sf.has_animation(nome):
		return Vector2i(-1, -1)
	var melhor := Vector2i(-1, -1)
	for i: int in sf.get_frame_count(nome):
		var img: Image = sf.get_frame_texture(nome, i).get_image()
		if img == null:
			continue
		var uso: Rect2i = img.get_used_rect()
		if uso.size.x == 0:
			continue
		var meio: int = img.get_width() / 2
		var vai: int = uso.end.x - meio if frente > 0 else meio - uso.position.x
		if vai > melhor.x:
			melhor = Vector2i(vai, i)
	return melhor


static func limpar_cache() -> void:
	_cache.clear()


static func _textura(caminho: String) -> Texture2D:
	if caminho.begins_with("res://"):
		return load(caminho) as Texture2D if ResourceLoader.exists(caminho) else null
	if not FileAccess.file_exists(caminho):
		return null
	var img: Image = Image.load_from_file(caminho)
	return null if img == null else ImageTexture.create_from_image(img)
