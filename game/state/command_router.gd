class_name CommandRouter
extends RefCounted
## Aplica um comando a um estado, sem alterá-lo: trabalha num clone e devolve o resultado.
##
## Códigos de erro: NAO_ENCONTRADO, MISSAO_ATIVA, ENERGIA_INSUFICIENTE, SEM_MISSAO,
## MISSAO_EM_ANDAMENTO, MUIRAQUITAS_INSUFICIENTES, ATRIBUTO_INVALIDO, VINTENS_INSUFICIENTES,
## FASE_BLOQUEADA, NIVEL_INSUFICIENTE, EM_RECUPERACAO, MOCHILA_CHEIA, CORAGEM_INSUFICIENTE e
## COMANDO_DESCONHECIDO. O `cmd_counter` fica para o GameService.
##
## Catálogo de eventos (cada um é {"type": ..., ...}):
## - missao_concluida {mission_id, c, luta, win}, xp_ganho {amount}, subiu_nivel {lvl},
##   item_ganho {item_id, nome, rar, destino: mochila|equipado},
##   vintens_ganhos {amount, origem: missao|fase|arena|venda|item_vendido},
##   fase_vencida {act, n, boss}, ato_concluido {act}, honra_alterada {delta, honra}.
## - Extras (R21): luta {contexto: missao|fase|arena, heroi {nome, lvl, hp},
##   inimigo {nome, lvl, hp, legend_id}}, seguido dos eventos do combate (golpe, critico,
##   esquiva, fim; atacante 0 = herói), e muiraquitas_ganhas {amount, origem: nivel|chefe}.

static var _table: Dictionary = {}


static func _handlers() -> Dictionary:
	if _table.is_empty():
		_table = {
			"iniciar_missao": MissionStartHandler.run,
			"concluir_missao": MissionFinishHandler.run,
			"acelerar_missao": MissionBoostHandler.speed_up,
			"renovar_missoes": MissionBoostHandler.renew,
			"treinar": TrainHandler.run,
			"enfrentar_fase": StageHandler.run,
			"comprar": ShopHandler.buy,
			"renovar_feira": ShopHandler.renew,
			"equipar": BagHandler.equip,
			"desequipar": BagHandler.unequip,
			"vender": BagHandler.sell,
			"desafiar": DuelHandler.run,
			"renomear": RenameHandler.run,
			"criar_guardiao": CreateHandler.run,
		}
	return _table


static func apply(state: GameState, cmd: Command, rules: RulesPack) -> CommandResult:
	var handlers: Dictionary = _handlers()
	if not handlers.has(cmd.type):
		return CommandResult.fail(state, "COMANDO_DESCONHECIDO")
	var s: GameState = state.clone()
	_regen(s, cmd.now_ms, rules)
	var rng := Rng.new(cmd.seed)
	Refill.ensure(s, cmd.now_ms, rng, rules)
	var ctx := HandlerCtx.new(s, cmd.params, rng, cmd.now_ms, rules)
	var handler: Callable = handlers[cmd.type]
	var error: String = str(handler.call(ctx))
	if not error.is_empty():
		return CommandResult.fail(state, error)
	Refill.ensure(s, cmd.now_ms, rng, rules)
	return CommandResult.success(s, ctx.events)


static func _regen(s: GameState, now_ms: int, rules: RulesPack) -> void:
	var b: Defs.BalanceDef = rules.balance
	var en: Dictionary = Stamina.regen(s.energia, s.en_upd_ms, now_ms, b.en_max, b.en_ms)
	s.energia = en["cur"]
	s.en_upd_ms = en["upd_ms"]
	var co: Dictionary = Stamina.regen(s.coragem, s.co_upd_ms, now_ms, b.co_max, b.co_ms)
	s.coragem = co["cur"]
	s.co_upd_ms = co["upd_ms"]
