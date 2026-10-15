extends Resource
class_name WizardAPI

## WizardAPI - Defines allowed API calls per progression tier
## Each tier unlocks more functions, classes, and language features

@export_group("Tier Configuration")

@export var tier_name: String = "Apprentice"
@export var tier_order: int = 0

@export_group("Allowed Global Functions")
## Format: "function_name" -> Dictionary with signature info
## Keys: "args" (Array of type strings), "returns" (type string)
@export var allowed_functions: Dictionary = {}

@export_group("Allowed Node Methods")
## Format: "NodeClassName" -> Dictionary of method_name -> signature
@export var allowed_node_methods: Dictionary = {}

@export_group("Allowed Node Properties")
## Format: "NodeClassName" -> Array of allowed property names (read/write)
@export var allowed_node_properties: Dictionary = {}

@export_group("Allowed Classes")
## Classes that can be instantiated or referenced (e.g., "Vector2", "Color", "Array")
@export var allowed_classes: Array[String] = []

@export_group("Allowed Built-in Constants")
@export var allowed_constants: Array[String] = []

@export_group("Language Features")
@export var allow_loops: bool = false
@export var allow_conditionals: bool = true
@export var allow_functions: bool = false
@export var allow_lambdas: bool = false
@export var allow_match: bool = false

@export_group("Execution Limits")
@export var max_execution_time_ms: int = 500
@export var max_memory_bytes: int = 1024 * 1024  # 1MB
@export var max_statements: int = 100
@export var max_recursion_depth: int = 10

@export_group("Custom API Implementation")
## Optional: Path to a script that implements custom API functions
## This script should have static functions matching allowed_functions keys
@export_file("*.gd") var api_implementation_path: String = ""

# Static tier definition paths (for convenience)
const TIER_APPRENTICE: String = "res://Resources/api_tiers/apprentice_api.tres"
const TIER_JOURNEYMAN: String = "res://Resources/api_tiers/journeyman_api.tres"
const TIER_MASTER: String = "res://Resources/api_tiers/master_api.tres"


func _init() -> void:
	# Set up defaults if empty
	if allowed_classes.is_empty():
		allowed_classes = ["Vector2", "Vector2i", "Color", "Array", "Dictionary", "Rect2", "String"]


## Get the API implementation script
func get_api_implementation() -> Script:
	if api_implementation_path != "":
		return load(api_implementation_path)
	return null


## Check if a global function is allowed
func is_function_allowed(func_name: String) -> bool:
	return allowed_functions.has(func_name)


## Get function signature info
func get_function_signature(func_name: String) -> Dictionary:
	if allowed_functions.has(func_name):
		return allowed_functions[func_name]
	return {}


## Check if a node method is allowed
func is_node_method_allowed(node_class: String, method_name: String) -> bool:
	if not allowed_node_methods.has(node_class):
		return false
	var methods: Dictionary = allowed_node_methods[node_class]
	return methods.has(method_name)


## Check if a node property is allowed
func is_node_property_allowed(node_class: String, property_name: String) -> bool:
	if not allowed_node_properties.has(node_class):
		return false
	return property_name in allowed_node_properties[node_class]


## Check if a class is allowed
func is_class_allowed(p_class_name: String) -> bool:
	return p_class_name in allowed_classes


## Check if a constant is allowed
func is_constant_allowed(const_name: String) -> bool:
	return const_name in allowed_constants


## Get all allowed function names (for autocomplete)
func get_allowed_function_names() -> Array[String]:
	var names: Array[String] = []
	for key in allowed_functions.keys():
		names.append(key)
	return names


## Look up an optional default value for argument `index` of `signature`.
## Defaults may be keyed by String ("2") or int (2); returns null when absent.
func get_arg_default(signature: Dictionary, index: int) -> Variant:
	var defaults: Dictionary = signature.get("defaults", {})
	if defaults.has(str(index)):
		return defaults[str(index)]
	if defaults.has(index):
		return defaults[index]
	return null


## Build the parameter declaration strings used by the sandbox wrapper,
## e.g. ["arg0: float", "arg1: float", "arg2: float = 64"].
func build_arg_declarations(func_name: String) -> Array[String]:
	var signature := get_function_signature(func_name)
	var args: Array = signature.get("args", [])
	var out: Array[String] = []

	for i in range(args.size()):
		var decl := "arg%d: %s" % [i, args[i]]
		var default_value = get_arg_default(signature, i)
		if default_value != null:
			decl += " = %s" % str(default_value)
		out.append(decl)

	return out


## Default literal for a return type, used by the sandbox wrapper's fallback
## branch (a typed function must return a value of that type on every path).
func get_default_return(type_name: String) -> String:
	match type_name:
		"bool":
			return "false"
		"int":
			return "0"
		"float":
			return "0.0"
		"String":
			return "\"\""
		"Vector2":
			return "Vector2.ZERO"
		"Vector2i":
			return "Vector2i.ZERO"
		"Color":
			return "Color()"
		"Rect2":
			return "Rect2()"
		"Array":
			return "[]"
		"Dictionary":
			return "{}"
		_:
			# Object-ish types (Node2D, RefCounted, ...) can be null
			return "null"


## Human-readable signature for the UI,
## e.g. "spawn_platform(x: float, y: float, width: float = 64) -> Node2D".
func format_signature(func_name: String) -> String:
	var signature := get_function_signature(func_name)
	var args: Array = signature.get("args", [])
	var names: Array = signature.get("param_names", [])
	var returns: String = signature.get("returns", "void")

	var parts: Array[String] = []
	for i in range(args.size()):
		var param_name: String = names[i] if i < names.size() else ("arg%d" % i)
		var part := "%s: %s" % [param_name, args[i]]
		var default_value = get_arg_default(signature, i)
		if default_value != null:
			part += " = %s" % str(default_value)
		parts.append(part)

	var result := "%s(%s)" % [func_name, ", ".join(parts)]
	if returns != "void":
		result += " -> " + returns
	return result


## Get allowed methods for a specific node class (for autocomplete)
func get_allowed_methods_for_class(node_class: String) -> Array[String]:
	var names: Array[String] = []
	if allowed_node_methods.has(node_class):
		for key in allowed_node_methods[node_class].keys():
			names.append(key)
	return names


## Validate the API configuration
func validate() -> Array[String]:
	var errors: Array[String] = []

	if tier_order < 0:
		errors.append("tier_order must be >= 0")

	if max_execution_time_ms <= 0:
		errors.append("max_execution_time_ms must be > 0")

	if max_execution_time_ms > 5000:
		errors.append("max_execution_time_ms should not exceed 5000ms (5s)")

	if max_memory_bytes <= 0:
		errors.append("max_memory_bytes must be > 0")

	if max_statements <= 0:
		errors.append("max_statements must be > 0")

	if max_recursion_depth <= 0:
		errors.append("max_recursion_depth must be > 0")

	if max_recursion_depth > 50:
		errors.append("max_recursion_depth should not exceed 50")

	if api_implementation_path != "" and not ResourceLoader.exists(api_implementation_path):
		errors.append("api_implementation_path does not exist: " + api_implementation_path)

	return errors
