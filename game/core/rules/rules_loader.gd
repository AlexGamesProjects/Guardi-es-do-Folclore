class_name RulesLoader
extends RefCounted
## Lê um diretório de pacote de regras (JSON), valida tudo e devolve o pacote tipado.

const FILES: PackedStringArray = [
	"manifest.json",
	"legends.json",
	"acts.json",
	"balance.json",
	"items.json",
	"rivals.json",
]


static func load_dir(path: String) -> RulesLoadResult:
	var result := RulesLoadResult.new()
	var files: Dictionary = {}
	for file_name: String in FILES:
		var full: String = "%s/%s" % [path.trim_suffix("/"), file_name]
		if not FileAccess.file_exists(full):
			result.errors.append("%s: arquivo não encontrado (%s)" % [file_name, full])
			continue
		var json := JSON.new()
		var parse_error: int = json.parse(FileAccess.get_file_as_string(full))
		if parse_error != OK:
			result.errors.append(
				(
					"%s: JSON inválido na linha %d: %s"
					% [file_name, json.get_error_line(), json.get_error_message()]
				)
			)
			continue
		files[file_name] = json.data
	result.errors.append_array(RulesValidator.validate(files))
	if result.errors.is_empty():
		result.pack = RulesPack.from_files(files)
		result.ok = true
	return result
