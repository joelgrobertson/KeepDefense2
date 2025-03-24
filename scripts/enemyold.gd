extends Combatant


@export var speed := 75.0
var target_pos := Vector2.ZERO
var target: Area2D
var last_move_direction := Vector2.DOWN

func _ready():
	# Find the castle automatically
	target = get_tree().get_first_node_in_group("combat_areas")
	if !target:
		target = get_tree().get_first_node_in_group("units")

func _physics_process(delta):
	if !is_attacking:
		if target and is_instance_valid(target):
			# Update target to castle's current position
			target_pos = target.global_position
			var direction = (target_pos - global_position).normalized()
			last_move_direction = direction
			
			# Movement
			velocity = direction * speed
			move_and_slide()
			
			# Animation
			update_animations()
	else:
		velocity = Vector2.ZERO
		
# Add area entered handler
func _on_combat_area_area_entered(area: Area2D):
	if is_attacking: 
		return
	
	if area.is_in_group("castle"):
		start_combat(area.get_parent()) # Assuming Castle is parent of Area2D

# Rename existing body entered handler
func _on_combat_area_body_entered(body: Node):
	if is_attacking: 
		return
	
	if body.is_in_group("units"):
		start_combat(body)


func update_animations():
	var angle_rad = atan2(last_move_direction.x, -last_move_direction.y)
	var angle_deg = rad_to_deg(angle_rad)
	if angle_deg < 0: angle_deg += 360
	var index = wrapi(int(round(angle_deg / 22.5)), 0, 16)
	$AnimatedSprite2D.play("walk_%d" % index)
