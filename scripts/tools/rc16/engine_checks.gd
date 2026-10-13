extends RefCounted
## Session 23 (docs/CORRECTION_LOG.md 233 and 234): checks that the engine itself says nothing while the game does what it does. A Logger (OS.add_logger) collects every error the engine prints
## while a stimulus runs, and the check passes when it printed none. The log scan of the QA wrappers (tools/qa_sim/engine_errors.sh) reads the same lines after a run; these checks name the cause
## and are what the AF2 mutations of tools/qa_sim/s23_mutations.py bite on. Wired into _closeout_check_runner.gd as `await Rc23Engine.run(self)`.

const SHADER_DIRS: PackedStringArray = ["res://assets/shaders", "res://scripts/shaders"]

## The errors the engine printed while it was installed, as `file:line message`. The engine calls it from any thread.
class Spy extends Logger:
	var seen: Array[String] = []
	var _lock := Mutex.new()

	func _log_error(_function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == Logger.ERROR_TYPE_WARNING:
			return
		_lock.lock()
		seen.append("%s:%d %s" % [file.get_file(), line, rationale if rationale != "" else code])
		_lock.unlock()

static func run(r: Node) -> void:
	await _freed_button(r)
	_shaders(r)

## UISFX1: UISFX looks at a button one frame after it entered the tree; a button freed in that frame used to make the engine refuse the call (1,016 times in one closeout run).
static func _freed_button(r: Node) -> void:
	var spy := Spy.new()
	OS.add_logger(spy)
	var button := Button.new()
	r.add_child(button)
	button.free()
	await r.get_tree().process_frame
	await r.get_tree().process_frame
	OS.remove_logger(spy)
	r._ok(spy.seen.is_empty(), "UISFX1 a button freed in its first frame raises no engine error (%s)" % [spy.seen.slice(0, 2)])

## SHADER1: every shader file of the project compiles; the fog card shader had a range hint on a vec2 and drew nothing, and no log scan looked for it.
static func _shaders(r: Node) -> void:
	var spy := Spy.new()
	OS.add_logger(spy)
	var count: int = 0
	for dir: String in SHADER_DIRS:
		for file: String in DirAccess.get_files_at(dir):
			if file.get_extension() == "gdshader":
				var shader := Shader.new()
				shader.code = FileAccess.get_file_as_string(dir.path_join(file))
				count += 1
	OS.remove_logger(spy)
	r._ok(count > 0 and spy.seen.is_empty(), "SHADER1 the %d shader files compile with no engine error (%s)" % [count, spy.seen.slice(0, 2)])
