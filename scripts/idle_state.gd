# idle_state.gd
class_name IdleState
extends State

func enter():
	print(unit.name, " entering IdleState")

func physics_update(delta):
	unit.play_idle_animation()
