# Unit.gd
class_name Unit
extends Combatant


var is_selected := false:
	set(value):
		if is_selected == value:
			return
		is_selected = value
		$SelectionHighlight.visible = value

func _ready():
	super._ready()
	
	# Add to groups
	add_to_group("units")
	$CombatArea.add_to_group("unit_combat_areas")
	
	# Enable health regeneration for units
	self.can_regenerate = true
	self.regen_rate = 1.0  # Adjust as needed
	self.regen_cooldown = 2.0  # Wait 3 seconds after combat before healing

# Combat area detection for units
func _on_combat_area_area_entered(area: Area2D):
	if is_attacking or is_dying:
		return  # Skip if already in combat or dying
		
	# Check if this is an enemy's combat area
	if area.is_in_group("enemy_combat_areas"):
		var enemy = area.get_parent()
		if enemy and is_instance_valid(enemy) and !enemy.is_dying:
			print(name, " detected enemy: ", enemy.name)
			start_combat(enemy)

# Counterattack when damaged
func take_damage(amount: float):
	# Call parent implementation first (which handles health bar, etc.)
	super.take_damage(amount)
	
	# If we survived and aren't already attacking, counterattack
	if !is_dying and !is_attacking and health > 0:
		var attacker = find_closest_enemy_in_range()
		if attacker:
			print(name, " counterattacking: ", attacker.name)
			start_combat(attacker)

# Find the closest enemy in combat range
func find_closest_enemy_in_range():
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest_enemy = null
	var closest_distance = get_combat_range() * 1.5  # Slightly extended range for counterattacks
	
	for enemy in enemies:
		if is_instance_valid(enemy) and !enemy.is_dying:
			var distance = global_position.distance_to(enemy.global_position)
			if distance < closest_distance:
				closest_enemy = enemy
				closest_distance = distance
				
	return closest_enemy
