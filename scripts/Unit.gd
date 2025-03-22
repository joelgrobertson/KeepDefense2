extends CharacterBody2D
class_name Unit

@onready var animated_sprite = $AnimatedSprite2D
@onready var nav_agent = $NavigationAgent2D
@onready var state_machine = $StateMachine
@onready var selection_highlight = $SelectionHighlight

@export var speed: float = 115.0

var target_pos = Vector2.ZERO
var current_animation := ""
var last_move_direction: Vector2 = Vector2(0, 1)

var is_selected := false:
	set(value):
		if is_selected == value:
			return
		is_selected = value
		selection_highlight.visible = value

func _ready():
	print(name, " initialized")
	state_machine.init(self)
	target_pos = global_position

# Set a new movement target and transition to moving state
func set_movement_target(pos: Vector2):
	target_pos = pos
	nav_agent.target_position = pos
	state_machine.current_state.state_transition_requested.emit("MovingState")

# Convert a direction vector to a directional index for animations (0-15)
func calculate_direction_index(direction: Vector2) -> int:
	var angle_rad = atan2(direction.y, direction.x)
	var angle_deg = rad_to_deg(angle_rad)
	angle_deg += 90
	return wrapi(int(round(angle_deg / 22.5)), 0, 16)
