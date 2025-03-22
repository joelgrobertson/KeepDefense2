extends CharacterBody2D
class_name Unit

@export var speed: float = 55.0

var target_pos = Vector2.ZERO
var current_animation := ""
var last_move_direction: Vector2 = Vector2(0,1)

@onready var animated_sprite = $AnimatedSprite2D
@onready var nav_agent = $NavigationAgent2D
@onready var state_machine = $StateMachine

func _ready():
	# Initialize the state machine
	state_machine.init(self)
	target_pos = global_position
	
	print(name, " initialized at: ", global_position)

func _physics_process(delta):
	# Movement is handled by states
	move_and_slide()

var is_selected := false :
	set(value):
		is_selected = value
		$SelectionHighlight.visible = value
	
func deselect():
	is_selected = false
	if has_node("SelectionIndicator"):
		$SelectionIndicator.hide()

func set_movement_target(pos: Vector2):
	print(name, ": Setting movement target to ", pos)
	target_pos = pos

	nav_agent.target_position = pos
	
	
	# Force state transition if needed
	if state_machine.current_state is IdleState:
		print("Requesting transition from IdleState to MovingState")
		state_machine.current_state.state_transition_requested.emit("MovingState")
	else:
		print("Not in IdleState, current state: ", state_machine.current_state.get_class())
	
	# Verify target was set
	print("Navigation target is now: ", nav_agent.target_position)

# Convert a direction vector to a directional index (0-15)
func calculate_direction_index(direction: Vector2) -> int:
	# Standard angle calculation - no need to invert y
	var angle_rad = atan2(direction.y, direction.x)
	var angle_deg = rad_to_deg(angle_rad)
	
	# Adjust angle to match your sprite orientations
	# This rotates everything by 90 degrees to align with your animations
	angle_deg += 90
	
	# Keep angle in the 0-360 range
	if angle_deg < 0: 
		angle_deg += 360
	
	# Map to 16 directions (0 to 15)
	return wrapi(int(round(angle_deg / 22.5)), 0, 16)
