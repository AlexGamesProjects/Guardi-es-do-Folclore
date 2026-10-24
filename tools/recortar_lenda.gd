extends SceneTree
## Recorta o quadro parado de uma lenda em partes para o esqueleto único (#32).
## Uso: godot --headless --path game --script ../tools/recortar_lenda.gd -- <id>
## Lê `res://assets/esqueleto/<id>/rig.json` e grava `<osso>.png` e `montagem.json` na mesma pasta.
## Cada pixel opaco vai para a primeira parte (na ordem do rig) cujo polígono o contém.
## `preencher` é um polígono onde a parte recebe também os pixels das partes da frente, pintados
## com a cor da própria parte mais próxima, para não abrir buraco quando a parte da frente gira.


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("informe o id da lenda")
		quit(1)
		return
	var pasta: String = "res://assets/esqueleto/%s" % args[0]
	var rig: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(pasta + "/rig.json"))
	var tira: Image = Image.load_from_file(str(rig["fonte"]))
	var lado: int = tira.get_height()
	var quadro: Image = tira.get_region(Rect2i(int(rig["quadro"]) * lado, 0, lado, lado))
	quadro.convert(Image.FORMAT_RGBA8)
	var partes: Array = rig["partes"]
	var dono: Array[int] = []
	dono.resize(lado * lado)
	dono.fill(-1)
	for y: int in lado:
		for x: int in lado:
			if quadro.get_pixel(x, y).a == 0.0:
				continue
			for i: int in partes.size():
				if _dentro(partes[i]["poligono"], x, y):
					dono[y * lado + x] = i
					break
	var montagem: Array = []
	for i: int in partes.size():
		var p: Dictionary = partes[i]
		var img: Image = Image.create(lado, lado, false, Image.FORMAT_RGBA8)
		for y: int in lado:
			for x: int in lado:
				if dono[y * lado + x] == i:
					img.set_pixel(x, y, quadro.get_pixel(x, y))
		if p.has("preencher"):
			_preencher(img, dono, i, p["preencher"])
		var uso: Rect2i = img.get_used_rect()
		img.get_region(uso).save_png(
			ProjectSettings.globalize_path("%s/%s.png" % [pasta, p["osso"]])
		)
		montagem.append(
			{
				"osso": p["osso"],
				"pai": p["pai"],
				"pivo": p["pivo"],
				"z": p["z"],
				"canto": [uso.position.x, uso.position.y],
			}
		)
	var saida := {"lado": lado, "pes": rig["pes"], "partes": montagem}
	var f: FileAccess = FileAccess.open(pasta + "/montagem.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(saida, "\t") + "\n")
	f.close()
	print("recortado: %s (%d partes)" % [args[0], partes.size()])
	quit()


func _dentro(poligono: Array, x: int, y: int) -> bool:
	var pts := PackedVector2Array()
	for p: Array in poligono:
		pts.append(Vector2(float(p[0]), float(p[1])))
	return Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), pts)


## Pinta os pixels opacos de outras partes dentro de `poligono` com a cor mais próxima da parte.
func _preencher(img: Image, dono: Array[int], i: int, poligono: Array) -> void:
	var lado: int = img.get_width()
	var faltam: Array[Vector2i] = []
	for y: int in lado:
		for x: int in lado:
			var d: int = dono[y * lado + x]
			if d != -1 and d != i and _dentro(poligono, x, y):
				faltam.append(Vector2i(x, y))
	while not faltam.is_empty():
		var resto: Array[Vector2i] = []
		var pintar: Dictionary[Vector2i, Color] = {}
		for p: Vector2i in faltam:
			# O vizinho mais claro, para o contorno escuro não se espalhar pelo preenchimento.
			var cor: Color = Color(0, 0, 0, 0)
			for v: Vector2i in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
				var q: Vector2i = p + v
				if q.x < 0 or q.y < 0 or q.x >= lado or q.y >= lado:
					continue
				var c: Color = img.get_pixelv(q)
				if c.a > 0.0 and (cor.a == 0.0 or c.get_luminance() > cor.get_luminance()):
					cor = c
			if cor.a > 0.0:
				pintar[p] = cor
			else:
				resto.append(p)
		if pintar.is_empty():
			break
		for p: Vector2i in pintar:
			img.set_pixelv(p, pintar[p])
		faltam = resto
	if not faltam.is_empty():
		push_warning("%d pixels sem cor vizinha" % faltam.size())
