extends Control

# Node references
@onready var slots_container: HBoxContainer = $Slots
@onready var message_label: Label = $MessagePanel/Message

var values: Array[int] = []
var slot_nodes: Array[Panel] = []
var selected_idx: int = -1
var anim_busy: bool = false

var message_locked := false
signal sorted_correctly
var required_crystals := 4

# Style resources
var normal_stylebox: StyleBoxFlat
var selected_stylebox: StyleBoxFlat
var hover_stylebox: StyleBoxFlat



func _ready():
	# Layout
	set_anchors_preset(Control.PRESET_TOP_WIDE)
	custom_minimum_size = Vector2(900, 240)

	# Message label style
	message_label.add_theme_color_override("font_color", Color.WHITE)
	message_label.add_theme_color_override("font_outline_color", Color.BLACK)
	message_label.add_theme_constant_override("outline_size", 7)

	# Slots container style
	slots_container.custom_minimum_size = Vector2(600, 120)
	slots_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Create styleboxes
	_init_styleboxes()

	show_message("Collect crystals. Click two numbers to swap.")


func _init_styleboxes():
	# Normal slot style
	normal_stylebox = StyleBoxFlat.new()
	normal_stylebox.bg_color = Color(0.1, 0.1, 0.1, 0.6)
	normal_stylebox.set_border_width_all(2)
	normal_stylebox.border_color = Color(0.7, 0.7, 0.7)
	normal_stylebox.set_corner_radius_all(6)

	# Selected slot style
	selected_stylebox = StyleBoxFlat.new()
	selected_stylebox.bg_color = Color(0.25, 0.5, 1.0, 0.85)
	selected_stylebox.set_border_width_all(4)
	selected_stylebox.border_color = Color(1, 1, 1)
	selected_stylebox.set_corner_radius_all(6)

	# Hover style
	hover_stylebox = StyleBoxFlat.new()
	hover_stylebox.bg_color = Color(0.35, 0.35, 0.35, 0.45)
	hover_stylebox.set_border_width_all(3)
	hover_stylebox.border_color = Color(0.9, 0.9, 0.9, 0.8)
	hover_stylebox.set_corner_radius_all(6)




# Called from RoomManager
func on_crystal_value(new_val: int) -> void:
	if values.size() > 0 and values[-1] == new_val:
		return

	values.append(new_val)
	_update_slots_display()


# Build UI
func _update_slots_display() -> void:
	for n in slot_nodes:
		if is_instance_valid(n):
			n.queue_free()
	slot_nodes.clear()

	for i in range(values.size()):
		var panel := Panel.new()
		panel.custom_minimum_size = Vector2(64, 64)
		panel.add_theme_stylebox_override("panel", normal_stylebox)
		panel.mouse_filter = Control.MOUSE_FILTER_STOP

		var label := Label.new()
		label.text = str(values[i])
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.custom_minimum_size = Vector2(64, 64)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE

		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_constant_override("outline_size", 7)

		panel.add_child(label)
		slots_container.add_child(panel)
		slot_nodes.append(panel)

		panel.connect("gui_input", Callable(self, "_on_slot_input").bind(i))
		panel.connect("mouse_entered", Callable(self, "_on_slot_hover").bind(i))
		panel.connect("mouse_exited", Callable(self, "_on_slot_unhover").bind(i))


	_update_selection_highlight()


func show_message(text: String):
	if not message_locked:
		message_label.text = text


func _on_slot_input(event: InputEvent, idx: int) -> void:
	if anim_busy:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_process_selection(idx)


func _process_selection(idx: int) -> void:
	if selected_idx == -1:
		selected_idx = idx
		_update_selection_highlight()
		_pulse(slot_nodes[idx])

		show_message(
			"Bubble Sort: Compare two items and swap if the left is larger. " +
			"Selected " + str(values[idx]) + ". Choose another."
		)

		return

	if idx == selected_idx:
		selected_idx = -1
		_update_selection_highlight()
		show_message("Selection cancelled.")
		return

	_perform_swap(selected_idx, idx)
	selected_idx = -1
	_update_selection_highlight()


func _update_selection_highlight():
	for i in range(slot_nodes.size()):
		var p: Panel = slot_nodes[i]
		if i == selected_idx:
			p.add_theme_stylebox_override("panel", selected_stylebox)
		else:
			p.add_theme_stylebox_override("panel", normal_stylebox)


# Glow animation
func _pulse(panel: Panel):
	var t = panel.create_tween()
	t.set_trans(Tween.TRANS_SINE)
	t.set_ease(Tween.EASE_IN_OUT)
	t.set_loops(2)
	t.tween_property(panel, "modulate:a", 0.6, 0.15).from(1.0)
	t.tween_property(panel, "modulate:a", 1.0, 0.15)


# Swap animation + logic
func _perform_swap(a: int, b: int):
	if anim_busy:
		return
	anim_busy = true

	show_message("Swapping " + str(values[a]) + " and " + str(values[b]) + "...")

	var pa: Panel = slot_nodes[a]
	var pb: Panel = slot_nodes[b]

	var pos_a = pa.global_position
	var pos_b = pb.global_position

	var t1 = pa.create_tween()
	var t2 = pb.create_tween()

	t1.tween_property(pa, "global_position", pos_b, 0.35)
	t2.tween_property(pb, "global_position", pos_a, 0.35)

	t1.connect("finished", func(): _on_swap_anim_finished(a, b))

	var tmp = values[a]
	values[a] = values[b]
	values[b] = tmp


func _on_swap_anim_finished(a: int, b: int):
	_update_slots_display()

	if is_sorted():
		show_message("Correct! The numbers are sorted!")
		emit_signal("sorted_correctly")
		emit_signal("move_ui_to_room0")
	else:
		show_message("Swapped!")

	anim_busy = false


func is_sorted() -> bool:
	if values.size() < required_crystals:
		return false

	for i in range(values.size() - 1):
		if values[i] > values[i + 1]:
			return false

	return true
func _on_slot_hover(idx: int) -> void:
	var p := slot_nodes[idx]
	if anim_busy:
		return

	# Don't override selected slot’s appearance
	if idx != selected_idx:
		p.add_theme_stylebox_override("panel", hover_stylebox)


func _on_slot_unhover(idx: int) -> void:
	var p := slot_nodes[idx]

	# If still selected, keep selected style
	if idx == selected_idx:
		p.add_theme_stylebox_override("panel", selected_stylebox)
	else:
		p.add_theme_stylebox_override("panel", normal_stylebox)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("WINDOW CLOSE DETECTED")
		PerfLogger.write_log("Game quit via window close")
		PerfLogger.finalize_log()
		get_tree().quit()
