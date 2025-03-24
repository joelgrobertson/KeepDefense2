# moving_state.gd
class_name MovingState
extends State

func enter():
	print(unit.name, " moving...")

# moving_state.gd - Add stricter validation
func physics_update(delta):
	# Always check if unit still exists
	if !unit:
		return
		
	# Check if navigation is finished
	if unit.nav_agent.is_navigation_finished():
		unit.velocity = Vector2.ZERO
		print(unit.name, " arrived.")
		state_transition_requested.emit("IdleState")
		return
	
	# If we have a combat target, prioritize following it (with validation)
	if unit.current_target and is_instance_valid(unit.current_target):
		unit.nav_agent.target_position = unit.current_target.global_position
	
	# Get the next path position and calculate the direction
	var next_position = unit.nav_agent.get_next_path_position()
	var new_velocity = (next_position - unit.global_position).normalized() * unit.speed
	
	# Set the velocity for avoidance calculations
	unit.nav_agent.set_velocity(new_velocity)
	
	# Update animation
	if new_velocity.length() > 0.1:
		unit.last_move_direction = new_velocity.normalized()
		unit.play_walk_animation()
