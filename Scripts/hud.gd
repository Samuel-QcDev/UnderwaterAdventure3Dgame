# Hud.gd

extends CanvasLayer

@onready var time_label = $Control/TimeLabel
@onready var keys_label = $Control/KeysLabel
@onready var gold_label = $Control/GoldLabel
@onready var objective_label = $Control/ObjectiveLabel
@onready var win_label = $Control/WinLabel


func update_time(seconds: int) -> void:
	time_label.text = "Temps : %d" % seconds


func update_keys(count: int, needed: int) -> void:
	keys_label.text = "Clés : %d / %d" % [count, needed]


func update_gold(amount: int) -> void:
	gold_label.text = "Or : %d" % amount


func show_objective(text: String) -> void:
	objective_label.text = text
	objective_label.visible = true


func show_win_message() -> void:
	win_label.text = "TRÉSOR OUVERT !\nTu as gagné !"
	win_label.visible = true


func show_game_over_message() -> void:
	win_label.text = "Temps écoulé…"
	win_label.visible = true


# Kept for backward-compatibility (coins are now optional bonus gold).
func update_coin_count(count: int) -> void:
	update_gold(count)
