extends ColorRect

var drag_start := Vector2.ZERO
var is_dragging := false

func start_drag(pos: Vector2):
	drag_start = pos
	position = pos
	size = Vector2.ZERO
	show()
	is_dragging = true

func _process(delta):
	if is_dragging:
		var current_pos = get_viewport().get_mouse_position()
		position = Vector2(min(drag_start.x, current_pos.x), min(drag_start.y, current_pos.y))
		size = Vector2(abs(current_pos.x - drag_start.x), abs(current_pos.y - drag_start.y))

func get_selection_rect() -> Rect2:
	return Rect2(position, size)
