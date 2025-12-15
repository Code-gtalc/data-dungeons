extends Control

func _ready():
	$VBoxContainer/ButtonStart.pressed.connect(_on_start_pressed)
	$VBoxContainer/ButtonQuit.pressed.connect(_on_quit_pressed)

func _on_start_pressed():
	get_tree().change_scene_to_file("res://scenes/sorting_cavern.tscn")

func _on_quit_pressed():
	get_tree().quit()
