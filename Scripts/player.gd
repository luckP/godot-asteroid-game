class_name Player extends CharacterBody2D

# --- SIGNALS ---
signal laser_shot(laser)
signal player_die()
signal player_take_damage()

# --- SETTINGS ---
# Movement Settings
@export var thrust_force: float = 300.0   
@export var linear_friction: float = 80.0 
@export var max_speed: float = 400.0
@export var default_health: float = 100

# Rotation Settings
@export var rotation_accel: float = 5.0   
@export var rotation_friction: float = 4.0 
@export var max_rotation_speed: float = 4.0 
@export var shoot_rate := 0.2


# --- ON READY ---
@onready var muzzle = $Mozzle
@onready var sprite = $Sprite2D

# --- VARIABLES ---
var laser_scene := preload("res://Scenes/laser.tscn")
var health: int = default_health 
var is_alive := true
  
# --- CRITICAL SETTING ---
# If your sprite draws the ship pointing UP, keep this as (0, -1).
# If your sprite draws the ship pointing RIGHT, change this to (1, 0).
var drive_direction = Vector2.UP 

# --- INTERNAL VARIABLES ---
var angular_velocity: float = 0.0
var shoot_cd = false

func _process(_delta: float) -> void:
	if Input.is_action_pressed("shoot"):
		shoot_laser()

func _physics_process(delta: float) -> void:
	
	## 1. ROTATION PHYSICS
	var turn_input := Input.get_axis("rotate_left", "rotate_right")
	
	if turn_input:
		angular_velocity += turn_input * rotation_accel * delta
	else:
		angular_velocity = move_toward(angular_velocity, 0, rotation_friction * delta)
	
	angular_velocity = clamp(angular_velocity, -max_rotation_speed, max_rotation_speed)
	rotation += angular_velocity * delta

	## 2. MOVEMENT PHYSICS
	# The .rotated(rotation) function is the MAGIC part.
	# It takes the "Up" direction and turns it to match the ship's angle.
	
	if Input.is_action_pressed("move_forward"):
		# We rotate our drive_direction by the ship's current rotation
		var current_direction = drive_direction.rotated(rotation)
		velocity += current_direction * thrust_force * delta
		
	if Input.is_action_pressed("move_backward"):
		# We rotate our drive_direction by the ship's current rotation
		var current_direction = drive_direction.rotated(rotation)
		velocity += current_direction * thrust_force * delta * -1
		
	# Apply Space Drag
	velocity = velocity.move_toward(Vector2.ZERO, linear_friction * delta)
	
	# --- NEW: LIMIT SPEED ---
	# This ensures the ship never goes faster than 'max_speed'
	velocity = velocity.limit_length(max_speed)

	## 3. APPLY MOVEMENT
	move_and_slide()
	
	## 4. SCREEN WRAP
	var screen_size = get_viewport_rect().size
	position.x = wrapf(position.x, 0, screen_size.x)
	position.y = wrapf(position.y, 0, screen_size.y)
	
func shoot_laser():
	if shoot_cd:
		return
	shoot_cd = true
	
	var laser = laser_scene.instantiate()
	laser.global_position = muzzle.global_position
	laser.rotation = rotation
	emit_signal("laser_shot", laser)
	
	await get_tree().create_timer(shoot_rate).timeout
	shoot_cd = false
	
func take_damage(damage: float) -> void:
	health -= damage
	emit_signal("player_take_damage")
	if health <= 0:
		die()
	
		
func die() -> void:
	health = default_health
	emit_signal("player_die")
	is_alive = false
	sprite.visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	
	
func respawn(pos: Vector2):
	if !is_alive:
		is_alive = true
		global_position = pos
		velocity = Vector2.ZERO
		sprite.visible = true
		process_mode = Node.PROCESS_MODE_INHERIT
	
	
	
	

	
