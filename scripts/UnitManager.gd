extends Node

@onready var selection_rect = %SelectionRect

var selected_units := []
var is_dragging := false

# Formation parameters
@export var formation_spacing := Vector2(50, 50)  # Space between units
@export var formation_shape := "grid"  # Options: "grid", "line", "wedge"

func get_global_mouse_position() -> Vector2:
	return get_viewport().get_camera_2d().get_global_mouse_position()

func _unhandled_input(event):
	if not event is InputEventMouseButton:
		return
	match event.button_index:
		MOUSE_BUTTON_LEFT:
			handle_left_click(event)
		MOUSE_BUTTON_RIGHT:
			handle_right_click(event)

func handle_left_click(event: InputEventMouseButton):
	if event.pressed:
		start_box_selection(event.position)
	elif is_dragging:
		end_box_selection()

func handle_right_click(event: InputEventMouseButton):
	if event.pressed:
		command_move(selected_units, get_global_mouse_position())
		
func clear_selection():
	for unit in selected_units:
		unit.is_selected = false
	selected_units.clear()

func select_unit(unit: Unit):
	unit.is_selected = true
	selected_units.append(unit)
	print("Selected unit: ", unit.name)

func start_box_selection(mouse_position: Vector2):
	is_dragging = true
	selection_rect.start_drag(mouse_position)

func end_box_selection():
	process_box_selection()
	is_dragging = false
	selection_rect.visible = false
	
func process_box_selection():
	clear_selection()
	
	var camera = get_viewport().get_camera_2d()
	var rect = selection_rect.get_selection_rect()
	var viewport_size = get_viewport().size
	
	# Convert to world coordinates
	var world_start = camera.get_screen_center_position() + (rect.position - Vector2(viewport_size)/2) * camera.zoom
	var world_size = rect.size * camera.zoom
	
	for unit in get_tree().get_nodes_in_group("units"):
		if Rect2(world_start, world_size).has_point(unit.global_position):
			select_unit(unit)
			
func calculate_formation_positions(count: int, center: Vector2) -> Array[Vector2]:
	var positions = []
	match formation_shape:
		"grid":
			positions = calculate_grid_formation(count, center)
		"line":
			positions = calculate_line_formation(count, center)
		"wedge":
			positions = calculate_wedge_formation(count, center)
		_:
			push_error("Unknown formation shape: ", formation_shape)
	return positions

func calculate_grid_formation(count: int, center: Vector2) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var rows = ceil(sqrt(count))
	var cols = ceil(float(count) / rows)
	
	# Convert cols to int for modulo operation
	var int_cols = int(cols)
	
	for i in count:
		var row = i / int_cols  # Integer division
		var col = i % int_cols  # Modulo operation
		var offset = Vector2(
			(col - (int_cols - 1) / 2.0) * formation_spacing.x,
			(row - (rows - 1) / 2.0) * formation_spacing.y
		)
		positions.append(center + offset)
	
	return positions

func calculate_line_formation(count: int, center: Vector2) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for i in count:
		var offset = Vector2((i - (count - 1) / 2.0) * formation_spacing.x, 0)
		positions.append(center + offset)
	return positions

func calculate_wedge_formation(count: int, center: Vector2) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var rows = ceil((sqrt(1 + 8 * count) - 1) / 2)  # Triangular number formula
	var index = 0
	
	for row in rows:
		var cols = row + 1
		for col in cols:
			var offset = Vector2(
				(col - (cols - 1) / 2.0) * formation_spacing.x,
				row * formation_spacing.y
			)
			positions.append(center + offset)
			index += 1
			if index >= count:
				return positions
	return positions
			
func move_in_formation(units: Array, center: Vector2):
	var positions = calculate_formation_positions(units.size(), center)
	for i in units.size():
		if units[i] is Unit:
			units[i].target_pos = positions[i]
			
func _find_valid_position(target_pos: Vector2) -> Vector2:
	var space_state = get_viewport().world_2d.direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = CircleShape2D.new()
	query.shape.radius = 16.0
	query.transform = Transform2D(0, target_pos)
	query.collision_mask = 1  # Units collision layer
	
	if space_state.intersect_shape(query).is_empty():
		return target_pos
	
	# Find nearby valid position
	var attempts = 5
	for i in attempts:
		var offset = Vector2(
			randf_range(-formation_spacing.x, formation_spacing.x),
			randf_range(-formation_spacing.y, formation_spacing.y)
		)
		var new_pos = target_pos + offset
		query.transform = Transform2D(0, new_pos)
		if space_state.intersect_shape(query).is_empty():
			return new_pos
	return target_pos  # Fallback

func command_move(units: Array[Unit], target_pos: Vector2):
	var formation_positions = calculate_formation_positions(units.size(), target_pos)
	for i in units.size():
		var unit = units[i]
		var final_pos = _find_valid_position(formation_positions[i])
		unit.set_movement_target(final_pos)

