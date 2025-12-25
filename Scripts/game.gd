extends Node2D

# --- UI ---
var score := 0:
	set(value):
		score = value
		hud.score = score
		
var health := 0:
	set(value):
		health = value
		hud.health = value
		
@onready var hud = $UI/HUD
@onready var lasers = $Lasers
@onready var player = $Player
@onready var asteroids_container = $Asteroids 
@onready var player_spawn = $PlawerSpawn

# References for Spawning
@onready var asteroid_timer = $AsteroidTimer
@onready var spawn_location = $Path2D/PathFollow2D # Make sure you created these nodes!

# We NEED this back so Main can spawn brand new rocks from scratch
@export var asteroid_scene: PackedScene 
@export var lifes := 3

func _ready() -> void:
	score = 0
	# Connect player
	player.connect("laser_shot", _on_player_laser_shot)
	player.connect("player_take_damage", _on_player_take_damage)
	player.connect("player_die", _on_player_die)
	# Connect the Timer signal
	asteroid_timer.connect("timeout", _on_asteroid_timer_timeout)
	
	# Connect existing asteroids (Manually placed in editor)
	for child in asteroids_container.get_children():
		if child.has_signal("spawn_asteroid"):
			child.connect("spawn_asteroid", _on_asteroid_spawn_request)
			child.connect("on_destroy", _on_asteroid_destroy_request)

func _on_player_laser_shot(laser):
	lasers.add_child(laser)

# --- 1. PERIODIC SPAWN LOGIC (The Loop) ---
func _on_asteroid_timer_timeout():
	if asteroid_scene == null: 
		return
	
	# A. Create a new rock
	var rock = asteroid_scene.instantiate()
	
	# B. Pick a random spot on the Path2D
	spawn_location.progress_ratio = randf() # Random point from 0.0 to 1.0 along the line
	rock.global_position = spawn_location.global_position
	
	# C. Randomize Type (Ice, Rock, Metal)
	# We use the Enums defined in your Asteroid script
	# randi() % 3 gives us 0, 1, or 2
	var asteroid_type = randi_range(0, 10)
	if asteroid_type < 2:
		rock.type = 0
	elif  asteroid_type < 8:
		rock.type = 1
	else:
		rock.type = 2
	rock.size = randi_range(0, 2)
	
	# D. Add using the same helper function we use for splitting
	_on_asteroid_spawn_request(rock)


# --- 2. UNIVERSAL SPAWN HELPER ---
# Handles both NEW asteroids and SPLIT pieces
func _on_asteroid_spawn_request(new_rock_node):
	# Connect the signal on this NEW rock so IT can spawn children too
	if new_rock_node.has_signal("spawn_asteroid"):
		new_rock_node.connect("spawn_asteroid", _on_asteroid_spawn_request)
		new_rock_node.connect("on_destroy", _on_asteroid_destroy_request)
	
	# Add to container safe from physics errors
	asteroids_container.call_deferred("add_child", new_rock_node)
	
func _on_asteroid_destroy_request(asteroid):
	score += asteroid.points
	print(score)
	
func _on_player_die():
	score = 0
	lifes -= 1
	
	if lifes <= 0:
		await get_tree().create_timer(1).timeout
		get_tree().reload_current_scene()
	else:
		await get_tree().create_timer(1).timeout
		player.respawn(player_spawn.position)
	
	hud.health = player.health
		
func _on_player_take_damage():
	health = player.health
		
