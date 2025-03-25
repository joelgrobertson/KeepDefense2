# Enemy.gd
class_name Enemy
extends Combatant

func _ready():
	super._ready()
	
	# Add to groups
	add_to_group("enemies")
	$CombatArea.add_to_group("enemy_combat_areas")
	$CombatArea.add_to_group("combat_areas")
	
	# Wait a bit before targeting castle
	await get_tree().create_timer(0.2).timeout
	target_castle()

# Basic castle targeting
func target_castle():
	if is_attacking or current_target != null:
		return
		
	var castle = get_tree().get_first_node_in_group("castle")
	if castle and is_instance_valid(castle):
		nav_agent.target_position = castle.global_position
		state_machine.current_state.state_transition_requested.emit("MovingState")

# Combat area detection - THIS IS CRITICAL
func _on_combat_area_area_entered(area: Area2D):
	print(name, " detected area: ", area.name, " in groups: ", area.get_groups())
	
	# Skip if already in combat
	if is_attacking:
		return
		
	# Check for units to attack
	if area.is_in_group("unit_combat_areas"):
		var unit_node = area.get_parent()
		if unit_node and is_instance_valid(unit_node):
			print(name, " engaging unit: ", unit_node.name)
			start_combat(unit_node)
	# Only check for castle if we didn't find a unit
	elif area.is_in_group("castle"):
		var castle = area.get_parent()
		if castle and is_instance_valid(castle):
			print(name, " engaging castle!")
			start_combat(castle)

# Make sure we're checking for nearby units
func _physics_process(delta):
	# If already fighting, skip
	if is_attacking or current_target != null:
		return
		
	# If not, check for any nearby units before continuing to castle
	var units = get_tree().get_nodes_in_group("units")
	var closest_unit = null
	var closest_distance = 999999.0
	
	for unit in units:
		if is_instance_valid(unit):
			var distance = global_position.distance_to(unit.global_position)
			if distance < closest_distance and distance <= get_combat_range():
				closest_unit = unit
				closest_distance = distance
	
	# If we found a unit in range, attack it
	if closest_unit:
		print(name, " found nearby unit: ", closest_unit.name)
		start_combat(closest_unit)
	# Otherwise, keep heading to castle if not already
	elif state_machine.current_state.name != "MovingState":
		target_castle()
