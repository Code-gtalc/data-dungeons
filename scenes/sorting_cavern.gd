extends Node2D

@onready var rooms = [
	$Room0,
	$Room1,
	$Room2,
	$Room3,
	$PuzzleRoom,
	$RewardRoom
]
@onready var player = $Player
@export var start_room: NodePath = ^"Room0"
@onready var exit_door = $DoorRight
var rooms_solved:={}
var crystal_buffer: Array[int] = []
var exit_unlocked: bool = false
@onready var steps_ui := $UI/AlgorithmSteps
var bubble_steps = [
	"Start bubble sort",
	"Compare first two elements",
	"Swap if needed",
	"Continue to next pair",
	"Largest element placed at end",
	"Next pass begins",
	"Sorting complete!"
]
@onready var next_btn = $UI/Controls/NextButton
@onready var auto_btn = $UI/Controls/AutoButton
@onready var reset_btn = $UI/Controls/ResetButton
var auto_running := false


func _ready():
	
	await get_tree().process_frame
	await get_tree().process_frame
	print("SortingCavern READY, finding UI...")
	steps_ui = get_node("UI/AlgorithmSteps")
	print("Found steps_ui:", steps_ui)
	_connect_doors()
	$Player.global_position = rooms[0].get_node("PlayerStart").global_position
	var room = get_node_or_null(start_room)
	if room:
		var spawn = room.get_node_or_null("PlayerStart")
		if spawn:
			player.global_position = spawn.global_position
	steps_ui.set_steps(bubble_steps)
	exit_door.locked = true
	next_btn.pressed.connect(_on_next_step)
	auto_btn.pressed.connect(_on_auto_run)
	reset_btn.pressed.connect(_on_reset)
	steps_ui.steps_finished.connect(_on_sort_finished)
	print("UI global position: ", steps_ui.global_position)
	print("SORTING CAVERN READY:", self)
	



func _connect_doors():
	for i in rooms.size():
		var room = rooms[i]

		# Left door
		if room.has_node("DoorLeft"):
			var dl = room.get_node("DoorLeft")
			dl.target_room = rooms[i - 1].get_path() if i > 0 else NodePath("")

		# Right door
		if room.has_node("DoorRight"):
			var dr = room.get_node("DoorRight")
			dr.target_room = rooms[i + 1].get_path() if i < rooms.size() - 1 else NodePath("")

func move_player_to_room(room_path: NodePath, spawn_point: String = "PlayerStart"):
	print("Moving to:", room_path)


	var room := get_node(room_path)
	if room:
		var start := room.get_node(spawn_point)
		player.global_position = start.global_position


func _on_crystal_collected(value):
	crystal_buffer.append(value)
	add_value_to_ui(value)
	print("Buffer:", crystal_buffer)
	if not is_sorted(crystal_buffer):
		PerfLogger.log_warning("Unsorted sequence detected")

	if is_sorted(crystal_buffer):
		print("Sorted! Clearing & unlocking exit")
		crystal_buffer.clear()
		unlock_exit()


func is_sorted(arr: Array[int]) -> bool:
	for i in range(arr.size() - 1):
		if arr[i] > arr[i+1]:
			return false
	return true
	
func unlock_exit():
	print("Exit unlocked!")
	exit_unlocked = true

func add_value_to_ui(value: int):
	var slot := Label.new()
	slot.text = str(value)
	slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot.add_theme_color_override("font_color", Color.WHITE)
	slot.add_to_group("slot")
	slot.mouse_filter = Control.MOUSE_FILTER_PASS
	steps_ui.add_child(slot)
	
func _on_next_step_button_pressed():
	steps_ui.next_step()
	if steps_ui.is_finished():
		exit_door.locked = false
		exit_door.update_visual_state()

func _on_next_step():
	steps_ui.next_step()

func _on_auto_run():
	if auto_running:
		auto_running = false
		auto_btn.text = "Auto Run"
		return
	auto_running = true
	auto_btn.text = "Stop"
	auto_sort()

func auto_sort() -> void:
	await get_tree().create_timer(0.75).timeout
	steps_ui.next_step()
	if auto_running and not steps_ui.is_finished():
		auto_sort()
	else:
		auto_running = false
		auto_btn.text = "Auto Run"

func _on_reset():
	steps_ui.reset_steps()
	exit_door.locked = true
	auto_running = false
	auto_btn.text = "Auto Run"
	exit_door.update_visual_state()

func _on_sort_finished():
	exit_door.locked = false
	exit_door.update_visual_state()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("WINDOW CLOSE DETECTED")
		PerfLogger.write_log("Game quit via window close")
		PerfLogger.finalize_log()
		get_tree().quit()
