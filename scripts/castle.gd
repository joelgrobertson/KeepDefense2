# Castle.gd
extends Area2D
class_name Castle

signal castle_destroyed

@export var health := 1000.0

func _ready():
	add_to_group("castle")
	add_to_group("combat_areas")

func take_damage(amount: float):
	health -= amount
	print("Castle health: ", health)
	
	if health <= 0:
		print("Castle destroyed!")
		castle_destroyed.emit()
		queue_free()
