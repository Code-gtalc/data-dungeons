extends CharacterBody2D

@onready var player = get_tree().get_first_node_in_group("player")

var speed = 40
var growth = 0.02

func _physics_process(delta):
	speed += growth
	var dir = (player.global_position - global_position).normalized()
	velocity = dir * speed
	move_and_slide()
