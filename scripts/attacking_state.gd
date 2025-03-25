# attacking_state.gd
class_name AttackingState
extends State

func enter():
	if unit:
		print(unit.name, " Entering AttackingState with ", unit.current_target.name if unit.current_target else "no target")
		unit.attack_timer = 0.0

func exit():
	if unit:
		unit.is_attacking = false
		unit.current_target = null

func physics_update(delta):
	# Check if target still exists
	if !unit or !unit.current_target or !is_instance_valid(unit.current_target):
		state_transition_requested.emit("IdleState")
		return
		
	# Get distance to target
	var distance = unit.global_position.distance_to(unit.current_target.global_position)
	
	# If we're in attack range, stop and attack
	if distance <= unit.get_combat_range():
		# Stop movement
		unit.velocity = Vector2.ZERO
		
		# Face the target
		unit.last_move_direction = (unit.current_target.global_position - unit.global_position).normalized()
		
		# Attack if cooldown expired
		unit.attack_timer += delta
		if unit.attack_timer >= unit.attack_cooldown:
			perform_attack()
			unit.attack_timer = 0.0
			
		# Update idle animation when not attacking
		if unit.animated_sprite.animation.find("attack_") == -1:
			unit.play_idle_animation()
	else:
		# Target moved out of range - pursue
		unit.nav_agent.target_position = unit.current_target.global_position
		
		# Get next path position
		var next_position = unit.nav_agent.get_next_path_position()
		var direction = (next_position - unit.global_position).normalized()
		
		# Set velocity
		unit.velocity = direction * unit.speed
		unit.move_and_slide()
		
		# Update walking animation
		unit.play_walk_animation()

func perform_attack():
	if !unit or !unit.current_target or !is_instance_valid(unit.current_target):
		return
		
	# Print debug info
	print(unit.name, " attacking ", unit.current_target.name, " at distance: ", 
		  unit.global_position.distance_to(unit.current_target.global_position))
	
	# Play attack animation
	unit.play_attack_animation()
	
	# Deal damage
	if unit.current_target.has_method("take_damage"):
		print(unit.name, " dealing ", unit.attack_damage, " damage to ", unit.current_target.name)
		unit.current_target.take_damage(unit.attack_damage)
