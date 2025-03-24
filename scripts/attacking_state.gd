# attacking_state.gd
class_name AttackingState
extends State

var optimal_distance := 30.0  # Target combat distance
var position_offset := Vector2.ZERO  # Unique offset for each attacker
var position_locked := false  # Once in position, lock it and stop adjusting

func enter():
	if !unit:
		return
		
	if !unit.current_target or !is_instance_valid(unit.current_target):
		state_transition_requested.emit("IdleState")
		return
		
	# Debug info
	print(unit.name, " ATTACKING ", unit.current_target.name)
	
	# Stop movement completely
	unit.velocity = Vector2.ZERO
	
	# Reset position lock
	position_locked = false
	
	# Assign a unique position offset for this attacker
	if unit is Enemy:
		# Generate a random offset angle, but stable for this instance
		var random_angle = hash(unit.get_instance_id()) % 360 * PI / 180.0
		position_offset = Vector2(cos(random_angle), sin(random_angle)) * 20.0

func exit():
	if unit:
		unit.is_attacking = false
		unit.current_target = null

func physics_update(delta):
	if !unit or !unit.current_target or !is_instance_valid(unit.current_target):
		state_transition_requested.emit("IdleState")
		return
	
	# Face target (always)
	unit.last_move_direction = (unit.current_target.global_position - unit.global_position).normalized()
	
	# Get distance to target
	var distance = unit.global_position.distance_to(unit.current_target.global_position)
	
	# If we're in attack range
	if distance <= unit.get_combat_range():
		# If we haven't locked position yet
		if !position_locked:
			# If we're in optimal range, lock position
			if abs(distance - optimal_distance) < 5.0:
				position_locked = true
				unit.velocity = Vector2.ZERO
			# Otherwise adjust position
			else:
				# Too close - back up
				if distance < optimal_distance - 5.0:
					var direction = -unit.last_move_direction
					unit.velocity = direction * unit.speed * 0.3
				# Too far - move closer
				else:
					var direction = unit.last_move_direction
					unit.velocity = direction * unit.speed * 0.3
				
				unit.move_and_slide()
		else:
			# We're locked in position, no more movement
			unit.velocity = Vector2.ZERO
		
		# Attack on cooldown regardless of position
		unit.attack_timer += delta
		if unit.attack_timer >= unit.attack_cooldown:
			perform_attack()
			unit.attack_timer = 0.0
		
		# Update idle animation between attacks
		if unit.animated_sprite.animation.find("attack_") == -1:
			unit.play_idle_animation()
	else:
		# Target moved out of range - unlock position and pursue
		position_locked = false
		
		# Calculate target position with offset for enemies
		var target_pos = unit.current_target.global_position
		if unit is Enemy:
			target_pos += position_offset
			
		unit.nav_agent.target_position = target_pos
		
		# Use navigation system for movement
		var next_pos = unit.nav_agent.get_next_path_position()
		var direction = (next_pos - unit.global_position).normalized()
		var target_velocity = direction * unit.speed
		
		# Use navigation avoidance
		unit.nav_agent.set_velocity(target_velocity)
		
		# Update walking animation
		unit.play_walk_animation()

func perform_attack():
	if !unit or !unit.current_target or !is_instance_valid(unit.current_target):
		return
		
	# Play attack animation
	unit.play_attack_animation()
	
	# Deal damage
	if unit.current_target.has_method("take_damage"):
		print(unit.name, " dealing ", unit.attack_damage, " damage to ", unit.current_target.name)
		unit.current_target.take_damage(unit.attack_damage)
