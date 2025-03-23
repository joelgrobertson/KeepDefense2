# Enemy.gd
extends CharacterBody2D
class_name Enemy

@onready var animated_sprite = $AnimatedSprite2D
@onready var nav_agent = $NavigationAgent2D
@onready var state_machine = $StateMachine
@onready var combat_area = $CombatArea/CollisionShape2D

@export var speed: float = 80.0
@export var health: float = 100.0
@export var attack_damage: float = 10.0
@export var attack_cooldown: float = 1.0

var target_pos := Vector2.ZERO
var target = null
var current_animation := ""
var last_move_direction: Vector2 = Vector2(0, 1)
var is_attacking := false
var current_target = null

func _ready():
	print(name, " initialized")
	state_machine.init(self)
	
	# Find the castle automatically
	target = get_tree().get_first_node_in_group("castle")
	if target:
		# Set initial target position
		target_pos = target.global_position
		
	nav_agent.velocity_computed.connect(_on_velocity_computed)
	
# This function will be called when the NavigationAgent computes a new avoidance velocity
func _on_velocity_computed(safe_velocity: Vector2):
	velocity = safe_velocity
	move_and_slide()

# Called when the enemy gets hit
func take_damage(amount: float):
	health -= amount
	print(name, " took damage: ", amount, ", remaining health: ", health)
	
	if health <= 0:
		print(name, " destroyed!")
		queue_free()

# Convert a direction vector to a directional index for animations (0-15)
func calculate_direction_index(direction: Vector2) -> int:
	var angle_rad = atan2(direction.y, direction.x)
	var angle_deg = rad_to_deg(angle_rad)
	angle_deg += 90
	return wrapi(int(round(angle_deg / 22.5)), 0, 16)

# Get combat range
func get_combat_range() -> float:
	return combat_area.shape.radius * max(combat_area.scale.x, combat_area.scale.y)

# Called when enemy enters combat with another entity
func _on_combat_area_body_entered(body):
	if is_attacking:
		return
		
	if body.is_in_group("units"):
		start_combat(body)
		
func _on_combat_area_area_entered(area):
	if is_attacking:
		return
		
	if area.is_in_group("castle"):
		start_combat(area.get_parent())

# Start combat with a target
func start_combat(target):
	if !is_attacking:
		current_target = target
		is_attacking = true
		state_machine.current_state.state_transition_requested.emit("AttackingState")
