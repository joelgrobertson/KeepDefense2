# Enemy.gd
class_name Enemy
extends Combatant

func _ready():
	super._ready()
	
	# Add to groups
	add_to_group("enemies")
	$CombatArea.add_to_group("enemy_combat_areas")
	$CombatArea.add_to_group("combat_areas")
	
	# Make sure combat area detection is connected
	$CombatArea.connect("area_entered", _on_combat_area_area_entered)
	
	# Wait a bit before targeting castle
	await get_tree().create_timer(0.2).timeout
	target_castle()

# Basic castle targeting
func target_castle():
	# Don't override combat
	if is_attacking or current_target != null:
		return
		
	var castle = get_tree().get_first_node_in_group("castle")
	if castle and is_instance_valid(castle):
		nav_agent.target_position = castle.global_position
		state_machine.current_state.state_transition_requested.emit("MovingState")

# The key issue - this needs to work reliably!
func _on_combat_area_area_entered(area: Area2D):
	# Debug print to verify this gets called
	print(name, " detected area: ", area.name, " in group: ", area.get_groups())
	
	# Skip if already fighting
	if is_attacking:
		return
		
	# Detection logic
	if area.is_in_group("unit_combat_areas"):
		var unit = area.get_parent()
		if unit and is_instance_valid(unit):
			print(name, " engaging unit: ", unit.name)
			engage_target(unit)
	elif area.is_in_group("castle"):
		var castle = area.get_parent()
		if castle and is_instance_valid(castle):
			print(name, " engaging castle!")
			engage_target(castle)

# Better combat engagement with direct state change
func engage_target(target):
	if target and is_instance_valid(target):
		current_target = target
		is_attacking = true
		# Force immediate state change - bypass normal transitions
		if state_machine and state_machine.current_state:
			state_machine.current_state.exit()
			state_machine._on_state_transition("AttackingState")

# Resume castle targeting when we exit combat
func _physics_process(delta):
	# If not in combat, make sure we're heading to the castle
	if !is_attacking and current_target == null:
		if state_machine.current_state.name != "MovingState":
			target_castle()
