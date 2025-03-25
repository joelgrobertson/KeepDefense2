class_name Combatant
extends CharacterBody2D

@export var health := 100.0
@export var attack_damage := 10.0
@export var attack_cooldown := 1.0
@export var speed := 80.0
@export var combat_range := 50.0  # Attacking distance

# Health regeneration properties
@export var can_regenerate := false  # Set to true only for units
@export var regen_rate := 5.0  # Health points per second
@export var regen_cooldown := 3.0  # Seconds to wait after combat before regen starts
var regen_timer := 0.0

# Common properties
var max_health := 100.0
var current_target = null
var is_attacking := false
var is_dying := false
var last_move_direction := Vector2.DOWN
var current_animation := ""
var attack_timer := 0.0

# References
@onready var animated_sprite = $AnimatedSprite2D
@onready var nav_agent = $NavigationAgent2D
@onready var state_machine = $StateMachine
@onready var combat_area = $CombatArea
@onready var health_bar = $HealthBar
@onready var health_bar_fill = $HealthBar/Fill
@onready var health_bar_bg = $HealthBar/Background
@onready var health_text = $HealthBar/HealthText

func _ready():
	# Save max health
	max_health = health
	
	# Hide health bar initially
	health_bar.visible = false
	
	# Initialize the state machine with self-reference
	state_machine.init(self)
	
	# Connect navigation signals
	nav_agent.velocity_computed.connect(_on_velocity_computed)
	
	# Connect combat area signals
	if combat_area:
		combat_area.area_entered.connect(_on_combat_area_area_entered)

func _process(delta):
	# Handle health regeneration when not in combat
	handle_health_regen(delta)
	
func handle_health_regen(delta):
	# Only proceed if regeneration is enabled and health is not full
	if !can_regenerate or health >= max_health or is_attacking or is_dying:
		regen_timer = 0.0  # Reset timer when in combat
		return
		
	# Increment regeneration timer
	regen_timer += delta
	
	# Check if we've waited long enough after combat
	if regen_timer >= regen_cooldown:
		# Apply regeneration
		health += regen_rate * delta
		
		# Cap health at maximum
		if health > max_health:
			health = max_health
			health_bar.visible = false  # Hide health bar when fully healed
		else:
			# Update health bar
			update_health_bar()

# Virtual function to be implemented by children
func _on_combat_area_area_entered(area):
	pass

# Handle taking damage
func take_damage(amount: float):
	# If already dying, don't take more damage
	if is_dying:
		return
		
	health -= amount
	print(name, " took damage: ", amount, ", health: ", health)
	
	if health <= 0:
		# Set dying flag first to prevent further damage processing
		is_dying = true
		handle_death()
	else:
		update_health_bar()

# Update the health bar visibility and fill amount
func update_health_bar():
	# Only show health bar if health is less than max
	if health < max_health:
		health_bar.visible = true
		health_text.text = str(int(health)) + "/" + str(int(max_health))
		# Calculate fill percentage (ensure it's between 0 and 1)
		var fill_percent = clamp(health / max_health, 0.0, 1.0)
		
		# Update the fill rect width
		health_bar_fill.size.x = health_bar_bg.size.x * fill_percent
	elif health <= 0:
		health_bar.visible = false

# Handle death logic
func handle_death():
	print(name, " died")
	
	# Set dying state 
	is_dying = true
	health_bar.visible = false
	
	# Disable all collisions immediately
	$CollisionShape2D.set_deferred("disabled", true)
	if combat_area:
		combat_area.set_deferred("monitoring", false)
		combat_area.set_deferred("monitorable", false)
	
	# Clear combat relationships
	if current_target and is_instance_valid(current_target) and current_target is Combatant:
		current_target.handle_target_death(self)
	
	# End all combat
	current_target = null
	is_attacking = false
	
	# Stop all movement and processing
	velocity = Vector2.ZERO
	set_process(false)
	set_physics_process(false)
	
	# Play death animation
	var anim_name = "death_%d" % calculate_direction_index(last_move_direction)
	print("Playing death animation: ", anim_name)
	
	## Set animation to not loop
	animated_sprite.animation = anim_name
	animated_sprite.stop()  # Stop any current animation
	animated_sprite.frame = 0  # Start from first frame
	animated_sprite.play()  # Play the animation once
	
	# Wait for the animation to complete
	await animated_sprite.animation_finished
	
	# Now animation is on last frame - wait a bit longer
	var corpse_timer = get_tree().create_timer(30)  # Corpse remains for 1.5 seconds
	await corpse_timer.timeout
	
	# Remove from scene
	queue_free()

# Called when a target we're fighting dies
func handle_target_death(died_target):
	# Only react if this is actually our target
	if current_target == died_target:
		current_target = null
		is_attacking = false
		
		# Return to default behavior
		if self is Enemy:
			if has_method("target_castle"):
				call("target_castle")
		else:
			state_machine.current_state.state_transition_requested.emit("IdleState")

# Calculate direction for animations
func calculate_direction_index(direction: Vector2) -> int:
	var angle_rad = atan2(direction.y, direction.x)
	var angle_deg = rad_to_deg(angle_rad)
	angle_deg += 90
	return wrapi(int(round(angle_deg / 22.5)), 0, 16)

# Get combat range
func get_combat_range() -> float:
	return combat_range

# Start combat with a target - smoother transition
# Start combat with a target - smoother transition
func start_combat(target):
	if target == null or !is_instance_valid(target) or (target is Combatant and target.is_dying):
		return
		
	print(name, " starting combat with ", target.name)
	current_target = target
	is_attacking = true
	
	# Immediately face the target
	last_move_direction = (target.global_position - global_position).normalized()
	
	# Immediately start attack animation if in range
	var distance = global_position.distance_to(target.global_position)
	if distance <= get_combat_range():
		# Initialize with a partial cooldown so first attack happens quickly
		attack_timer = attack_cooldown * 0.75  # 75% of the way through cooldown
		play_attack_animation()  # Start the attack animation immediately
	
	# Force state change to attacking
	if state_machine and state_machine.current_state:
		state_machine.current_state.state_transition_requested.emit("AttackingState")

# End combat
func end_combat():
	is_attacking = false
	current_target = null
	state_machine.current_state.state_transition_requested.emit("IdleState")

# Set movement target
func set_movement_target(pos: Vector2):
	# Cancel combat if we're told to move somewhere
	if is_attacking:
		end_combat()
		
	nav_agent.target_position = pos
	state_machine.current_state.state_transition_requested.emit("MovingState")

# Navigation callback
func _on_velocity_computed(safe_velocity: Vector2):
	velocity = safe_velocity
	move_and_slide()

# Helper functions for animations
func play_attack_animation():
	var anim_name = "attack_%d" % calculate_direction_index(last_move_direction)
	if anim_name != current_animation:
		animated_sprite.play(anim_name)
		current_animation = anim_name

func play_idle_animation():
	var anim_name = "idle_%d" % calculate_direction_index(last_move_direction)
	if anim_name != current_animation:
		animated_sprite.play(anim_name)
		current_animation = anim_name

func play_walk_animation():
	var anim_name = "walk_%d" % calculate_direction_index(last_move_direction)
	if anim_name != current_animation:
		animated_sprite.play(anim_name)
		current_animation = anim_name
