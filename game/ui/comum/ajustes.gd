class_name Ajustes
extends RefCounted
## Preferências deste aparelho (fora do save): velocidade da luta.

const ARQUIVO: String = "user://ajustes.cfg"
const VELOCIDADES: Array[int] = [1, 2]


static func velocidade() -> int:
	var cfg := ConfigFile.new()
	if cfg.load(ARQUIVO) != OK:
		return 1
	var v: int = int(cfg.get_value("luta", "velocidade", 1))
	return v if VELOCIDADES.has(v) else 1


static func definir_velocidade(v: int) -> void:
	var cfg := ConfigFile.new()
	cfg.load(ARQUIVO)
	cfg.set_value("luta", "velocidade", v if VELOCIDADES.has(v) else 1)
	cfg.save(ARQUIVO)
