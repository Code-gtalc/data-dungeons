extends Area2D

@export var target_room: String = ""
@export var locked: bool = false     # default OFF, RoomManager will turn it ON

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	if not body.is_in_group("player"):
		return

	if locked:
		print("Door is locked!")
		return

	if RoomManager:
		RoomManager.change_room(target_room)
