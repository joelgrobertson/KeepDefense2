# death_state.gd
class_name DeathState
extends State

func enter():
	if unit:
		print(unit.name, " entering death state")
		
		# Remove from selection if selected
		if unit is Unit and unit.is_selected:
			unit.is_selected = false
			var unit_manager = get_tree().get_first_node_in_group("unit_manager") 
			if unit_manager:
				unit_manager.selected_units.erase(unit)
				
				# Remove from groups
		if unit.is_in_group("units"):
			unit.remove_from_group("units")
		elif unit.is_in_group("enemies"):
			unit.remove_from_group("enemies")
		
		# Hide health bar
		unit.health_bar.visible = false
		
		# Disable all collisions
		unit.get_node("CollisionShape2D").set_deferred("disabled", true)
		if unit.combat_area:
			unit.combat_area.set_deferred("monitoring", false)
			unit.combat_area.set_deferred("monitorable", false)
		
		# Clear combat relationships
		if unit.current_target and is_instance_valid(unit.current_target) and unit.current_target is Combatant:
			unit.current_target.handle_target_death(unit)
			
		# Clear any registered attackers
		unit.clear_attackers()
		
		# End combat state
		unit.current_target = null
		unit.is_attacking = false
		
		# Play death animation
		var anim_name = "death_%d" % unit.calculate_direction_index(unit.last_move_direction)
		unit.animated_sprite.animation = anim_name
		unit.animated_sprite.stop()
		unit.animated_sprite.frame = 0
		unit.animated_sprite.play()
		
		# Wait for animation and corpse delay
		await unit.animated_sprite.animation_finished
		await get_tree().create_timer(15).timeout
		

			
		# Remove from scene
		unit.queue_free()

func physics_update(_delta):
	# No physics updates in death state
	pass
