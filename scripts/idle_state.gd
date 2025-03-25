# idle_state.gd
class_name IdleState
extends State

func enter():
	if unit:
		print(unit.name, " entering IdleState")
		
		# Ensure unit is completely stopped
		unit.velocity = Vector2.ZERO
		
		# Force a complete stop
		if unit.has_method("force_stop"):
			unit.force_stop()

func physics_update(delta):
	# Force velocity to zero every frame in idle
	if unit:
		unit.velocity = Vector2.ZERO
		unit.play_idle_animation()
