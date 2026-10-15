extends Camera2D
class_name GameCamera

## GameCamera - Smooth-follow camera with lookahead, limits, and screen shake
## Designed for 2D platformer levels
## All smoothing is done manually (no position_smoothing) for full control

@export_group("Follow")
## How quickly the camera catches up (higher = snappier, ~5-15 feels good)
@export_range(1.0, 30.0) var follow_speed: float = 8.0
## Soft deadzone radius (pixels). 0 = always centred on the player.
## Values > 0 let the player drift this far from centre before the camera moves.
@export_range(0.0, 200.0) var deadzone_radius: float = 0.0

@export_group("Lookahead")
## How far ahead of the player to peek based on movement direction
@export var lookahead_distance: float = 80.0
## How quickly the lookahead catches up
@export var lookahead_speed: float = 5.0

@export_group("Zoom")
@export var default_zoom: Vector2 = Vector2(1.5, 1.5)
@export var min_zoom: Vector2 = Vector2(0.5, 0.5)
@export var max_zoom: Vector2 = Vector2(4.0, 4.0)

@export_group("Limits")
## Minimum size of the auto-calculated limit box (prevents the camera sticking
## on flat levels whose geometry is smaller than the viewport)
@export var min_limit_size: Vector2 = Vector2(2400, 1300)

@export_group("Shake")
## Shake decay rate — higher = shake dies faster
@export var shake_decay: float = 5.0
## Shake frequency (wobble speed)
@export var shake_frequency: float = 30.0

## Target to follow (set by the level)
var target: Node2D = null

## Internal state
var _current_position: Vector2 = Vector2.ZERO
var _lookahead_offset: Vector2 = Vector2.ZERO
var _shake_offset: Vector2 = Vector2.ZERO
var _shake_intensity: float = 0.0
var _shake_time: float = 0.0


func _ready() -> void:
	zoom = default_zoom
	# We manage smoothing ourselves; disable the built-in one
	position_smoothing_enabled = false

	# Start centered on target
	if target:
		_current_position = target.global_position
		global_position = _current_position


func _process(delta: float) -> void:
	if target == null:
		return

	# --- Compute desired position (target + lookahead) ---
	var target_velocity: Vector2 = Vector2.ZERO
	if target is CharacterBody2D:
		target_velocity = (target as CharacterBody2D).velocity

	# Ease lookahead toward the direction of movement
	var desired_lookahead := Vector2(
		sign(target_velocity.x) * lookahead_distance,
		0.0
	)
	_lookahead_offset = _lookahead_offset.lerp(desired_lookahead, lookahead_speed * delta)

	var desired_position: Vector2 = target.global_position + _lookahead_offset

	# --- Deadzone ---
	# Only start moving once the desired position exits the deadzone circle
	var to_desired: Vector2 = desired_position - _current_position
	if to_desired.length() > deadzone_radius:
		# Lerp toward desired, pulling back slightly so it doesn't overshoot
		var t: float = clampf(follow_speed * delta, 0.0, 1.0)
		_current_position = _current_position.lerp(desired_position, t)
	# else: inside deadzone, hold still

	# --- Screen shake ---
	_shake_time += delta * shake_frequency
	if _shake_intensity > 0.1:
		_shake_offset = Vector2(
			sin(_shake_time * 1.7) * _shake_intensity,
			cos(_shake_time * 2.3) * _shake_intensity
		)
		_shake_intensity = lerpf(_shake_intensity, 0.0, shake_decay * delta)
	else:
		_shake_offset = Vector2.ZERO
		_shake_intensity = 0.0

	# --- Apply ---
	global_position = _current_position
	offset = _shake_offset


## Set the follow target
func set_target(node: Node2D) -> void:
	target = node
	if target:
		_current_position = target.global_position
		global_position = _current_position
		_lookahead_offset = Vector2.ZERO


## Set camera limits (world-space rect the camera can't see beyond)
func set_limits(rect: Rect2) -> void:
	limit_left = int(rect.position.x)
	limit_top = int(rect.position.y)
	limit_right = int(rect.position.x + rect.size.x)
	limit_bottom = int(rect.position.y + rect.size.y)


## Auto-calculate limits from a level node's children.
## Prefers the visual ColorRects (which represent the drawn world) and also
## includes collision shapes. Guarantees the limit area is at least as large as
## a comfortable minimum so the camera can always pan (flat levels otherwise
## produce a limit box shorter than the viewport, which makes the camera stick).
func set_limits_from_node(node: Node2D) -> void:
	if node == null:
		return

	var bounds := Rect2()
	var found := false

	for child in node.get_children():
		if not (child is Node2D):
			continue
		if child is Camera2D or child is CanvasLayer:
			continue

		for r in _collect_rects(child as Node2D):
			if not found:
				bounds = r
				found = true
			else:
				bounds = bounds.merge(r)

	if not found:
		return

	# Grow so the camera doesn't hug the geometry edges
	bounds = bounds.grow(150.0)

	# Enforce a minimum size, centred on the current bounds
	if bounds.size.x < min_limit_size.x:
		var extra := (min_limit_size.x - bounds.size.x) / 2.0
		bounds.position.x -= extra
		bounds.size.x = min_limit_size.x
	if bounds.size.y < min_limit_size.y:
		var extra := (min_limit_size.y - bounds.size.y) / 2.0
		bounds.position.y -= extra
		bounds.size.y = min_limit_size.y

	set_limits(bounds)


## Collect world-space rects for a node from its collision shape and ColorRects
func _collect_rects(n: Node2D) -> Array[Rect2]:
	var out: Array[Rect2] = []

	# Collision shape (if any)
	var cs := n.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs and cs.shape is RectangleShape2D:
		var sz: Vector2 = (cs.shape as RectangleShape2D).size
		out.append(Rect2(n.global_position + cs.position - sz / 2.0, sz))

	# Visual ColorRects (world-space)
	for c in n.get_children():
		if c is ColorRect:
			var cr := c as ColorRect
			out.append(Rect2(cr.global_position, cr.size))

	return out


## Trigger a screen shake
func shake(intensity: float = 5.0) -> void:
	_shake_intensity = max(_shake_intensity, intensity)


## Smoothly zoom to a target level
func tween_zoom(target_zoom: Vector2, duration: float = 0.5) -> void:
	var clamped := target_zoom.clamp(min_zoom, max_zoom)
	var tween := create_tween()
	tween.tween_property(self, "zoom", clamped, duration)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)


## Snap instantly to the target (useful after teleports)
func snap_to_target() -> void:
	if target:
		_current_position = target.global_position
		global_position = _current_position
		_lookahead_offset = Vector2.ZERO


## Reset camera to default state
func reset() -> void:
	_lookahead_offset = Vector2.ZERO
	_shake_offset = Vector2.ZERO
	_shake_intensity = 0.0
	zoom = default_zoom
	snap_to_target()
