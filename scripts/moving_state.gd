extends State
class_name MovingState

# Movement smoothing properties
var steering_weight := 0.7
var current_velocity := Vector2.ZERO
var arrival_threshold := 10.0

func enter():
	if unit:
		print(unit.name, " entering MovingState")
		unit.nav_agent.target_position = unit.target_pos
		current_velocity = Vector2.ZERO
		update_animation()

func physics_update(delta):
	if !unit:
		return
	
	# Check if we're close enough to destination
	var distance_to_target = unit.global_position.distance_to(unit.target_pos)
	if distance_to_target < arrival_threshold:
		unit.velocity = Vector2.ZERO
		current_velocity = Vector2.ZERO
		state_transition_requested.emit("IdleState")
		return
		
	# Update movement and animation
	update_movement(delta)
	update_animation()
	
	# Check if navigation is finished
	if unit.nav_agent.is_navigation_finished():
		unit.velocity = Vector2.ZERO
		current_velocity = Vector2.ZERO
		state_transition_requested.emit("IdleState")

func update_movement(delta):
	if unit.nav_agent.is_navigation_finished():
		unit.velocity = Vector2.ZERO
		current_velocity = Vector2.ZERO
		return
	
	# Get desired direction from navigation
	var next_position = unit.nav_agent.get_next_path_position()
	var desired_direction = (next_position - unit.global_position).normalized()
	
	# Calculate desired velocity based on full speed (no slowdown)
	var desired_velocity = desired_direction * unit.speed
	
	# Smoothly steer towards the desired velocity
	current_velocity = current_velocity.lerp(desired_velocity, 1.0 - steering_weight)
	
	# Apply the calculated velocity
	unit.velocity = current_velocity
	unit.last_move_direction = current_velocity.normalized()
	
	# Move the unit - this should be here, not in Unit._physics_process
	unit.move_and_slide()

func update_animation():
	if unit:
		# Update animation based on movement direction
		var anim_name = "walk_%d" % unit.calculate_direction_index(unit.last_move_direction)
		if anim_name != unit.current_animation:
			unit.animated_sprite.play(anim_name)
			unit.current_animation = anim_name
