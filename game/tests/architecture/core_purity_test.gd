extends GdUnitTestSuite

const CORE_DIR: String = "res://core"

const RULES: Array[Dictionary] = [
	{"name": "extends Node", "pattern": "\\bextends\\s+Node\\b"},
	{"name": "get_tree", "pattern": "\\bget_tree\\b"},
	{"name": "Time.", "pattern": "(?<![\\w.])Time\\."},
	{"name": "OS.get_ticks", "pattern": "\\bOS\\.get_ticks"},
	{"name": "float", "pattern": "\\bfloat\\b"},
	{
		"name": "sorteio global",
		"pattern": "(?<![\\w.])(randi|randf|randomize|randi_range|randf_range)\\("
	},
]


# Devolve uma lista de "rótulo:linha: regra" para cada violação encontrada no texto.
func _find_violations(label: String, text: String) -> Array[String]:
	var found: Array[String] = []
	var lines: PackedStringArray = text.split("\n")
	for rule: Dictionary in RULES:
		var re := RegEx.new()
		re.compile(String(rule["pattern"]))
		for i: int in lines.size():
			if re.search(lines[i]) != null:
				found.append("%s:%d: %s" % [label, i + 1, String(rule["name"])])
	return found


func _collect_scripts(dir_path: String) -> Array[String]:
	var files: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return files
	for sub: String in dir.get_directories():
		files.append_array(_collect_scripts(dir_path.path_join(sub)))
	for f: String in dir.get_files():
		if f.ends_with(".gd"):
			files.append(dir_path.path_join(f))
	return files


func test_core_has_no_forbidden_constructs() -> void:
	var scripts: Array[String] = _collect_scripts(CORE_DIR)
	assert_bool(scripts.is_empty()).is_false()
	var all_violations: Array[String] = []
	for path: String in scripts:
		var text: String = FileAccess.get_file_as_string(path)
		all_violations.append_array(_find_violations(path, text))
	assert_array(all_violations).is_empty()


func test_detector_catches_violation() -> void:
	var sample: String = (
		"extends Node\n"
		+ "var x: float = 1.0\n"
		+ "func f() -> void:\n"
		+ "\tget_tree()\n"
		+ "\tvar t = Time.get_ticks_msec()\n"
		+ "\tvar o = OS.get_ticks_msec()\n"
		+ "\tvar r = randi()\n"
		+ "\tvar r2 = randi_range(1, 2)\n"
	)
	var found: Array[String] = _find_violations("amostra", sample)
	assert_int(found.size()).is_equal(7)
	assert_array(found).contains(
		["amostra:1: extends Node", "amostra:2: float", "amostra:4: get_tree"]
	)


func test_detector_allows_instance_rng_calls() -> void:
	var sample: String = "var v: int = _rng.randi() % 10\nvar w := rng.randi_range(1, 2)\n"
	assert_array(_find_violations("amostra", sample)).is_empty()
