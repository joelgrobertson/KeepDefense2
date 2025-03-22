extends State
class_name MovingState

# Movement smoothing properties
var steering_weight := 0.7
var current_velocity := Vector2.ZERO

func enter():
	print(unit.name, " entering MovingState")

func physics_update(delta):
	# Check if navigation is finished, if so enter Idle
	if unit.nav_agent.is_navigation_finished():
		unit.velocity = Vector2.ZERO
		current_velocity = Vector2.ZERO
		state_transition_requested.emit("IdleState")
	
	var next_position = unit.nav_agent.get_next_path_position()
	var desired_direction = (next_position - unit.global_position).normalized()
	var desired_velocity = desired_direction * unit.speed
	
	# Smoothly steer towards the desired velocity
	current_velocity = current_velocity.lerp(desired_velocity, 1.0 - steering_weight)
	
	# Apply the calculated velocity
	unit.velocity = current_velocity
	unit.last_move_direction = current_velocity.normalized()
	
	var anim_name = "walk_%d" % unit.calculate_direction_index(unit.last_move_direction)
	if anim_name != unit.current_animation:
		unit.animated_sprite.play(anim_name)
		unit.current_animation = anim_name

	unit.move_and_slide()

