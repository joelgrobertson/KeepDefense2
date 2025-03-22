extends State
class_name AttackingState

var attack_timer := 0.0
var attack_cooldown := 1.0

func enter():
	if unit:
		print("Entering AttackingState")
		attack_timer = 0.0
		update_animation()

func exit():
	if unit:
		unit.is_attacking = false
		unit.current_target = null

func physics_update(delta):
	if !unit:
		return
		
	if unit.current_target == null or !is_instance_valid(unit.current_target):
		emit_signal("state_transition_requested", "IdleState")
		return
		
	# Check if target is in range
	if unit.global_position.distance_to(unit.current_target.global_position) > unit.get_combat_range():
		# If target moved out of range, transition to MovingState
		unit.target_pos = unit.current_target.global_position
		emit_signal("state_transition_requested", "MovingState")
		return
	
	# Face the target
	var direction = (unit.current_target.global_position - unit.global_position).normalized()
	unit.last_move_direction = direction
	update_animation()
	
	# Attack on cooldown
	attack_timer += delta
	if attack_timer >= attack_cooldown:
		perform_attack()
		attack_timer = 0.0

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
