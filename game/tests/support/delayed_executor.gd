class_name DelayedExecutor
extends CommandExecutor
## Só para testes: espera um tempo antes de delegar, como faria um servidor remoto.

var _inner: CommandExecutor
var _delay_ms: int = 0


func _init(inner: CommandExecutor, delay_ms: int) -> void:
	_inner = inner
	_delay_ms = delay_ms


func execute(state: GameState, cmd: Command) -> CommandResult:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	await tree.create_timer(float(_delay_ms) / 1000.0).timeout
	return await _inner.execute(state, cmd)
