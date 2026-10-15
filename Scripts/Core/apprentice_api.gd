extends RefCounted
class_name ApprenticeAPI

## ApprenticeAPI - Implementation of allowed functions for Apprentice tier
## These are static functions that the sandbox can call

# References to game systems (injected at runtime)
var _world: Node = null
var _player: Node = null


## Initialize with world references
func setup(world: Node, player: Node = null) -> void:
	_world = world
	_player = player


## Set the world reference
func set_world(world: Node) -> void:
	_world = world


## Set the player reference
func set_player(player: Node) -> void:
	_player = player


# ==================== WORLD MANIPULATION ====================

## Spawn a platform at the given position
func spawn_platform(x: float, y: float, width: float = 64, height: float = 16) -> Node2D:
	if _world == null:
		push_error("No world reference set")
		return null

	# Create a new platform
	var platform := StaticBody2D.new()
	platform.position = Vector2(x, y)

	# Add collision shape
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width, height)
	collision.shape = shape
	platform.add_child(collision)

	# Add visual (placeholder)
	var visual := ColorRect.new()
	visual.size = Vector2(width, height)
	visual.position = Vector2(-width/2, -height/2)
	visual.color = Color(0.6, 0.4, 0.2)  # Brown placeholder
	platform.add_child(visual)

	# Add to world
	_world.add_child(platform)

	# Add metadata for identification
	platform.set_meta("spawned_by_code", true)
	platform.set_meta("spawn_time", Time.get_ticks_msec())

	return platform


## Remove a spawned platform by position (approximate)
func remove_platform(x: float, y: float, tolerance: float = 32.0) -> bool:
	if _world == null:
		return false

	var target_pos := Vector2(x, y)
	var removed := false

	for child in _world.get_children():
		if child is StaticBody2D and child.has_meta("spawned_by_code"):
			if child.position.distance_to(target_pos) <= tolerance:
				child.queue_free()
				removed = true
				break

	return removed


## Change the world's gravity (affects player)
func change_gravity(value: float) -> void:
	if _world == null:
		return

	# Find physics server or gravity area
	# This is a simplified version - actual implementation depends on your setup
	if _world.has_method("set_gravity"):
		_world.set_gravity(value)
	else:
		# Try to find a gravity node
		var gravity_area = _world.get_node_or_null("GravityArea")
		if gravity_area:
			gravity_area.gravity = value


## Teleport the player to a position
func teleport_player(x: float, y: float) -> void:
	if _player == null:
		push_error("No player reference set")
		return

	if _player is CharacterBody2D:
		_player.global_position = Vector2(x, y)
		_player.velocity = Vector2.ZERO

	# Snap camera to new position so it doesn't lag behind
	var level = _player.get_parent()
	if level:
		for child in level.get_children():
			if child.has_method("snap_to_target"):
				child.snap_to_target()
				break


## Get player position
func get_player_position() -> Vector2:
	if _player == null:
		return Vector2.ZERO
	return _player.global_position


# ==================== VISUAL EFFECTS ====================

## Change the color of a spawned platform (by position)
func color_platform(x: float, y: float, color: Color, tolerance: float = 32.0) -> bool:
	if _world == null:
		return false

	var target_pos := Vector2(x, y)

	for child in _world.get_children():
		if child is StaticBody2D and child.has_meta("spawned_by_code"):
			if child.position.distance_to(target_pos) <= tolerance:
				# Find ColorRect child
				for visual in child.get_children():
					if visual is ColorRect:
						visual.color = color
						return true
	return false


## Spawn a particle effect at position
func spawn_particles(x: float, y: float, count: int = 10, color: Color = Color.WHITE) -> void:
	if _world == null:
		return

	var particles := CPUParticles2D.new()
	particles.position = Vector2(x, y)
	particles.amount = count
	particles.emitting = true
	particles.one_shot = true
	particles.color = color
	particles.lifetime = 1.0

	_world.add_child(particles)

	# Auto-free after particles finish
	particles.finished.connect(particles.queue_free)


# ==================== UTILITY FUNCTIONS ====================

## Wait for a duration (in seconds) - blocks execution
func wait(seconds: float) -> void:
	# In sandbox, this would be problematic
	# For now, just print (real implementation would need async support)
	print("wait(", seconds, ") called - async not yet supported")


## Log a message to the console
func log_message(message: String) -> void:
	print("[Player Code]: ", message)


## Create a Vector2 (convenience function)
func vec2(x: float, y: float) -> Vector2:
	return Vector2(x, y)


## Get a random float between min and max
func random_range(min_val: float, max_val: float) -> float:
	return randf_range(min_val, max_val)


## Get a random integer between min and max (inclusive)
func random_int(min_val: int, max_val: int) -> int:
	return randi_range(min_val, max_val)


# ==================== PUZZLE-SPECIFIC ====================

## Check if player is near a position
func is_player_near(x: float, y: float, radius: float = 64.0) -> bool:
	if _player == null:
		return false

	var player_pos: Vector2 = _player.global_position
	return player_pos.distance_to(Vector2(x, y)) <= radius


## Check if a platform exists at position
func platform_exists_at(x: float, y: float, tolerance: float = 32.0) -> bool:
	if _world == null:
		return false

	var target_pos := Vector2(x, y)

	for child in _world.get_children():
		if child is StaticBody2D and child.has_meta("spawned_by_code"):
			if child.position.distance_to(target_pos) <= tolerance:
				return true
	return false


## Count spawned platforms
func count_spawned_platforms() -> int:
	if _world == null:
		return 0

	var count := 0
	for child in _world.get_children():
		if child is StaticBody2D and child.has_meta("spawned_by_code"):
			count += 1
	return count


## Clear all spawned platforms
func clear_all_platforms() -> void:
	if _world == null:
		return

	for child in _world.get_children():
		if child is StaticBody2D and child.has_meta("spawned_by_code"):
			child.queue_free()
