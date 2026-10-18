class_name Clock
extends RefCounted
## Fonte do instante atual, em milissegundos. O núcleo nunca a lê: o GameService a consulta e
## entrega o instante pronto no comando.


func now_ms() -> int:
	return 0
