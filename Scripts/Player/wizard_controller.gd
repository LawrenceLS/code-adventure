extends CharacterBody2D
class_name WizardController

## WizardController - Basic platformer movement for the wizard character
##
## Input actions ("move_left", "move_right", "jump") are created at runtime so
## the player works with WASD *and* the arrow keys without needing to hand-edit
## project settings.

@export_group("Movement")
@export var speed: float = 300.0
@export var jump_velocity: float = -420.0
@export var acceleration: float = 2000.0
@export var friction: float = 1800.0

@export_group("Physics")
@export var gravity_multiplier: float = 1.0

@export_group("Visual")
## Node used as the body's visual (Polygon2D / Sprite2D / any Node2D)
@export var visual_path: NodePath = "Visual"

## State
var is_controllable: bool = true
var current_gravity: float = 980.0

## References
var visual: Node2D = null

## Facing direction (1 = right, -1 = left)
var _facing: float = 1.0


func _ready() -> void:
	_ensure_input_actions()

	if visual_path != NodePath(""):
		visual = get_node_or_null(visual_path) as Node2D

	# Pick up gravity from the world if it provides one
	var world := get_parent()
	if world and world.has_method("get_gravity"):
		current_gravity = world.get_gravity()


func _physics_process(delta: float) -> void:
	if not is_controllable:
		return

	# Gravity
	if not is_on_floor():
		velocity.y += current_gravity * gravity_multiplier * delta

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Horizontal movement
	var direction := Input.get_axis("move_left", "move_right")

	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
		_facing = signf(direction)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	move_and_slide()
	_update_visual()


func _update_visual() -> void:
	if visual == null:
		return

	# Facing + a touch of squash/stretch. Scaling around the node origin keeps
	# the body centred (Polygon2D/Sprite2D scale about their own origin).
	var sx := _facing
	var sy := 1.0
	if not is_on_floor():
		sx *= 0.95
		sy = 0.95
	visual.scale = Vector2(sx, sy)


## Teleport to a position
func teleport(new_position: Vector2) -> void:
	global_position = new_position
	velocity = Vector2.ZERO


## Enable/disable player control (for cutscenes, code execution, etc.)
func set_controllable(enabled: bool) -> void:
	is_controllable = enabled
	if not enabled:
		velocity.x = 0.0


## Set gravity multiplier (for anti-gravity puzzles)
func set_gravity_multiplier(multiplier: float) -> void:
	gravity_multiplier = multiplier

	# Flip the visual upside-down when gravity is inverted
	if visual:
		visual.scale.y = -1.0 if multiplier < 0.0 else 1.0


## Get current state as string (for debugging)
func get_state_string() -> String:
	var state := "Floor" if is_on_floor() else "Air"
	return "%s | Velocity: (%.1f, %.1f)" % [state, velocity.x, velocity.y]


## ---------------------------------------------------------------------------
## Runtime input setup
## ---------------------------------------------------------------------------

## Create the movement actions if they don't already exist, mapping both WASD
## and the arrow keys.
func _ensure_input_actions() -> void:
	_add_action("move_left", [KEY_A, KEY_LEFT])
	_add_action("move_right", [KEY_D, KEY_RIGHT])
	_add_action("move_up", [KEY_W, KEY_UP])
	_add_action("jump", [KEY_SPACE, KEY_W, KEY_UP])


func _add_action(action: StringName, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)

	for key in keys:
		# Skip if this key is already bound to the action
		var already_bound := false
		for existing in InputMap.action_get_events(action):
			if existing is InputEventKey and existing.physical_keycode == key:
				already_bound = true
				break
		if already_bound:
			continue

		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action, event)
