extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if GameManager.pending_game_start:
		GameManager.pending_game_start = false
		AudioManager.play_music()
		GameManager._start_game()

func _input(event):
	if event.is_action_pressed("ui_cancel"):  # Default binding for Esc
		get_tree().quit()
