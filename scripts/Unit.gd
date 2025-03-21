extends CharacterBody2D
class_name Unit

@export var speed := 150.0
@export var acceleration := 8.0
var last_move_direction := Vector2.DOWN
var current_animation := ""
var target_pos := Vector2.ZERO
var movement_direction := Vector2.ZERO
var is_selected := false :
	set(value):
		is_selected = value
		$SelectionHighlight.visible = value

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var state_machine = $StateMachine

func _ready():
	state_machine.init(self)
	target_pos = global_position
	print("Unit initialized at: ", global_position)

func _physics_process(delta):
	if state_machine:
		state_machine._physics_process(delta)

# Animation System
func calculate_direction_index(direction: Vector2) -> int:
	var angle_rad = atan2(direction.x, -direction.y)
	var angle_deg = rad_to_deg(angle_rad)
	if angle_deg < 0: angle_deg += 360
	return wrapi(int(round(angle_deg / 22.5)), 0, 16)

		
func _draw():
	if Engine.is_editor_hint():
		return

	# Draw movement target
	#draw_circle(target_pos - global_position, 5, Color.RED)
	
	# Draw movement line
	#draw_line(Vector2.ZERO, target_pos - global_position, Color.YELLOW, 2)
	
	# Draw velocity
	#draw_line(Vector2.ZERO, velocity.normalized() * 20, Color.GREEN, 2)
