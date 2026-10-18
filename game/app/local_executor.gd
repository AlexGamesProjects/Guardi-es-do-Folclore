class_name LocalExecutor
extends CommandExecutor
## Aplica o comando no próprio aparelho, depois de ceder um quadro (mesmo ritmo de um remoto).

var _rules: RulesPack


func _init(rules: RulesPack) -> void:
	_rules = rules


func execute(state: GameState, cmd: Command) -> CommandResult:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	await tree.process_frame
	return CommandRouter.apply(state, cmd, _rules)
