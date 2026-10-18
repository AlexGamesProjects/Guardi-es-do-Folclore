class_name CartaLib
extends RefCounted
## Pinturas das lendas (cartas), em `res://assets/cartas/<id>.webp`. Sem carta, devolve null.

const CAMINHO: String = "res://assets/cartas/%s.webp"


static func textura(lenda_id: String) -> Texture2D:
	if lenda_id == "":
		return null
	var caminho: String = CAMINHO % lenda_id
	if not ResourceLoader.exists(caminho):
		return null
	return load(caminho) as Texture2D
