class_name Asteroid extends RigidBody2D


# --- DEFINITIONS ---
enum AstType { ICE, ROCK, METAL }
enum AstSize { BIG, MEDIUM, SMALL }

# --- SIGNALS ---
signal spawn_asteroid(asteroid_obj)
signal on_destroy(asteroid_obj)

# --- EXPORTS ---
@export_group("Asteroid Settings")
@export var type: AstType = AstType.ROCK
@export var size: AstSize = AstSize.BIG

# --- CONFIGURATION MATRICES ---

# 1. TYPE CONFIG (Controls the ROW / Y)
var type_data = {
	AstType.ICE: {
		"row": 0, 
		"hp_mult": 0.8, 
		"speed_mult": 1.2,
		"points": 100,
		"mass_mult": 1,
	},
	AstType.ROCK: {
		"row": 1, 
		"hp_mult": 1.0, 
		"speed_mult": 1.0,
		"points": 200,
		"mass_mult": 2,
	},
	AstType.METAL: {
		"row": 2, 
		"hp_mult": 2.5, 
		"speed_mult": 0.6,
		"points": 300,
		"mass_mult": 3,
	}
}

# 2. SIZE CONFIG (Controls the COLUMN / X)
var size_data = {
	AstSize.BIG: {
		"col_start": 0,
		"base_hp": 4,
		"base_speed": 40.0,
		"radius": 70.0,
		"damage": 20,
		"points_multiplier": 1,
		"mass": 100,
	},
	AstSize.MEDIUM: {
		"col_start": 3,
		"base_hp": 2,
		"base_speed": 70.0,
		"radius": 45.0,
		"damage": 10,
		"points_multiplier": 0.5,
		"mass": 30,
	},
	AstSize.SMALL: {
		"col_start": 6,
		"base_hp": 1,
		"base_speed": 100.0,
		"radius": 12.0,
		"damage": 5,
		"points_multiplier": 0.25,
		"mass": 10,
	}
}

# --- STATE VARIABLES ---
var movement_vector := Vector2.ZERO
var rotation_speed := 0.0
var current_health := 0
var current_max_health := 0
var points := 0

# Components
@onready var sprite = $Sprite2D
@onready var collider = $CollisionShape2D

func _ready() -> void:
	setup_asteroid()

func setup_asteroid():
	# 1. Fetch Configs
	var t_config = type_data[type]
	var s_config = size_data[size]
	
	# 2. Calculate Stats
	current_max_health = int(s_config["base_hp"] * t_config["hp_mult"])
	if current_max_health < 1: current_max_health = 1
	current_health = current_max_health
	
	# 3. Setup Movement
	var final_speed = s_config["base_speed"] * t_config["speed_mult"]
	rotation = randf_range(0, 2 * PI)
	rotation_speed = randf_range(-1.5, 1.5)
	
	var random_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	movement_vector = random_dir * final_speed
	
	# 4. Setup Visuals
	if sprite:
		# Map the correct grid position
		var col = s_config["col_start"] + randi_range(0, 2)
		var row = t_config["row"]
		sprite.frame_coords = Vector2i(col, row)
	
	# 5. Dynamic Collision Size
	var new_shape = CircleShape2D.new()
	new_shape.radius = s_config["radius"]
	points = int(t_config["points"] * s_config["points_multiplier"])
	mass = int(t_config["mass_mult"] * s_config["mass"])
	collider.shape = new_shape

func _physics_process(delta: float) -> void:
	global_position += movement_vector * delta
	rotation += rotation_speed * delta
	
	# Simple Screen Wrap
	var screen_size = get_viewport_rect().size
	# We add a buffer of 80px (approx half sprite size) to avoid popping
	var margin = 80
	global_position.x = wrapf(global_position.x, -margin, screen_size.x + margin)
	global_position.y = wrapf(global_position.y, -margin, screen_size.y + margin)

func take_damage(amount: int):
	current_health -= amount
	
	# 1. Visual Feedback (Cracked State)
	# Logic: If health is low, shift column by +1
	#if current_health <= (current_max_health / 2) and current_health > 0:
		#update_sprite_damage()
	
	# 2. Destruction Check
	if current_health <= 0:
		destroy()

func update_sprite_damage():
	if not sprite: return
	
	var t_config = type_data[type]
	var s_config = size_data[size]
	
	# Shift 1 column to the right for the damaged frame
	var cracked_col = s_config["col_start"] + 1
	sprite.frame_coords = Vector2i(cracked_col, t_config["row"])

func destroy():
	# 1. Spawn logic (Only if NOT small)
	if size != AstSize.SMALL:
		var next_size = size + 1
		
		# DYNAMIC LOAD to prevent Circular Reference errors
		var asteroid_scene = load("res://Scenes/asteroid.tscn")
		
		if asteroid_scene:
			# Loop to create 2 fragments
			for i in range(3):
				var new_rock = asteroid_scene.instantiate()
				
				# Configure BEFORE adding to tree
				new_rock.global_position = global_position
				new_rock.type = type # Inherit parent type (Ice -> Ice)
				new_rock.size = next_size
				
				# Handover to Main Scene
				emit_signal("spawn_asteroid", new_rock)
		else:
			print("Error: Could not load asteroid scene. Check path: res://Scenes/asteroid.tscn")
	
	# 2. Destruction
	emit_signal("on_destroy", self)
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		var s_config = size_data[size]
		var player = body
		player.take_damage(s_config["damage"])
