extends State
class_name IdleState

func enter():
	print(unit.name, " entering IdleState")

func physics_update(delta):
	update_animation()

func update_animation():
	var anim_name = "idle_%d" % unit.calculate_direction_index(unit.last_move_direction)
	if anim_name != unit.current_animation:
		unit.animated_sprite.play(anim_name)
		unit.current_animation = anim_name
