# EnemySpawner.gd
extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_radius_min: float = 800.0
@export var spawn_radius_max: float = 1000.0
@export var spawn_interval: float = 5.0
@export var enemies_per_wave: int = 3
@export var max_enemies: int = 50  # Limits total enemies to prevent performance issues

var castle: Castle
var spawn_timer: float = 0.0
var enemy_count: int = 0

func _ready():
	# Find the castle
	castle = get_tree().get_first_node_in_group("castle")
	if !castle:
		push_error("No castle found for enemy spawner!")

func _process(delta):
	if !castle:
		return
		
	spawn_timer += delta
	
	if spawn_timer >= spawn_interval and enemy_count < max_enemies:
		spawn_wave()
		spawn_timer = 0.0

func spawn_wave():
	for i in range(enemies_per_wave):
		if enemy_count >= max_enemies:
			break
			
		var spawn_position = get_random_spawn_position()
		if spawn_position:
			spawn_enemy(spawn_position)

func get_random_spawn_position() -> Vector2:
	var angle = randf() * 2 * PI
	var distance = randf_range(spawn_radius_min, spawn_radius_max)
	var spawn_pos = castle.global_position + Vector2(cos(angle), sin(angle)) * distance
	
	# Validate position (optional: check if it's on valid navigation mesh)
	# You could add additional checks here
	
	return spawn_pos

func spawn_enemy(position: Vector2):
	var enemy_instance = enemy_scene.instantiate()
	enemy_instance.global_position = position
	add_child(enemy_instance)
	
	# Track enemy count and connect to destroyed signal
	enemy_count += 1
	# Connect to the tree_exiting signal to decrement enemy count
	enemy_instance.tree_exiting.connect(_on_enemy_destroyed)

# Called when an enemy is destroyed
func _on_enemy_destroyed():
	enemy_count -= 1
