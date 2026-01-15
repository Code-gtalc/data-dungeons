extends Control

func _ready():
	$VBoxContainer/ButtonStart.pressed.connect(_on_start_pressed)
	$VBoxContainer/ButtonQuit.pressed.connect(_on_quit_pressed)

func _on_start_pressed():
	PerfLogger.write_log("Main Menu → Sorting Cavern transition started")
	PerfLogger.log_loading_start()
	get_tree().change_scene_to_file("res://scenes/sorting_cavern.tscn")

func _on_quit_pressed():
	PerfLogger.write_log("Game quit via UI button")
	PerfLogger.finalize_log()
	get_tree().quit()
