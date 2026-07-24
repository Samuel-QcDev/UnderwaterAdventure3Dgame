# Hud.gd

extends CanvasLayer

@onready var time_label = $Control/TimeLabel
@onready var coin_label = $Control/CoinLabel

func update_time(seconds: int):
	time_label.text = "Time: %d" % seconds

func update_coin_count(count: int):
	coin_label.text = "Coins: %d" % count

func show_win_message():
	# Show a message, popup, or transition
	pass

func show_game_over_message():
	# Show a message, popup, or transition
	pass
