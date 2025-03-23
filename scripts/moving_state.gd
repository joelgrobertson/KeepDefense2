extends State
class_name MovingState

# Movement smoothing properties
var steering_weight := 0.7
var current_velocity := Vector2.ZERO

func enter():
	print(unit.name, " moving...")

func physics_update(delta):
	# Check if navigation is finished, if so enter Idle
	if unit.nav_agent.is_navigation_finished():
		unit.velocity = Vector2.ZERO
		current_velocity = Vector2.ZERO
		print(unit.name, " arrived.")
		state_transition_requested.emit("IdleState")
		return
	
	# Get the next path position and calculate the direction
	var next_position = unit.nav_agent.get_next_path_position()
	var current_position = unit.global_position
	var new_velocity = (next_position - current_position).normalized() * unit.speed
	
	# Use the built-in avoidance calculations
	unit.nav_agent.set_velocity(new_velocity)
	
	# Animation update
	if new_velocity.length() > 0.1:
		unit.last_move_direction = new_velocity.normalized()
		var anim_name = "walk_%d" % unit.calculate_direction_index(unit.last_move_direction)
		if anim_name != unit.current_animation:
			unit.animated_sprite.play(anim_name)
			unit.current_animation = anim_name

