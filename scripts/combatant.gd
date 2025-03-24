# Combatant.gd
class_name Combatant
extends CharacterBody2D

@export var health := 100.0
@export var attack_damage := 10.0
@export var attack_cooldown := 1.0
@export var speed := 80.0

# Common properties
var current_target = null
var is_attacking := false
var last_move_direction := Vector2.DOWN
var current_animation := ""
var attack_timer := 0.0

# References
@onready var animated_sprite = $AnimatedSprite2D
@onready var nav_agent = $NavigationAgent2D
@onready var state_machine = $StateMachine

func _ready():
	# Initialize the state machine with self-reference
	state_machine.init(self)
	
	# Connect navigation signals
	nav_agent.velocity_computed.connect(_on_velocity_computed)

# Handle taking damage
func take_damage(amount: float):
	health -= amount
	print(name, " took damage: ", amount, ", health: ", health)
	
	if health <= 0:
		queue_free()

# Calculate direction for animations
func calculate_direction_index(direction: Vector2) -> int:
	var angle_rad = atan2(direction.y, direction.x)
	var angle_deg = rad_to_deg(angle_rad)
	angle_deg += 90
	return wrapi(int(round(angle_deg / 22.5)), 0, 16)

# Get combat range
func get_combat_range() -> float:
	return $CombatArea/CollisionShape2D.shape.radius

# Start combat with a target
func start_combat(target):
	if !is_attacking:
		print(name, " starting combat with ", target.name)
		current_target = target
		is_attacking = true
		# Force state change
		if state_machine:
			state_machine.current_state.state_transition_requested.emit("AttackingState")

# Navigation callback
func _on_velocity_computed(safe_velocity: Vector2):
	velocity = safe_velocity
	move_and_slide()
	
func set_movement_target(pos: Vector2):
	nav_agent.target_position = pos
	state_machine.current_state.state_transition_requested.emit("MovingState")

# Helper functions for animations
func play_attack_animation():
	var anim_name = "attack_%d" % calculate_direction_index(last_move_direction)
	if anim_name != current_animation:
		animated_sprite.play(anim_name)
		current_animation = anim_name

func play_idle_animation():
	var anim_name = "idle_%d" % calculate_direction_index(last_move_direction)
	if anim_name != current_animation:
		animated_sprite.play(anim_name)
		current_animation = anim_name

func play_walk_animation():
	var anim_name = "walk_%d" % calculate_direction_index(last_move_direction)
	if anim_name != current_animation:
		animated_sprite.play(anim_name)
		current_animation = anim_name
