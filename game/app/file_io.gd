class_name FileIO
extends RefCounted
## Acesso a arquivos do save. Fica numa classe à parte para os testes trocarem por uma que falha.


## Texto do arquivo; vazio se não existir ou não abrir.
func read(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	return f.get_as_text()


## Grava o texto inteiro. `false` se não abrir ou se a escrita falhar (disco ou cota cheios).
func write(path: String, text: String) -> bool:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	var stored: bool = f.store_string(text)
	var err: int = f.get_error()
	f.close()
	return stored and err == OK


## Troca de nome sobre arquivo existente: o destino só é removido se a origem existe.
func rename(from: String, to: String) -> bool:
	if not exists(from):
		return false
	if exists(to) and not remove(to):
		return false
	return DirAccess.rename_absolute(from, to) == OK


func exists(path: String) -> bool:
	return FileAccess.file_exists(path)


## Apaga o arquivo; `true` também quando ele já não existia.
func remove(path: String) -> bool:
	if not exists(path):
		return true
	return DirAccess.remove_absolute(path) == OK


## Nomes dos arquivos da pasta (vazio se a pasta não existir).
func list(dir: String) -> PackedStringArray:
	if not DirAccess.dir_exists_absolute(dir):
		return PackedStringArray()
	return DirAccess.get_files_at(dir)
