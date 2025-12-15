extends HBoxContainer

# --- Child label for displaying the current step ---
@onready var step_label: Label = get_node_or_null("StepLabel")

var steps: Array = []
var current_step := 0

signal steps_finished

# --- Ensure step_label exists ---
func _ready():
	if step_label == null:
		print("StepLabel not found, creating one automatically")
		step_label = Label.new()
		step_label.name = "StepLabel"
		add_child(step_label)
	# Optional: initial blank text
	step_label.text = ""

# --- Set the steps array and reset current step ---
func set_steps(new_steps: Array) -> void:
	steps = new_steps
	current_step = 0
	print("AlgorithmSteps: Setting steps:", steps)
	if step_label != null and steps.size() > 0:
		step_label.text = steps[0]

# --- Advance to the next step ---
func next_step() -> void:
	if step_label == null:
		return
	if steps.size() == 0:
		return

	if current_step < steps.size() - 1:
		current_step += 1
		step_label.text = steps[current_step]

		if current_step == steps.size() - 1:
			emit_signal("steps_finished")

# --- Reset steps to the first step ---
func reset_steps() -> void:
	current_step = 0
	if step_label != null and steps.size() > 0:
		step_label.text = steps[0]

# --- Check if the steps are finished ---
func is_finished() -> bool:
	return current_step >= steps.size() - 1

# --- Optional helper to add a new step dynamically ---
func add_step(step_text: String) -> void:
	steps.append(step_text)
