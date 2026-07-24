extends Control

func _on_StartButton_pressed():
	GameManager.new_game()
	
func _on_QuitButton_pressed():
	get_tree().quit()
