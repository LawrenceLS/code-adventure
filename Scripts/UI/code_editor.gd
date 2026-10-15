extends CanvasLayer
class_name CodeEditorUI

## CodeEditorUI - Pop-up "Spellbook" where the player writes and runs code.
##
## Opens over most of the screen, pauses the game, and lets the player cast a
## spell (run their code). The level owns execution and calls back with results.

signal run_requested(code: String)
signal opened
signal closed

@onready var _level_title: Label = $Margin/Panel/Inner/VBox/Header/LevelTitle
@onready var _hint_button: Button = $Margin/Panel/Inner/VBox/Header/HintButton
@onready var _close_button: Button = $Margin/Panel/Inner/VBox/Header/CloseButton
@onready var _code_edit: CodeEdit = $Margin/Panel/Inner/VBox/Body/Left/CodeEdit
@onready var _run_button: Button = $Margin/Panel/Inner/VBox/Body/Left/ButtonRow/RunButton
@onready var _reset_button: Button = $Margin/Panel/Inner/VBox/Body/Left/ButtonRow/ResetButton
@onready var _status: Label = $Margin/Panel/Inner/VBox/Body/Left/ButtonRow/StatusLabel
@onready var _ref: RichTextLabel = $Margin/Panel/Inner/VBox/Body/Right/RefScroll/RefList
@onready var _output: RichTextLabel = $Margin/Panel/Inner/VBox/OutputPanel/Output

## Re-open automatically? (kept for future use)
@export var auto_close_on_success: bool = true

var _is_open: bool = false
var _hints: Array = []
var _hint_index: int = 0
var _api: WizardAPI = null
var _initial_code: String = ""


func _ready() -> void:
	visible = false

	# CodeEdit niceties
	_code_edit.gutters_draw_line_numbers = true
	_code_edit.indent_automatic = true
	_code_edit.highlight_current_line = true
	_code_edit.wrap_mode = TextEdit.LINE_WRAPPING_NONE
	_code_edit.minimap_draw = false
	_code_edit.placeholder_text = "# Write your spell here...\n# e.g. spawn_platform(690, 560)"

	_ref.fit_content = true

	_run_button.pressed.connect(_on_run_pressed)
	_reset_button.pressed.connect(_on_reset_pressed)
	_close_button.pressed.connect(close_editor)
	_hint_button.pressed.connect(_on_hint_pressed)

	_build_highlighter()
	_set_output("Press [b]E[/b] to open, then cast your spell. Good luck, apprentice!")


## ---------------------------------------------------------------------------
## Public API
## ---------------------------------------------------------------------------

func open_editor() -> void:
	if _is_open:
		return
	_is_open = true
	visible = true
	get_tree().paused = true
	_code_edit.grab_focus()
	opened.emit()


func close_editor() -> void:
	if not _is_open:
		return
	_is_open = false
	visible = false
	get_tree().paused = false
	_code_edit.release_focus()
	closed.emit()


func toggle_editor() -> void:
	if _is_open:
		close_editor()
	else:
		open_editor()


func is_open() -> bool:
	return _is_open


func set_code(code: String) -> void:
	_initial_code = code
	_code_edit.text = code


func get_code() -> String:
	return _code_edit.text


## Configure the header + hints for a level
func set_level_info(title: String, description: String, hints: Array) -> void:
	_level_title.text = title
	_hints = hints
	_hint_index = 0
	if description != "":
		_set_output(description)


## Build the "Available Spells" panel from the current API whitelist
func set_api_reference(api: WizardAPI) -> void:
	_api = api

	if api == null:
		_ref.text = "No spells available."
		return

	var names := api.get_allowed_function_names()
	names.sort()

	var bb := "[b]Available spells[/b]\n\n"
	for spell in names:
		var signature := api.format_signature(spell)
		var paren := signature.find("(")
		if paren < 0:
			bb += "[color=#ffd479]%s[/color]\n" % signature
			continue
		var fname := signature.substr(0, paren)
		var rest := signature.substr(paren)
		bb += "[color=#ffd479]%s[/color][color=#9fb2c9]%s[/color]\n" % [fname, rest]

	_ref.text = bb

	# Rebuild so API function names glow in the code editor
	_build_highlighter()


## Called by the level once execution finishes
func show_result(success: bool, message: String, output: Array) -> void:
	var bb := ""
	if success:
		bb = "[color=#7ee787]✓ Spell cast successfully![/color]"
	else:
		bb = "[color=#ff7b72]✗ %s[/color]" % message

	if not output.is_empty():
		bb += "\n[color=#9fb2c9]" + "\n".join(output) + "[/color]"

	if success:
		print("[Spellbook] Spell cast succeeded")
	else:
		print("[Spellbook] Spell failed: ", message)

	_set_output(bb)
	_status.text = "Ready" if success else "Error"

	if success and auto_close_on_success:
		close_editor()


## ---------------------------------------------------------------------------
## Internals
## ---------------------------------------------------------------------------

func _on_run_pressed() -> void:
	_status.text = "Casting..."
	run_requested.emit(_code_edit.text)


func _on_reset_pressed() -> void:
	_code_edit.text = _initial_code
	_set_output("Editor reset.")


func _on_hint_pressed() -> void:
	if _hints.is_empty():
		_set_output("[color=#e3b341]No hints for this level.[/color]")
		return
	var hint := str(_hints[_hint_index])
	_hint_index = (_hint_index + 1) % _hints.size()
	_set_output("[color=#e3b341]Hint: %s[/color]" % hint)


func _set_output(bbcode: String) -> void:
	_output.text = bbcode


func _input(event: InputEvent) -> void:
	# Open shortcut works while the editor is closed (gameplay / unpaused)
	if _is_open:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E or event.keycode == KEY_TAB:
			open_editor()
			get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if not _is_open:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			close_editor()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F5 or (event.ctrl_pressed and event.keycode == KEY_ENTER):
			_on_run_pressed()
			get_viewport().set_input_as_handled()


func _build_highlighter() -> void:
	var hl := CodeHighlighter.new()

	# Language keywords
	var keyword_color := Color("ff7b72")
	for kw in [
		"if", "elif", "else", "for", "while", "return", "and", "or", "not",
		"in", "match", "break", "continue", "pass", "func", "var", "const",
		"true", "false", "null", "await", "self",
	]:
		hl.add_keyword_color(kw, keyword_color)

	# Built-in types / helpers
	var builtin_color := Color("79c0ff")
	for builtin in [
		"print", "str", "int", "float", "bool", "len", "range", "abs", "min",
		"max", "clamp", "lerp", "randf", "randi", "sin", "cos", "sqrt", "pow",
		"floor", "ceil", "round", "sign",
		"Vector2", "Vector2i", "Color", "Rect2", "Array", "Dictionary", "String",
	]:
		hl.add_keyword_color(builtin, builtin_color)

	# The player's available API functions glow gold
	if _api:
		for spell in _api.get_allowed_function_names():
			hl.add_keyword_color(spell, Color("ffd479"))

	# Strings + comments
	hl.add_color_region("\"", "\"", Color("a5d6ff"))
	hl.add_color_region("'", "'", Color("a5d6ff"))
	hl.add_color_region("#", "", Color("8b949e"), true)

	hl.number_color = Color("d2a8ff")
	hl.symbol_color = Color("c9d1d9")
	hl.function_color = Color("ffd479")
	hl.member_variable_color = Color("7ee787")

	_code_edit.syntax_highlighter = hl
