extends Node

@onready var selection_rect = %SelectionRect

var selected_units := []
var is_dragging := false
var drag_start_world_pos := Vector2.ZERO

# Formation parameters
@export var formation_spacing := Vector2(50, 50)
@export var formation_shape := "grid"  # Options: "grid", "line", "wedge"

func _ready():
	set_process_unhandled_input(true)
	print("UnitManager initialized")

func _unhandled_input(event):
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if event.pressed:
					# Begin selection - store the world position where we started dragging
					is_dragging = true
					drag_start_world_pos = get_mouse_world_pos()
					selection_rect.start_drag(event.position)
					print("Started selection at world pos: ", drag_start_world_pos)
				elif is_dragging:
					# End selection
					select_units_in_rectangle()
					is_dragging = false
					selection_rect.visible = false
			MOUSE_BUTTON_RIGHT:
				if event.pressed and selected_units.size() > 0:
					# Move selected units
					var target = get_mouse_world_pos()
					command_move(selected_units, target)

# Get the world position of the mouse, handling zoom correctly
func get_mouse_world_pos() -> Vector2:
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return get_viewport().get_mouse_position()
	
	# In Godot 4, use the correct method to convert screen coordinates to world coordinates
	var mouse_pos = get_viewport().get_mouse_position()
	var canvas_transform = get_viewport().get_canvas_transform()
	
	# Apply the inverse of the canvas transform to get world coordinates
	return canvas_transform.affine_inverse() * mouse_pos

# Select all units within the selection rectangle
func select_units_in_rectangle():
	# Get current mouse world position
	var current_world_pos = get_mouse_world_pos()
	
	# Create a world-space rectangle from the drag start and current positions
	var rect_pos = Vector2(
		min(drag_start_world_pos.x, current_world_pos.x),
		min(drag_start_world_pos.y, current_world_pos.y)
	)
	
	var rect_size = Vector2(
		abs(current_world_pos.x - drag_start_world_pos.x),
		abs(current_world_pos.y - drag_start_world_pos.y)
	)
	
	var selection_rect_world = Rect2(rect_pos, rect_size)
	
	print("Selection rectangle in world space: ", selection_rect_world)
	
	# Clear the current selection
	clear_selection()
	
	# Find all units within the selection rectangle
	for unit in get_tree().get_nodes_in_group("units"):
		if selection_rect_world.has_point(unit.global_position):
			select_unit(unit)
			print("Selected unit: ", unit.name, " at position: ", unit.global_position)

# Clear the current selection
func clear_selection():
	for unit in selected_units:
		unit.is_selected = false
	selected_units.clear()

# Select a single unit
func select_unit(unit):
	unit.is_selected = true
	selected_units.append(unit)

# Command the selected units to move to a target position
func command_move(units: Array, target_pos: Vector2):
	var formation_positions = calculate_formation_positions(units.size(), target_pos)
	
	for i in units.size():
		if i < formation_positions.size() and units[i] is Unit:
			units[i].set_movement_target(formation_positions[i])

# Calculate formation positions for units
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
	var int_cols = int(cols)
	
	for i in count:
		var row = i / int_cols
		var col = i % int_cols
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
	var rows = ceil((sqrt(1 + 8 * count) - 1) / 2)
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
