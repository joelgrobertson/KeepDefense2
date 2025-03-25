# Enemy.gd
class_name Enemy
extends Combatant

var in_unit_combat := false  # Track if fighting a unit

func _ready():
	super._ready()
	
	# Add to groups
	add_to_group("enemies")
	$CombatArea.add_to_group("enemy_combat_areas")
	
	# Wait a bit before targeting castle
	await get_tree().create_timer(0.2).timeout
	target_castle()

# Basic castle targeting
func target_castle():
	if is_attacking or is_dying:
		return
		
	var castle = get_tree().get_first_node_in_group("castle")
	if castle and is_instance_valid(castle):
		nav_agent.target_position = castle.global_position
		state_machine.current_state.state_transition_requested.emit("MovingState")

# Combat area detection
func _on_combat_area_area_entered(area: Area2D):
	# Skip if already in combat or dying
	if is_attacking or is_dying:
		return
		
	# Check for units to attack
	if area.is_in_group("unit_combat_areas"):
		var unit = area.get_parent()
		if unit and is_instance_valid(unit) and !unit.is_dying:
			# Check if unit is already in combat with another enemy
			if should_attack_unit(unit):
				print(name, " engaging unit: ", unit.name)
				in_unit_combat = true
				start_combat(unit)
	
	# Only check for castle if we didn't find a unit to attack
	elif area.is_in_group("castle") and !in_unit_combat:
		var castle = area.get_parent()
		if castle and is_instance_valid(castle):
			print(name, " engaging castle!")
			start_combat(castle)

# Decide whether to attack a unit based on its status
func should_attack_unit(unit):
	# If the unit is already in combat with another enemy,
	# have a % chance to skip this unit and continue to castle
	if unit.is_attacking and unit.current_target is Enemy and unit.current_target != self:
		# 70% chance to bypass unit and head to castle
		return randf() < 0.3
	
	# Otherwise, definitely attack this unit
	return true

# Override end_combat to reset unit combat flag and go back to castle
func end_combat():
	is_attacking = false
	current_target = null
	in_unit_combat = false
	
	# Back to castle if we're still alive
	if !is_dying:
		target_castle()
