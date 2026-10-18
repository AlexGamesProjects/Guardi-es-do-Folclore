class_name CreateHandler
extends RefCounted
## `criar_guardiao {nome, origem}`: só uma vez (origem vazia). Grava o nome saneado, a origem e
## soma o bônus da origem aos atributos base. Erros: JA_CRIADO, ORIGEM_INVALIDA.


static func run(c: HandlerCtx) -> String:
	if c.s.origem != "":
		return "JA_CRIADO"
	var origem: String = c.arg_str("origem")
	var origens: Dictionary = c.rules.balance.origens
	if not origens.has(origem):
		return "ORIGEM_INVALIDA"
	var info: Dictionary = origens[origem]
	c.s.nome = NameRules.sanitize(c.arg_str("nome"), c.rules)
	c.s.origem = origem
	for k: String in Defs.STAT_KEYS:
		if info.has(k):
			c.s.stats[k] += int(info[k])
	return ""
