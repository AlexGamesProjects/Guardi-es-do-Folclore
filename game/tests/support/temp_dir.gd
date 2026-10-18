class_name TempDir
extends RefCounted
## Raiz temporária única por teste, em `user://`, apagada no fim.

static var _counter: int = 0


static func make() -> String:
	_counter += 1
	return "user://test_profiles_%d_%d" % [Time.get_ticks_usec(), _counter]


static func remove(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	for f: String in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(f))
	DirAccess.remove_absolute(path)
