extends CharacterBody2D

@export var move_speed: float = 120.0

@onready var anim_player: AnimationPlayer = $AnimationPlayer

# Start facing RIGHT
var last_dir: Vector2 = Vector2.RIGHT  
var direction: Vector2 = Vector2.ZERO

func _ready():
	anim_player.play("idle_right")   # Initial idle state
	add_to_group("player")
	print("Player ready, listening for crystals...")


func _physics_process(delta):
	direction = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)

	if direction != Vector2.ZERO:
		direction = direction.normalized()
		velocity = direction * move_speed
		_play_walk_animation()
		last_dir = direction
	else:
		velocity = Vector2.ZERO
		_play_idle_animation()

	move_and_slide()


func _play_walk_animation():
	# Horizontal movement
	if abs(direction.x) > abs(direction.y):
		if direction.x > 0:
			anim_player.play("walk_right")
		else:
			anim_player.play("walk_left")

	# Vertical movement
	else:
		if direction.y > 0:
			anim_player.play("walk_down")
			
		else:
			anim_player.play("walk_up")
			   


func _play_idle_animation():
	if abs(last_dir.x) > abs(last_dir.y):
		if last_dir.x > 0:
			anim_player.play("idle_right")
		else:
			anim_player.play("idle_left")
	else:
		# Up/down idle -> use idle_up_down (shared)
		anim_player.play("idle_up_down")

func _on_crystal_collected(value: int) -> void:
	print("Collected crystal worth: ", value)
	GameState.add_score(value)
