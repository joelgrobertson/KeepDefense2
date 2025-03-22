extends State
class_name IdleState

# Add a cooldown to prevent rapid state transitions
var transition_cooldown := 0.0
var can_transition := true

func enter():
	if unit:
		print(unit.name, " entering IdleState")
		# Ensure velocity is zeroed when entering idle state
		unit.velocity = Vector2.ZERO
		update_animation()
		
		# Reset cooldown
		transition_cooldown = 0.2  # Reduced cooldown time
		can_transition = false

func physics_update(delta):
	if !unit:
		return
		
	# Handle transition cooldown
	if !can_transition:
		transition_cooldown -= delta
		if transition_cooldown <= 0:
			can_transition = true
	
	# Ensure the unit stays in place
	unit.velocity = Vector2.ZERO
	
	# Check for movement commands with increased threshold
	if can_transition and unit.global_position.distance_to(unit.target_pos) > 10.0:
		state_transition_requested.emit("MovingState")

func update_animation():
	if unit:
		var anim_name = "idle_%d" % unit.calculate_direction_index(unit.last_move_direction)
		if anim_name != unit.current_animation:
			unit.animated_sprite.play(anim_name)
			unit.current_animation = anim_name
