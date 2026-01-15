extends Node2D

@onready var player_start := $PlayerStart
@onready var crystals_container := $Crystals

@export var crystal_values: Array[int] = []
@export var spawn_positions: Array[Vector2] = []

var crystal_scene := preload("res://scenes/data_crystal.tscn")

func _ready():
	print("\n===== ROOM READY:", name, "=====")
	print("Room at Global:", global_position)
	print("PlayerStart Local:", player_start.position, 
		  " | Global:", player_start.global_position)

	spawn_crystals()
	debug_crystals()

func spawn_crystals():
	if crystal_values.size() != spawn_positions.size():
		push_error("❌ MISMATCH: crystal_values count != spawn_positions count")
		return

	for i in range(crystal_values.size()):
		var crystal = crystal_scene.instantiate()
		crystal.value = crystal_values[i]

		# Local position inside the room
		crystal.position = spawn_positions[i]

		# Add to container under the room scene tree
		crystals_container.add_child(crystal)

func debug_crystals():
	var crystals = crystals_container.get_children()
	print("Crystals spawned in:", name, "| Total:", crystals.size())

	for crystal in crystals:
		print(" -", crystal.name, 
			"| Local:", crystal.position, 
			"| Global:", crystal.global_position)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("WINDOW CLOSE DETECTED")
		PerfLogger.write_log("Game quit via window close")
		PerfLogger.finalize_log()
		get_tree().quit()
