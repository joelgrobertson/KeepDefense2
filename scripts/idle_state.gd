extends State
class_name IdleState

func enter():
	if unit:
		print("Entering IdleState")
		update_animation()

func physics_update(delta):
	if !unit:
		return
		
	# Check for movement commands
	if unit.global_position.distance_to(unit.target_pos) > 5:
		print("Movement command received, transitioning to move")
		state_transition_requested.emit("MovingState")
		
	# Check for attack commands

func update_animation():
	if unit:
		var anim_name = "idle_%d" % unit.calculate_direction_index(unit.last_move_direction)
		if anim_name != unit.current_animation:
			unit.animated_sprite.play(anim_name)
			unit.current_animation = anim_name
