extends GdUnitTestSuite

const CORE_DIR: String = "res://core"

const RULES: Array[Dictionary] = [
	{"name": "get_tree", "pattern": "\\bget_tree\\b"},
	{"name": "Time.", "pattern": "(?<![\\w.])Time\\."},
	{"name": "OS.get_ticks", "pattern": "\\bOS\\.get_ticks"},
	{"name": "float", "pattern": "\\bfloat\\b"},
	{
		"name": "sorteio global",
		"pattern":
		(
			"(?<![\\w.])(randi|randf|randomize|randi_range|randf_range|randfn|pick_random|shuffle)"
			+ "\\s*\\("
		)
	},
]

# Bases permitidas para `extends` em core/ (além de classes declaradas dentro de core/).
const ALLOWED_BASES: Array[String] = ["RefCounted", "Resource", "Object"]


# Nomes de class_name declarados no texto.
func _declared_classes(text: String) -> Array[String]:
	var names: Array[String] = []
	var re := RegEx.new()
	re.compile("(?m)^\\s*class_name\\s+(\\w+)")
	for m: RegExMatch in re.search_all(text):
		names.append(m.get_string(1))
	return names


# Devolve "rótulo:linha: regra" para cada violação. Sem `extends` vale como RefCounted.
func _find_violations(label: String, text: String, core_classes: Array[String]) -> Array[String]:
	var found: Array[String] = []
	var lines: PackedStringArray = text.split("\n")
	var extends_re := RegEx.new()
	extends_re.compile("\\bextends\\s+(\\S+)")
	for i: int in lines.size():
		for m: RegExMatch in extends_re.search_all(lines[i]):
			var base: String = m.get_string(1).trim_suffix(":")
			if not (ALLOWED_BASES.has(base) or core_classes.has(base)):
				found.append("%s:%d: extends %s não permitido" % [label, i + 1, base])
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
	var texts: Dictionary = {}
	var core_classes: Array[String] = []
	for path: String in scripts:
		var text: String = FileAccess.get_file_as_string(path)
		texts[path] = text
		core_classes.append_array(_declared_classes(text))
	var all_violations: Array[String] = []
	for path: String in scripts:
		all_violations.append_array(_find_violations(path, String(texts[path]), core_classes))
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
		+ "\tvar r3 = randi ()\n"
		+ "\tvar r4 = pick_random([1])\n"
		+ "\tshuffle(a)\n"
		+ "\tvar r5 = randfn(0, 1)\n"
	)
	var found: Array[String] = _find_violations("amostra", sample, [])
	assert_int(found.size()).is_equal(11)
	(
		assert_array(found)
		. contains(
			[
				"amostra:1: extends Node não permitido",
				"amostra:2: float",
				"amostra:4: get_tree",
				"amostra:9: sorteio global",
				"amostra:10: sorteio global",
				"amostra:11: sorteio global",
				"amostra:12: sorteio global",
			]
		)
	)


func test_detector_catches_node_descendants_and_path_extends() -> void:
	for base: String in ["Node2D", "Node3D", "Control", "CanvasItem", "Sprite2D"]:
		var found: Array[String] = _find_violations("a", "extends %s\n" % base, [])
		assert_int(found.size()).is_equal(1)
	assert_int(_find_violations("a", 'extends "res://x.gd"\n', []).size()).is_equal(1)
	assert_int(_find_violations("a", "class_name Foo extends Node2D\n", []).size()).is_equal(1)


func test_detector_allows_permitted_extends() -> void:
	for base: String in ["RefCounted", "Resource", "Object"]:
		assert_array(_find_violations("a", "extends %s\n" % base, [])).is_empty()
	assert_array(_find_violations("a", "class_name Foo\nvar x: int = 1\n", [])).is_empty()
	assert_array(_find_violations("a", "extends Rng\n", ["Rng"])).is_empty()
	assert_int(_find_violations("a", "extends Rng\n", []).size()).is_equal(1)
	assert_array(_find_violations("a", "class Inner extends RefCounted:\n\tpass\n", [])).is_empty()


func test_detector_allows_instance_rng_calls() -> void:
	var sample: String = (
		"var v: int = _rng.randi() % 10\n"
		+ "var w := rng.randi_range(1, 2)\n"
		+ "var z: int = _rng.next_int(5)\n"
		+ "var y: int = rng.range_int(1, 2)\n"
		+ "var p = arr.pick_random()\n"
		+ "arr.shuffle()\n"
	)
	assert_array(_find_violations("amostra", sample, [])).is_empty()
