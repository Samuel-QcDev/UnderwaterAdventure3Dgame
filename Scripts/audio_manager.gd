extends Node

@onready var music: AudioStreamPlayer = $Music

func play_music():
	if not music.playing:
		music.play()

func stop_music():
	music.stop()
