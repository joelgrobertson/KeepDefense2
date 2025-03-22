extends Node
class_name StateMachine

@export var initial_state: State

var current_state: State

func init(unit_ref):
	# Initialize states with unit reference
	for child in get_children():
		if child is State:
			child.unit = unit_ref
			child.state_transition_requested.connect(_on_state_transition)
	
	# Set initial state
	if initial_state:
		current_state = initial_state
		current_state.enter()
	else:
		push_error("No initial state set in StateMachine")

func _physics_process(delta):
	if current_state:
		current_state.physics_update(delta)

func _on_state_transition(new_state_name: String):
	print("State transition requested: ", new_state_name)
	var new_state = get_node(new_state_name)
	if new_state and new_state is State:
		if current_state:
			current_state.exit()
		current_state = new_state
		current_state.enter()
	else:
		push_error("Invalid state requested: " + new_state_name)
