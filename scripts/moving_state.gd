extends State
class_name MovingState

func enter():
	if unit:
		print("Entering MovingState")
		unit.nav_agent.target_position = unit.target_position
		update_animation()

func set_movement_position(pos: Vector2):
	if unit:
		unit.target_pos = pos
		unit.navigation_agent.target_position = pos

func physics_update(delta):
	if !unit:
		return
	
	var arrived = update_movement()
	update_animation()
	
	if arrived:
		print("Arrived at target")
		emit_signal("state_transition_requested", "IdleState")

func update_movement() -> bool:
	if unit.navigation_agent.is_navigation_finished():
		return true  # Arrived at target
	
	var next_position = unit.navigation_agent.get_next_path_position()
	var direction = (next_position - unit.global_position).normalized()
	unit.velocity = direction * unit.speed
	unit.last_move_direction = direction
	unit.move_and_slide()
	return false  # Still moving

func update_animation():
	if unit:
		var anim_name = "walk_%d" % unit.calculate_direction_index(unit.last_move_direction)
		if anim_name != unit.current_animation:
			unit.animated_sprite.play(anim_name)
			unit.current_animation = anim_name
