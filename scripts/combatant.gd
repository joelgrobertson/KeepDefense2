# Combatant.gd (inherited by both Unit and Enemy)
class_name Combatant
extends CharacterBody2D

@export var health := 100.0
@export var attack_damage := 10.0
@export var attack_cooldown := 1.0

var current_target: Node = null
var attack_timer := 0.0
var is_attacking := false

var combat_cooldown := 1.0
var combat_timer := 0.0


func take_damage(amount: float):
	health -= amount
	if health <= 0:
		queue_free()

func _process(delta):
	if is_attacking:
		combat_timer += delta
		if combat_timer >= combat_cooldown:
			if is_instance_valid(current_target) && global_position.distance_to(current_target.global_position) <= get_combat_range():
				perform_attack()
				combat_timer = 0.0
			else:
				end_combat()
				
func get_combat_range() -> float:
	return $CombatArea.shape.radius * max($CombatArea.scale.x, $CombatArea.scale.y)
			
func start_combat(target: Node):
	if !is_attacking or current_target != target:
		is_attacking = true
		current_target = target
		print(name, " started combat with ", target.name)
		
		# Stop movement immediately
		velocity = Vector2.ZERO
		
		if target is Combatant:
			target.start_combat(self)

func perform_attack():
	if is_instance_valid(current_target) and current_target.has_method("take_damage"):
		current_target.take_damage(attack_damage)
		play_attack_animation(current_target.global_position)
	
	# Break combat if target is dead/destroyed
	if !is_instance_valid(current_target):
		end_combat()
		
func end_combat():
	is_attacking = false
	current_target = null
	
	print(name, " ended combat")

func play_attack_animation(target_position: Vector2):
	var direction = (target_position - global_position).normalized()
	var angle_rad = atan2(direction.x, -direction.y)
	var angle_deg = rad_to_deg(angle_rad)
	if angle_deg < 0: angle_deg += 360
	var index = wrapi(int(round(angle_deg / 22.5)), 0, 16)
	$AnimatedSprite2D.play("attack_%d" % index)
