extends Node
## Autoload `Boot`: valida o pacote de regras, carrega (ou cria) o perfil offline, configura o
## `GameService` e abre o menu. Com regras inválidas o jogo não inicia: abre a tela de erro.

const PROFILE_ID: String = "solo"
const MODE: String = "offline"
const DEFAULT_NAME: String = "Jaci"
const MENU_SCENE: String = "res://ui/menu.tscn"
const ERROR_SCENE: String = "res://ui/erro_regras.tscn"
const SEED_MASK: int = 0x7FFFFFFF

## Quem abre as telas: `(scene_path: String, errors: PackedStringArray)`. Vazio = troca a cena real.
## Os testes trocam por um Callable que só registra a chamada.
var opener: Callable = Callable()
## Avisos do carregamento do perfil (`RESERVA_USADA`, `SAVE_RECRIADO` ou vazio).
var last_warning: String = ""
## Avisos coletados no `start`, para o menu ler (`SAVE_RECRIADO`, `SAVE_FALHOU`).
## Um sinal emitido aqui não chegaria ao menu, que ainda não existe.
var warnings: Array[String] = []

var _started: bool = false
var _result: bool = false


func start(
	pack_dir: String = "res://data/packs/base",
	save_root: String = "user://profiles",
	io: FileIO = null
) -> bool:
	# Segunda chamada: devolve o resultado da primeira, sem recarregar nem reconfigurar nada.
	if _started:
		return _result
	_started = true
	_result = _start(pack_dir, save_root, io)
	return _result


func _start(pack_dir: String, save_root: String, io: FileIO) -> bool:
	var loaded: RulesLoadResult = RulesLoader.load_dir(pack_dir)
	if not loaded.ok:
		_open(ERROR_SCENE, loaded.errors)
		return false
	var rules: RulesPack = loaded.pack
	var clock: Clock = SystemClock.new()
	var file_io: FileIO = io if io != null else FileIO.new()
	var saves := SaveService.new(file_io, save_root)
	# O `SaveService` devolve SAVE_RECRIADO também para o primeiro perfil (nada no disco).
	# Só é aviso de verdade se havia alguma cópia, ou seja, se elas estavam corrompidas.
	var had_files: bool = false
	for ext: String in ["json", "bak1", "bak2"]:
		had_files = had_files or file_io.exists("%s/%s.%s" % [save_root, PROFILE_ID, ext])
	var fresh: Callable = func() -> GameState:
		return GameState.new_game(
			PROFILE_ID, MODE, DEFAULT_NAME, _random_seed(), clock.now_ms(), rules
		)
	var res: Dictionary = saves.load(PROFILE_ID, MODE, fresh)
	var state: GameState = res["state"]
	last_warning = str(res["warning"])
	# Perfil novo (ou recriado): grava já, para ele aparecer em `list_profiles`.
	if last_warning == "SAVE_RECRIADO":
		if had_files:
			warnings.append("SAVE_RECRIADO")
		if not saves.save(state, rules.rules_version, rules.schema_version):
			warnings.append("SAVE_FALHOU")
	_game_service().setup(rules, LocalExecutor.new(rules), clock, state, saves)
	_open(MENU_SCENE, PackedStringArray())
	return true


## Pelo caminho do nó, não pelo nome global: assim o script passa no `--check-only` isolado.
func _game_service() -> Node:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	return tree.root.get_node("GameService")


func _random_seed() -> int:
	var bytes: PackedByteArray = Crypto.new().generate_random_bytes(4)
	return int(bytes.decode_u32(0)) & SEED_MASK


func _open(scene_path: String, errors: PackedStringArray) -> void:
	if opener.is_valid():
		opener.call(scene_path, errors)
		return
	var packed: PackedScene = load(scene_path) as PackedScene
	var screen: Node = packed.instantiate()
	if not errors.is_empty():
		screen.set("errors", errors)
	var tree: SceneTree = get_tree()
	var old: Node = tree.current_scene
	tree.root.add_child(screen)
	tree.current_scene = screen
	if old != null:
		old.queue_free()
