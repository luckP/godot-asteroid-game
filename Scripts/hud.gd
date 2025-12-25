extends Control

@onready var score = $Score:
	set(value):
		score.text = "Score: " + str(value)
		
@onready var health = $Health:
	set(value):
		health.value = value
