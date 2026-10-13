# The engine's own error lines that mean a script, a shader, a deferred call or a signal callback is broken. Sourced by the QA wrappers that read an engine log
# (closeout_check, headless_suite, playthrough, guarded_headless, guarded_windowed) as `grep -aE "$BAD" LOG`, so a new kind is added in one place (docs/CORRECTION_LOG.md 233, 234).
# shellcheck disable=SC2034
BAD='SCRIPT ERROR|SHADER ERROR|Shader compilation failed|Parse Error|Compile Error|Nonexistent function|freed instance|Failed to load script|Failed to instantiate an autoload|Invalid call|Invalid get index|Invalid set index|Cannot infer the type|Error calling deferred method|Error calling from signal|Lambda capture'
