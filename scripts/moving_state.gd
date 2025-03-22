extends State
class_name MovingState

# Add a variable to track if we're already very close to destination
var is_very_close := false

func enter():
	if unit:
		print("Entering MovingState")
		unit.nav_agent.target_position = unit.target_pos
		is_very_close = false
		update_animation()

func physics_update(delta):
	if !unit:
		return
	
	# Check if we're already very close to target
	var distance_to_target = unit.global_position.distance_to(unit.target_pos)
	
	# If we're super close, just snap to position and transition
	if distance_to_target < 5.0:
		unit.velocity = Vector2.ZERO
		print("Very close to target, transitioning to idle")
		state_transition_requested.emit("IdleState")
		return
		
	var arrived = update_movement()
	update_animation()
	
	if arrived:
		# Explicitly zero out velocity when arrived
		unit.velocity = Vector2.ZERO
		print("Arrived at target")
		state_transition_requested.emit("IdleState")

func update_movement() -> bool:
	if unit.nav_agent.is_navigation_finished():
		# Make sure velocity is zeroed out
		unit.velocity = Vector2.ZERO
		return true  # Arrived at target
	
	var next_position = unit.nav_agent.get_next_path_position()
	var direction = (next_position - unit.global_position).normalized()
	
	# Calculate distance to next path point to avoid overshooting
	var distance_to_next = unit.global_position.distance_to(next_position)
	
	# If very close to next navigation point, reduce speed
	var effective_speed = unit.speed
	if distance_to_next < 20.0:
		effective_speed = unit.speed * (distance_to_next / 20.0)
		effective_speed = max(effective_speed, 10.0)  # Don't go too slow
	
	unit.velocity = direction * effective_speed
	unit.last_move_direction = direction
	unit.move_and_slide()
	
	# Check if we're close enough to the final target
	if unit.global_position.distance_to(unit.target_pos) < 10.0:
		return true
		
	return false  # Still moving

func update_animation():
	if unit:
		var anim_name = "walk_%d" % unit.calculate_direction_index(unit.last_move_direction)
		if anim_name != unit.current_animation:
			unit.animated_sprite.play(anim_name)
			unit.current_animation = anim_name
