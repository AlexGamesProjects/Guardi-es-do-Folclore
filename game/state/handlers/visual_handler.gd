class_name VisualHandler
extends RefCounted
## `mudar_visual {visual}`: nunca falha; o visual é saneado (ver VisualRules) e de graça.


static func run(c: HandlerCtx) -> String:
	c.s.visual = VisualRules.sanitize(c.p.get("visual"))
	return ""
