# moving_state.gd
class_name MovingState
extends State

func enter():
	print(unit.name, " moving...")

func physics_update(delta):
	# Check if navigation is finished
	if unit.nav_agent.is_navigation_finished():
		unit.velocity = Vector2.ZERO
		print(unit.name, " arrived.")
		state_transition_requested.emit("IdleState")
		return
	
	# Get the next path position and calculate the direction
	var next_position = unit.nav_agent.get_next_path_position()
	var direction = (next_position - unit.global_position).normalized()
	
	# Set velocity
	unit.velocity = direction * unit.speed
	unit.move_and_slide()
	
	# Update animation
	if unit.velocity.length() > 0.1:
		unit.last_move_direction = unit.velocity.normalized()
		unit.play_walk_animation()
