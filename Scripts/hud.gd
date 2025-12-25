extends Control

var uilife_scene = preload("res://Scenes/ui_life.tscn")

@onready var score = $Score:
	set(value):
		score.text = "Score: " + str(value)
		
@onready var health = $Node2D/Health:
	set(value):
		health.value = value

@onready var lives = $Node2D2/Lifes:
	set(value):
		for ul in lives.get_children():
			ul.queue_free()
		for i in value:
			var uilife = uilife_scene.instantiate()
			lives.add_child(uilife)
			
