# Unit.gd
class_name Unit
extends Combatant

var is_selected := false:
	set(value):
		if is_selected == value:
			return
		is_selected = value
		$SelectionHighlight.visible = value

var pushed_timer := 0.0  # Track if we're being pushed back
var push_threshold := 0.5  # How long before we counterattack if pushed

func _ready():
	super._ready()
	
	# Add to groups
	add_to_group("units")
	$CombatArea.add_to_group("unit_combat_areas")
	$CombatArea.add_to_group("combat_areas")
	
	# Connect the area_entered signal
	$CombatArea.connect("area_entered", _on_combat_area_area_entered)

# Process function to detect being pushed
func _physics_process(delta):
	# If we're not in combat but being pushed, track it
	if !is_attacking and velocity.length() > 0.1:
		pushed_timer += delta
		
		# If we've been pushed for too long, look for enemies
		if pushed_timer > push_threshold:
			pushed_timer = 0.0
			find_and_attack_nearest_enemy()
	else:
		pushed_timer = 0.0

# Find and attack the nearest enemy
func find_and_attack_nearest_enemy():
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest_enemy = null
	var closest_distance = 999999.0
	
	for enemy in enemies:
		if is_instance_valid(enemy):
			var distance = global_position.distance_to(enemy.global_position)
			if distance < closest_distance and distance <= get_combat_range() * 1.5:
				closest_enemy = enemy
				closest_distance = distance
				
	if closest_enemy:
		print(name, " found nearby enemy: ", closest_enemy.name)
		engage_target(closest_enemy)

# Handle combat area detection
func _on_combat_area_area_entered(area: Area2D):
	print(name, " detected area: ", area.name, " in group: ", area.get_groups())
	
	if is_attacking:
		return
		
	if area.is_in_group("enemy_combat_areas"):
		var enemy = area.get_parent()
		if enemy and is_instance_valid(enemy):
			print(name, " engaging enemy: ", enemy.name)
			engage_target(enemy)

# Better take_damage with immediate response
func take_damage(amount: float):
	health -= amount
	print(name, " took damage: ", amount, ", health: ", health)
	
	# Always reset pushed timer when taking damage
	pushed_timer = 0.0
	
	# If we're not already attacking something, counterattack
	if !is_attacking and health > 0:
		# Find who attacked us
		find_and_attack_nearest_enemy()
	
	if health <= 0:
		queue_free()

# Simple combat engagement
func engage_target(target):
	if target and is_instance_valid(target):
		current_target = target
		is_attacking = true
		# Force immediate state change - bypass normal transitions
		if state_machine and state_machine.current_state:
			state_machine.current_state.exit()
			state_machine._on_state_transition("AttackingState")
