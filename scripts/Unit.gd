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
	$CombatArea.add_to_group("combat_areas")

# Combat area detection for units
func _on_combat_area_area_entered(area: Area2D):
	if is_attacking:
		return
		
	if area.is_in_group("enemy_combat_areas"):
		var enemy = area.get_parent()
		if enemy and is_instance_valid(enemy):
			print(name, " engaging enemy: ", enemy.name)
			start_combat(enemy)

# Counterattack when damaged
func take_damage(amount: float):
	health -= amount
	print(name, " took damage: ", amount, ", health: ", health)
	
	# Counterattack if not already attacking
	if !is_attacking and health > 0:
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
			print(name, " counterattacking: ", closest_enemy.name)
			start_combat(closest_enemy)
	
	if health <= 0:
		queue_free()
