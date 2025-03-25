class_name AttackingState
extends State

var attack_range_reached := false

func enter():
	if unit:
		# Check if target already has too many attackers
		if unit.current_target is Combatant:
			if not unit.current_target.register_attacker(unit):
				# Target has too many attackers, find another target
				var alternative_target = find_alternative_target()
				if alternative_target:
					unit.current_target = alternative_target
					unit.current_target.register_attacker(unit)
				else:
					# No alternative, go back to previous state
					state_transition_requested.emit("IdleState")
					return
					
		print(unit.name, " Entering AttackingState with ", unit.current_target.name if unit.current_target else "no target")
		
		# Start with partial cooldown for quicker first attack
		if unit.attack_timer == 0.0:
			unit.attack_timer = unit.attack_cooldown * 0.75
		
		attack_range_reached = false
		
		# Immediately check if we're in range and can start attacking
		if unit.current_target and is_instance_valid(unit.current_target):
			var distance = unit.global_position.distance_to(unit.current_target.global_position)
			if distance <= unit.get_combat_range():
				attack_range_reached = true
				
				# Face the target
				unit.last_move_direction = (unit.current_target.global_position - unit.global_position).normalized()
				
				# Force an attack animation right away
				if unit.attack_timer >= unit.attack_cooldown:
					perform_attack()
					unit.attack_timer = 0.0
				else:
					# At least play idle animation facing target
					unit.play_idle_animation()
					
func find_alternative_target():
	# Find enemies with fewer than max attackers nearby
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest_available = null
	var closest_distance = 300.0  # Max search distance
	
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.is_dying and enemy.current_attackers.size() < enemy.max_attackers:
			var distance = unit.global_position.distance_to(enemy.global_position)
			if distance < closest_distance:
				closest_available = enemy
				closest_distance = distance
				
	return closest_available

func exit():
	if unit:
		pass  # Unit will handle combat state

func physics_update(delta):
	# Check if we ourselves are dying
	if !unit or unit.is_dying:
		return  # Don't do anything if we're dying
	
	# Check if target is still valid
	if !unit.current_target or !is_instance_valid(unit.current_target):
		unit.end_combat()
		return
		
	# Check if target is dying
	if unit.current_target is Combatant and unit.current_target.is_dying:
		unit.end_combat()
		return
		
	# Get distance to target
	var distance = unit.global_position.distance_to(unit.current_target.global_position)
	
	# If we're in attack range, stop and attack
	if distance <= unit.get_combat_range():
		attack_range_reached = true
		
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
		# If target moved out of range
		if attack_range_reached:
			# If we were in range before but now we're not, 
			# check if we should pursue or stop attacking
			if unit is Enemy and unit.current_target is Unit:
				# If target is >2x attack range away, give up and go to castle
				if distance > unit.get_combat_range() * 2:
					unit.end_combat()
					return
		
		# Set movement toward target
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
		
	# Extra check to make sure target isn't dying
	if unit.current_target is Combatant and unit.current_target.is_dying:
		unit.end_combat()
		return
		
	# Play attack animation
	unit.play_attack_animation()
	
	# Deal damage
	if unit.current_target.has_method("take_damage"):
		print(unit.name, " dealing ", unit.attack_damage, " damage to ", unit.current_target.name)
		unit.current_target.take_damage(unit.attack_damage)
