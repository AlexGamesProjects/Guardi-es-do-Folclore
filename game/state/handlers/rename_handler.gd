class_name RenameHandler
extends RefCounted
## `renomear`: nunca falha; o nome é saneado (ver NameRules).


static func run(c: HandlerCtx) -> String:
	c.s.nome = NameRules.sanitize(c.arg_str("nome"), c.rules)
	return ""
