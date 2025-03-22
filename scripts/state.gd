extends Node
class_name State

var state_machine = null
var unit = null

signal state_transition_requested(new_state)

func _ready():
	await owner.ready
	
	# Get reference to state machine
	state_machine = get_parent()
	
	# Get reference to the Unit (owner of the state machine)
	unit = owner.get_parent()

func enter():
	pass

func exit():
	pass

func update(delta):
	pass

func physics_update(delta):
	pass
