extends State
class_name AttackingState

var attack_timer := 0.0
var attack_cooldown := 1.0

func enter():
	if unit:
		print(unit.name, " Entering AttackingState with ", unit.current_target.name)
		attack_timer = 1.5

func exit():
	if unit:
		unit.is_attacking = false
		unit.current_target = null

func physics_update(delta):
		
	if unit.current_target == null or !is_instance_valid(unit.current_target):
		state_transition_requested.emit("IdleState")
		return
		
 # Get distance to target
	var distance = unit.global_position.distance_to(unit.current_target.global_position)
	
	# If we're in attack range, stop and attack
	if distance <= unit.get_combat_range():
		# Completely stop movement
		unit.velocity = Vector2.ZERO
		
		# Face the target
		var direction = (unit.current_target.global_position - unit.global_position).normalized()
		unit.last_move_direction = direction
		
		# Attack if cooldown expired
		attack_timer += delta
		if attack_timer >= unit.attack_cooldown:
			perform_attack()
			attack_timer = 0.0
			
		update_animation()
	else:
		# If target moved away, we need to get closer
		unit.nav_agent.target_position = unit.current_target.global_position
		emit_signal("state_transition_requested", "MovingState")

func perform_attack():
	if unit and unit.current_target and is_instance_valid(unit.current_target):
		# Play attack animation
		play_attack_animation()
		
		# Deal damage
		if unit.current_target.has_method("take_damage"):
			unit.current_target.take_damage(unit.attack_damage)

func play_attack_animation():
	if unit:
		var anim_name = "attack_%d" % unit.calculate_direction_index(unit.last_move_direction)
		if anim_name != unit.current_animation:
			unit.animated_sprite.play(anim_name)
			unit.current_animation = anim_name

func update_animation():
	# When not actively attacking, show an idle stance facing the enemy
	if unit and unit.animated_sprite.animation.find("attack_") == -1:
		var anim_name = "idle_%d" % unit.calculate_direction_index(unit.last_move_direction)
		if anim_name != unit.current_animation:
			unit.animated_sprite.play(anim_name)
			unit.current_animation = anim_name
