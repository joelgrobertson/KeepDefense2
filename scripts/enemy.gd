# Enemy.gd
extends CharacterBody2D


@onready var animated_sprite = $AnimatedSprite2D
@onready var nav_agent = $NavigationAgent2D
@onready var state_machine = $StateMachine
@onready var combat_area = $CombatArea

@export var speed: float = 80.0
@export var health: float = 100.0
@export var attack_damage: float = 10.0
@export var attack_cooldown: float = 1.0

var target_pos := Vector2.ZERO
var current_animation := ""
var last_move_direction: Vector2 = Vector2(0, 1)
var is_attacking := false
var current_target = null

func _ready():
	print(name, " initialized")
	
	# Add to appropriate groups
	add_to_group("enemies")
	$CombatArea.add_to_group("enemy_combat_areas")
	$CombatArea.add_to_group("combat_areas")
	
	# Initialize the state machine
	state_machine.init(self)
	
	# Find the castle automatically
	var castle = get_tree().get_first_node_in_group("castle")
	if castle:
		# Set initial target position
		target_pos = castle.global_position
		# Set initial navigation target
		nav_agent.target_position = target_pos
		
		# Explicitly start in moving state (wait one frame for state machine setup)
		await get_tree().process_frame
		state_machine.current_state.state_transition_requested.emit("MovingState")
	else:
		print("ERROR: No castle found for enemy to target!")
		
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
	return $CombatArea/CollisionShape2D.shape.radius

# Physics process for updating enemy behavior
func _physics_process(delta):
	# If not attacking, update the target position if needed
	if !is_attacking:
		var castle = get_tree().get_first_node_in_group("castle")
		if castle and is_instance_valid(castle):
			# Only update if significantly changed
			if castle.global_position.distance_to(target_pos) > 10:
				target_pos = castle.global_position
				nav_agent.target_position = target_pos

# Called when enemy's combat area enters another combat area
func _on_combat_area_area_entered(area: Area2D):
	if is_attacking:
		return
		
	# Check if area is a combat area
	if !area.is_in_group("combat_areas"):
		return
		
	# If it's an enemy combat area, ignore it
	if area.is_in_group("enemy_combat_areas"):
		return
		
	# If it's a unit combat area, engage with the unit
	if area.is_in_group("unit_combat_areas"):
		var unit = area.get_parent()
		print(name, " starting combat with unit: ", unit.name)
		start_combat(unit)
	
	# If it's the castle, engage with the castle
	elif area.is_in_group("castle"):
		var castle = area.get_parent()
		print(name, " starting combat with castle!")
		start_combat(castle)

# Start combat with a target
func start_combat(target):
	if !is_attacking:
		current_target = target
		is_attacking = true
		state_machine.current_state.state_transition_requested.emit("AttackingState")
