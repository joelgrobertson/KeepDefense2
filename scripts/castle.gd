extends Area2D

@export var health := 50.0

func _ready():
	add_to_group("castle")

func take_damage(amount: float):
	health -= amount
	print("Castle health: " + str(health))
	if health <= 0:
		print("Castle destroyed!")
		queue_free()

func _on_body_entered(body):
	if body is Enemy:
		body.start_combat(self)
