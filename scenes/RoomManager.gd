extends Node

# Robust RoomManager for the project
# Spawns player at SortingCavern PlayerStart (only once), connects crystals once,
# forwards crystal values to SortingUI, manages door signals, and unlocks exits
# when SortingUI emits `sorted_correctly`.

var player: CharacterBody2D = null
var rooms: Dictionary = {}
var exit_doors: Array = []
var initialized_rooms := {}
var sorting_ui_node_path: NodePath = NodePath("UI/SortingUI")
var sorting_ui_ref: Node = null

func _ready():
	print("--- RoomManager Ready (patched) ---")
	get_tree().connect("tree_changed", Callable(self, "_on_tree_changed"))

func _on_tree_changed():
	var scene = get_tree().current_scene
	if scene == null:
		return

	# Acquire player reference if present
	if player == null:
		player = scene.get_node_or_null("Player")
		if player:
			print("RoomManager: Player found in scene:", scene.name)

	# Register rooms only once
	for child in scene.get_children():
		if child is Node and child.is_in_group("room") and not initialized_rooms.has(child.name):
			rooms[child.name] = child
			initialized_rooms[child.name] = true
			print("RoomManager: Registered room:", child.name)
			_connect_room_doors(child)

	# For SortingCavern scene: spawn player at scene's PlayerStart only once
	if scene.name == "SortingCavern":
		# cache sorting UI
		if sorting_ui_ref == null and scene.has_node(sorting_ui_node_path):
			sorting_ui_ref = scene.get_node(sorting_ui_node_path)
			print("RoomManager: Found SortingUI:", sorting_ui_ref)
			# connect to sorted signal if available
			if sorting_ui_ref.has_signal("sorted_correctly") and not sorting_ui_ref.is_connected("sorted_correctly", Callable(self, "_on_sorted_correctly")):
				sorting_ui_ref.connect("sorted_correctly", Callable(self, "_on_sorted_correctly"))
				print("RoomManager: Connected to SortingUI.sorted_correctly")

		# spawn player at SortingCavern PlayerStart only once
		if player and scene.has_node("PlayerStart"):
			if not scene.has_meta("__player_spawned_by_roommanager"):
				var spawn = scene.get_node("PlayerStart")
				player.global_position = spawn.global_position
				scene.set_meta("__player_spawned_by_roommanager", true)
				print("RoomManager: Player spawned at SortingCavern PlayerStart:", spawn.global_position)

		_connect_existing_crystals(scene)
	else:
		# For non-sorting scenes, do not reposition player automatically.
		pass


func _connect_room_doors(room: Node) -> void:
	# Connect door_entered signals (left/right). Add door to exit_doors if right door is an exit.
	if room.has_node("DoorLeft"):
		var dl = room.get_node("DoorLeft")
		if dl and not dl.is_connected("door_entered", Callable(self, "_on_door_entered")):
			dl.connect("door_entered", Callable(self, "_on_door_entered"))
	if room.has_node("DoorRight"):
		var dr = room.get_node("DoorRight")
		if dr and not dr.is_connected("door_entered", Callable(self, "_on_door_entered")):
			dr.connect("door_entered", Callable(self, "_on_door_entered"))
			if dr not in exit_doors:
				exit_doors.append(dr)
				# lock by default if property exists
				if "locked" in dr:
					dr.locked = true
				if dr.has_method("update_visual_state"):
					dr.call("update_visual_state")


func _connect_existing_crystals(scene: Node) -> void:
	# Connect crystals found in the scene tree group "crystal".
	# We intentionally do NOT filter by owner here, because crystals may be
	# nested inside room nodes and we want to connect them all once.
	var crystals = get_tree().get_nodes_in_group("crystal")
	for c in crystals:
		# If crystal is already connected, skip (prevents duplicates)
		if c.has_signal("crystal_collected") and not c.is_connected("crystal_collected", Callable(self, "_on_crystal_collected")):
			c.connect("crystal_collected", Callable(self, "_on_crystal_collected"))
			print("RoomManager: connected crystal:", c)


func _on_crystal_collected(value):
	# Normalize to int
	var int_val:int = value if typeof(value) == TYPE_INT else int(str(value))
	if sorting_ui_ref != null and sorting_ui_ref.has_method("on_crystal_value"):
		# forward to UI deferred to avoid timing issues
		sorting_ui_ref.call_deferred("on_crystal_value", int_val)
	else:
		print("RoomManager: No SortingUI to handle crystal value:", int_val)


func _on_door_entered(target_room):
	# Doors might pass NodePath or simple string; normalize to string room name
	var room_name := ""
	if typeof(target_room) == TYPE_NODE_PATH:
		room_name = String(target_room).get_file()
	else:
		room_name = str(target_room)

	# ensure player reference
	if player == null:
		var current_scene = get_tree().current_scene
		if current_scene:
			player = current_scene.get_node_or_null("Player")
	if player == null:
		print("RoomManager: door_entered but player missing; ignoring")
		return

	change_room(room_name)


func change_room(room_name: String) -> void:
	if not rooms.has(room_name):
		push_error("RoomManager: Room not found: " + room_name)
		return
	var room = rooms[room_name]
	var spawn = room.get_node_or_null("PlayerStart")
	if spawn and player:
		player.global_position = spawn.global_position
		print("RoomManager: Player moved to", room_name, "pos=", spawn.global_position)
	for r in rooms.values():
		r.visible = (r == room)


# --- Unlock / lock exit doors ---
func unlock_exit() -> void:
	print("RoomManager: Unlocking exits...")

	# Unlock logic doors
	for d in exit_doors:
		if d:
			if "locked" in d:
				d.locked = false
			if d.has_method("update_visual_state"):
				d.call("update_visual_state")

	# Disable the physical static collision
	var scene = get_tree().current_scene
	if scene and scene.has_node("Room0"):
		var room = scene.get_node("Room0")

		if room.has_node("StaticBody2D/DoorBlocker"):
			room.get_node("StaticBody2D/DoorBlocker").disabled = true

		# Hide the translucent overlay
		set_door_blocker_visual(room, false)





func lock_all_exits() -> void:
	for d in exit_doors:
		if d:
			if "locked" in d:
				d.locked = true
			if d.has_method("update_visual_state"):
				d.call("update_visual_state")


# --- SortingUI callback ---
func _on_sorted_correctly() -> void:
	print("RoomManager: Sorting UI reports correct sort - unlocking exits")
	unlock_exit()

func disable_room_blocker(room: Node):
	if room.has_node("StaticBody2D/DoorBlocker"):
		var blocker := room.get_node("StaticBody2D/DoorBlocker")
		blocker.disabled = true
		print("RoomManager: DoorBlocker disabled for", room.name)

func set_door_blocker_visual(room: Node, visible: bool):
	if room.has_node("DoorBlockerVisual"):
		room.get_node("DoorBlockerVisual").visible = visible
