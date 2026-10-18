class_name MotorErros
extends Logger
## Registra todo erro do motor (push_error, erro de script) enquanto está instalado.
## Avisos (`push_warning`) não contam.

var errors: Array[String] = []
var _mutex: Mutex = Mutex.new()


func _log_error(
	function: String,
	file: String,
	line: int,
	code: String,
	rationale: String,
	_editor_notify: bool,
	error_type: int,
	_script_backtraces: Array[ScriptBacktrace]
) -> void:
	if error_type == ERROR_TYPE_WARNING:
		return
	_mutex.lock()
	errors.append("%s (%s:%d %s) %s" % [code, file, line, function, rationale])
	_mutex.unlock()


func _log_message(_message: String, _error: bool) -> void:
	pass
