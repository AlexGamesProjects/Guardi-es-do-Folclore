extends SceneTree
## Monta as tiras de uma lenda a partir de quadros soltos: `<origem>/<acao>/0.png, 1.png...`
## viram `<destino>/<acao>.png` (quadros lado a lado, na ordem). Com `--espelhar`, vira cada
## quadro na horizontal (as lendas olham para a esquerda, para o guardião).
##
## Fica em tools/ (fora do jogo exportado). Uso, da raiz do repositório:
##   godot --headless -s tools/montar_tiras.gd -- "$PWD/arte/pixellab/boitata" \
##     "$PWD/game/assets/sprites/boitata" --espelhar

const ACOES: Array[String] = ["parado", "ataque", "golpe", "esquiva", "derrota"]


func _init() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	var origem: String = a[0]
	var destino: String = a[1]
	var espelhar: bool = a.has("--espelhar")
	DirAccess.make_dir_recursive_absolute(destino)
	for acao: String in ACOES:
		var quadros: Array[Image] = []
		while FileAccess.file_exists("%s/%s/%d.png" % [origem, acao, quadros.size()]):
			var q: Image = Image.load_from_file("%s/%s/%d.png" % [origem, acao, quadros.size()])
			q.convert(Image.FORMAT_RGBA8)
			if espelhar:
				q.flip_x()
			quadros.append(q)
		if quadros.is_empty():
			continue
		var lado: int = quadros[0].get_height()
		var tira: Image = Image.create(lado * quadros.size(), lado, false, Image.FORMAT_RGBA8)
		for i: int in quadros.size():
			tira.blit_rect(quadros[i], Rect2i(0, 0, lado, lado), Vector2i(i * lado, 0))
		tira.save_png("%s/%s.png" % [destino, acao])
		print("%s: %d quadros de %d px" % [acao, quadros.size(), lado])
	quit()
