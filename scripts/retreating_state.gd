# retreating_state.gd
class_name RetreatingState
extends State

var retreat_position: Vector2

func enter():
	if unit and unit.current_target and is_instance_valid(unit.current_target):
		# Choose a retreat position (away from current danger)
		var retreat_direction = (unit.global_position - unit.current_target.global_position).normalized()
		retreat_position = unit.global_position + retreat_direction * 200.0
		
		# Set navigation
		unit.nav_agent.target_position = retreat_position
		
		print(unit.name, " retreating!")
	else:
		# If no current target, just go to idle
		state_transition_requested.emit("IdleState")

func physics_update(delta):
	# Similar to moving state, but transition to IdleState when reached safe position
	if unit.nav_agent.is_navigation_finished():
		unit.velocity = Vector2.ZERO
		state_transition_requested.emit("IdleState")
		return
	
	# Otherwise, use standard movement logic
	var next_position = unit.nav_agent.get_next_path_position()
	var new_velocity = (next_position - unit.global_position).normalized() * unit.speed
	
	unit.nav_agent.set_velocity(new_velocity)
	
	# Update animation
	if new_velocity.length() > 0.1:
		unit.last_move_direction = new_velocity.normalized()
		unit.play_walk_animation()
