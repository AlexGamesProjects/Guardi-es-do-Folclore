class_name NameRules
extends RefCounted
## Saneamento do nome do guardião. Emoji é permitido; controles e quebras de linha somem.

## Quanto do texto bruto é olhado (basta para achar `nome_max` caracteres úteis).
const _SCAN_LIMIT: int = 4096


static func sanitize(raw: String, rules: RulesPack) -> String:
	var max_len: int = int(rules.balance.start["nome_max"])
	var clean: String = ""
	var scan: int = mini(raw.length(), _SCAN_LIMIT)
	for i: int in scan:
		if not _is_invisible(raw.unicode_at(i)):
			clean += raw[i]
	clean = _trim(clean)
	if clean.length() > max_len:
		clean = _trim(clean.substr(0, max_len))
	if clean.is_empty():
		return str(rules.balance.start["nome"])
	return clean


## Controles e caracteres de formatação (categoria Cf): somem do nome em qualquer posição.
static func _is_invisible(code: int) -> bool:
	return (
		code < 32
		or (code >= 127 and code <= 159)
		or code == 0xAD
		or (code >= 0x200B and code <= 0x200F)
		or (code >= 0x2028 and code <= 0x202E)
		or (code >= 0x2060 and code <= 0x206F)
		or code == 0xFEFF
		or (code >= 0xFFF9 and code <= 0xFFFB)
	)


## Espaços Unicode (Zs) também saem das pontas, além dos espaços comuns.
static func _is_space(code: int) -> bool:
	return (
		code == 32
		or code == 0xA0
		or code == 0x1680
		or (code >= 0x2000 and code <= 0x200A)
		or code == 0x202F
		or code == 0x205F
		or code == 0x3000
	)


static func _trim(text: String) -> String:
	var a: int = 0
	var b: int = text.length()
	while a < b and _is_space(text.unicode_at(a)):
		a += 1
	while b > a and _is_space(text.unicode_at(b - 1)):
		b -= 1
	return text.substr(a, b - a)
