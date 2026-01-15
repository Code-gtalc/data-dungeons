extends Node

var log_file: FileAccess

# FPS tracking
var fps_samples: Array[float] = []
var min_fps: float = INF

# Timing
var load_start_time: int = 0
var input_times: Array[int] = []

# Loading time aggregation
var load_durations: Array[int] = []

# Input response aggregation
var input_response_durations: Array[int] = []



# Error tracking
var warning_count: int = 0
var error_count: int = 0

func _ready():
	print("PerfLogger READY")  # <-- MUST appear in Output
	var path := "user://performance_log.txt"
	log_file = FileAccess.open(path, FileAccess.WRITE)
	write_log("=== Performance Log Started ===")
	log_file.flush()


func _process(delta):
	var fps := Engine.get_frames_per_second()
	fps_samples.append(fps)
	min_fps = min(min_fps, fps)

func _input(event):
	if event.is_pressed():
		input_times.append(Time.get_ticks_usec())

func log_input_response_time(duration_usec: int):
	input_response_durations.append(duration_usec)


# -----------------------------
# Loading time logging
# -----------------------------
func log_loading_start():
	load_start_time = Time.get_ticks_usec()

func log_loading_end(scene_name: String):
	if load_start_time == 0:
		return

	var duration := Time.get_ticks_usec() - load_start_time
	load_durations.append(duration)

	write_log("Loading Time [%s]: %d µs" % [scene_name, duration])

	load_start_time = 0


# -----------------------------
# Error & warning logging
# -----------------------------
func log_warning(msg: String):
	warning_count += 1
	write_log("WARNING: " + msg)

func log_error(msg: String):
	error_count += 1
	write_log("ERROR: " + msg)

# -----------------------------
# Final summary
# -----------------------------
func finalize_log():
	var avg_fps := 0.0
	if fps_samples.size() > 0:
		avg_fps = fps_samples.reduce(func(a, b): return a + b) / fps_samples.size()

	write_log("")
	write_log("=== SUMMARY ===")
	write_log("Average FPS: %.2f" % avg_fps)
	write_log("Minimum FPS: %.2f" % min_fps)

	if load_durations.size() > 0:
		var total_load := 0
		for t in load_durations:
			total_load += t

		var avg_load := float(total_load) / load_durations.size()
		write_log("Average Loading Time: %.2f µs" % avg_load)
	else:
		write_log("Average Loading Time: N/A")

	write_log("CPU Usage: Not directly available in Godot 4")

	write_log("Memory Usage: %.2f MB" % (OS.get_static_memory_usage() / 1024.0 / 1024.0))
	if input_response_durations.size() > 0:
		var total_input := 0
		for t in input_response_durations:
			total_input += t
		var avg_input := float(total_input) / input_response_durations.size()
		write_log("Average Input Response Time: %.2f µs" % avg_input)
	else:
		write_log("Average Input Response Time: N/A")


	write_log("Warnings: %d" % warning_count)
	write_log("Errors: %d" % error_count)
	write_log("================")

	log_file.close()


# -----------------------------
# Internal file writer
# -----------------------------
func write_log(text: String):
	print(text)
	if log_file:
		log_file.store_line(text)
		log_file.flush()
