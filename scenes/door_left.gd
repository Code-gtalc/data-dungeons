extends Area2D

@export var target_room : String = ""   # Example: "Room1"

func _ready():
	print("DoorLeft READY, target =", target_room)

func _on_body_entered(body: Node) -> void:
	print("DoorLeft: body entered →", body)

	if body.name=="Player":
		print("DoorLeft → calling RoomManager.change_room(", target_room, ")")
		RoomManager.change_room(target_room)
