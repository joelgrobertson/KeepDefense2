# UnitManager.gd
extends Node

@onready var selection_rect = %SelectionRect

var selected_units := []
var is_dragging := false
var drag_start_world_pos := Vector2.ZERO

# Formation parameters
@export var formation_spacing := Vector2(50, 50)
@export var formation_shape := "line"  # Options: "grid", "line"

func _ready():
	# Connect to formation dropdown if it exists
	var top_bar = get_tree().get_first_node_in_group("top_bar")
	if top_bar and top_bar.has_signal("formation_changed"):
		top_bar.formation_changed.connect(_on_formation_selected)

func _on_formation_selected(new_formation):
	formation_shape = new_formation
	print("Formation changed to: ", formation_shape)
	
	# Optional: Update existing selected units
	if selected_units.size() > 0:
		var center = get_average_position(selected_units)
		command_move(selected_units, center)

func get_average_position(units: Array) -> Vector2:
	var total = Vector2.ZERO
	for unit in units:
		total += unit.global_position
	return total / units.size()

func _unhandled_input(event):
	# Handle selection start (left mouse button press)
	if Input.is_action_just_pressed("select_units"):
		start_selection_drag()
	
	# Handle selection end (left mouse button release)
	elif Input.is_action_just_released("select_units") and is_dragging:
		finish_selection_drag()
	
	# Handle unit commands (right mouse button)
	elif Input.is_action_just_pressed("command_units") and selected_units.size() > 0:
		command_units_at_cursor()
		
	# You could add more actions like:
	elif Input.is_action_just_pressed("select_all_units"):
		select_all_units()

# These helper functions keep your code organized while remaining in UnitManager
func start_selection_drag():
	is_dragging = true
	drag_start_world_pos = get_mouse_world_pos()
	selection_rect.start_drag(get_viewport().get_mouse_position())

func finish_selection_drag():
	select_units_in_rectangle()
	is_dragging = false
	selection_rect.visible = false

func command_units_at_cursor():
	var target = get_mouse_world_pos()
	var clicked_object = get_object_under_cursor()
	
	if clicked_object is Enemy:
		command_attack(selected_units, clicked_object)
	elif clicked_object is Castle:
		# Units should defend the castle
		var defend_pos = clicked_object.global_position + Vector2(0, 100)  # Position near castle
		command_move(selected_units, defend_pos)
	else:
		command_move(selected_units, target)

# Command units to attack a target
func command_attack(units: Array, target: Node):
	for unit in units:
		if unit is Unit:
			unit.start_combat(target)

# Function to detect what's under the cursor
func get_object_under_cursor():
	var space_state = get_viewport().get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = get_mouse_world_pos()
	query.collision_mask = 1  # Adjust as needed
	var result = space_state.intersect_point(query, 1)
	
	if result.size() > 0:
		return result[0].collider
	return null

# Get the world position of the mouse, handling zoom correctly
func get_mouse_world_pos() -> Vector2:
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return get_viewport().get_mouse_position()
	
	# convert screen coordinates to world coordinates
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

	# Clear the current selection
	clear_selection()
	
	# Find all units within the selection rectangle
	for unit in get_tree().get_nodes_in_group("units"):
		if selection_rect_world.has_point(unit.global_position):
			select_unit(unit)
			print("Selected unit: ", unit.name)

# Clear the current selection
func clear_selection():
	for unit in selected_units:
		unit.is_selected = false
	selected_units.clear()

# Select a single unit
func select_unit(unit):
	unit.is_selected = true
	selected_units.append(unit)
	
func select_all_units():
	clear_selection()
	for unit in get_tree().get_nodes_in_group("units"):
		select_unit(unit)

# Command the selected unit(s) to move to a target position
func command_move(units: Array, target_pos: Vector2):
	var formation_positions = calculate_formation_positions(units.size(), target_pos)
	
	for i in units.size():
		if i < formation_positions.size() and units[i] is Unit:
			print("Commanding move for: ", units[i].name)
			units[i].set_movement_target(formation_positions[i])

# Calculate formation positions for units
func calculate_formation_positions(count: int, center: Vector2) -> Array[Vector2]:
	var positions = []
	match formation_shape:
		"grid":
			positions = calculate_grid_formation(count, center)
		"line":
			positions = calculate_line_formation(count, center)
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
