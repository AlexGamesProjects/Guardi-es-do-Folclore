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
		if not _is_control(raw.unicode_at(i)):
			clean += raw[i]
	clean = clean.strip_edges()
	if clean.length() > max_len:
		clean = clean.substr(0, max_len).strip_edges()
	if clean.is_empty():
		return str(rules.balance.start["nome"])
	return clean


static func _is_control(code: int) -> bool:
	return code < 32 or (code >= 127 and code <= 159) or code == 0x2028 or code == 0x2029
