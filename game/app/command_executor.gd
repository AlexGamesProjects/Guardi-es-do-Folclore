class_name CommandExecutor
extends RefCounted
## Quem aplica um comando a um estado. Sempre usado com `await`, para que o executor local e um
## futuro executor remoto (modo online) sejam intercambiáveis.


func execute(state: GameState, _cmd: Command) -> CommandResult:
	return CommandResult.fail(state, "COMANDO_DESCONHECIDO")
