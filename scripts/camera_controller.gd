extends Camera2D

@export var zoomSpeed : float = 80
@export var min_zoom: float = 0.5
@export var max_zoom: float = 3.5

var zoomTarget :Vector2

var dragStartMousePos = Vector2.ZERO
var dragStartCameraPos = Vector2.ZERO
var isDragging : bool = false

func _ready():
	zoomTarget = zoom
	
func _process(delta):
	Zoom(delta)
	SimplePan(delta)
	CameraDrag()
	
func Zoom(delta):
	if Input.is_action_just_pressed("camera_zoom_in"):
		zoomTarget = (zoom * 1.1).clamp(Vector2.ONE * min_zoom, Vector2.ONE * max_zoom)
	if Input.is_action_just_pressed("camera_zoom_out"):
		zoomTarget = (zoom * 0.9).clamp(Vector2.ONE * min_zoom, Vector2.ONE * max_zoom)
		
	zoom = zoom.slerp(zoomTarget, zoomSpeed * delta)
	
func SimplePan(delta):
	var input = Input.get_vector("camera_move_left", "camera_move_right","camera_move_up", "camera_move_down")
	position += input.normalized() * delta * 1000 * (1/zoom.x)
	
func CameraDrag():
	if !isDragging and Input.is_action_just_pressed("camera_drag"):
		dragStartMousePos = get_viewport().get_mouse_position()
		dragStartCameraPos = position
		isDragging = true
		
	if isDragging and Input.is_action_just_released("camera_drag"):
		isDragging = false
		
	if isDragging:
		var moveVector = get_viewport().get_mouse_position() - dragStartMousePos
		position = dragStartCameraPos - moveVector * (1/zoom.x)
