# Castle.gd
extends Area2D
class_name Castle

signal castle_destroyed

@export var health := 1000.0
@export var radius := 100.0  # Detection radius

func _ready():
	add_to_group("castle")

func take_damage(amount: float):
	health -= amount
	print("Castle health: ", health)
	
	if health <= 0:
		print("Castle destroyed!")
		castle_destroyed.emit()
		queue_free()
