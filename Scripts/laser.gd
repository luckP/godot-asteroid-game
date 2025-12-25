extends Area2D

@export var speed := 500.0
@export var damage := 2

var moviment_vector := Vector2(0, -1)

func _physics_process(delta: float) -> void:
	global_position += moviment_vector.rotated(rotation) * speed * delta


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()


func _on_body_entered(area: RigidBody2D) -> void:
	if area is Asteroid:
		hit_asteroid(area)


func hit_asteroid(asteroid: Asteroid) -> void:
	asteroid.take_damage(damage)
	queue_free()
