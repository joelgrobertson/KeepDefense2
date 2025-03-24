extends CharacterBody2D
class_name Unit

@onready var animated_sprite = $AnimatedSprite2D
@onready var nav_agent = $NavigationAgent2D
@onready var state_machine = $StateMachine

@export var speed: float = 80.0
@export var health: float = 100.0
@export var attack_damage: float = 10.0
@export var attack_cooldown: float = 1.0

var target_pos := Vector2.ZERO
var current_animation := ""
var last_move_direction: Vector2 = Vector2(0, 1)
var is_attacking := false
var current_target = null

var is_selected := false:
	set(value):
		if is_selected == value:
			return
		is_selected = value
		$SelectionHighlight.visible = value

func _ready():
	print(name, " initialized")
	add_to_group("units")
	$CombatArea.add_to_group("unit_combat_areas")
	$CombatArea.add_to_group("combat_areas")
	state_machine.init(self)
	
	nav_agent.velocity_computed.connect(_on_velocity_computed)
	
# This function will be called when the NavigationAgent computes a new avoidance velocity
func _on_velocity_computed(safe_velocity: Vector2):
	velocity = safe_velocity
	move_and_slide()
	
# Get combat range
func get_combat_range() -> float:
	return $CombatArea/CollisionShape2D.shape.radius

func _on_combat_area_area_entered(area: Area2D):
	if is_attacking:
		return
		
	# Check if area is a combat area
	if !area.is_in_group("combat_areas"):
		return
		
	# If it's a unit combat area, ignore it
	if area.is_in_group("unit_combat_areas"):
		return
		
	# If it's an enemy combat area, engage with the enemy
	if area.is_in_group("enemy_combat_areas"):
		var enemy = area.get_parent()
		print(name, " starting combat with enemy: ", enemy.name)
		start_combat(enemy)

func start_combat(target):
	if !is_attacking:
		current_target = target
		is_attacking = true
		state_machine.current_state.state_transition_requested.emit("AttackingState")

# Set a new movement target and transition to moving state
func set_movement_target(pos: Vector2):
	nav_agent.target_position = pos
	state_machine.current_state.state_transition_requested.emit("MovingState")

# Convert a direction vector to a directional index for animations (0-15)
func calculate_direction_index(direction: Vector2) -> int:
	var angle_rad = atan2(direction.y, direction.x)
	var angle_deg = rad_to_deg(angle_rad)
	angle_deg += 90
	return wrapi(int(round(angle_deg / 22.5)), 0, 16)
