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
var in_combat_movement := false

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

# Configure collision for combat
func configure_collision_for_combat(enable: bool):
	if enable:
		# During combat, ignore collisions with other units/enemies
		# This prevents pushing and jiggling
		collision_mask = collision_mask & ~2  # Remove bit 2 (unit/enemy collision layer)
	else:
		# Normal movement - detect all collisions
		collision_mask = collision_mask | 2   # Add back bit 2
		
		
func configure_navigation_for_combat(enable: bool):
	in_combat_movement = enable
	
	if enable:
		# Configure for combat - disable avoidance
		nav_agent.avoidance_enabled = false
		nav_agent.radius = 2.0  # Smaller radius during combat
	else:
		# Configure for normal movement - enable avoidance
		nav_agent.avoidance_enabled = true
		nav_agent.radius = 12.0  # Normal radius
		
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
