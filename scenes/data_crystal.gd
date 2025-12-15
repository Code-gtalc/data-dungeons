extends CharacterBody2D

@export var value : int = 0
@onready var pickup_area: Area2D = $Area2D

signal crystal_collected(value: int)

func _ready():
	add_to_group("value_crystal")
	$Label.text = str(value)
	if pickup_area:
		pickup_area.connect("body_entered", Callable(self, "_on_body_entered"))
	else:
		push_error("❌ Area2D not found in DataCrystal!")
	#pickup_area.connect("body_entered", Callable(self, "_on_body_entered"))
	print("Crystal ready:", name, "value:", value)

func flash_compare():
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate", Color(1, 0.4, 0.4), 0.2)
	tween.tween_property(self, "modulate", Color(1, 1, 1), 0.2)
	
func _on_body_entered(body):
	if body.name == "Player":
		emit_signal("crystal_collected", value)
		queue_free()
