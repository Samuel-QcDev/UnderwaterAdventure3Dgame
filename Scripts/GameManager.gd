extends Node

# Exported game parameters
@export var total_time: int = 180  # seconds
@export var keys_needed: int = 3   # find this many keys, then deliver to the galleon

@onready var winMusic = AudioManager.get_node("Win")

var last_loaded_scene_path := ""

# Internal state
var time_left: int
var game_over: bool = false

# References to scene nodes (populated at runtime)
var game_timer: Timer
var hud

# Signals to notify game events
signal game_won
signal game_lost

func _ready():
	# Defer node lookup to next idle frame (main scene should be loaded by then)
	call_deferred("_init_nodes")	

func _init_nodes() -> bool:
	# Runs on every boot, including while the start menu is up, so a missing
	# Main scene is expected and must stay quiet.
	game_timer = get_tree().root.get_node_or_null("Main/GameManagerRoot/GameTimer")
	hud = get_tree().root.get_node_or_null("Main/GameManagerRoot/HUD")

	if not game_timer or not hud:
		return false

	# Initialize game state
	time_left = total_time

	# Setup and start the timer
	game_timer.wait_time = 1.0
	# _init_nodes() also runs from _start_game(), so guard against a second connect.
	if not game_timer.timeout.is_connected(_on_timer_timeout):
		game_timer.timeout.connect(_on_timer_timeout)
	game_timer.start()

	# Initial HUD update
	_update_hud()
	return true

#func new_game():
	#call_deferred("_init_nodes")
	#var main_scene_path = "res://Scenes/Main.tscn"
	#
	## First time or wrong scene loaded: switch
	#if last_loaded_scene_path != main_scene_path:
		#last_loaded_scene_path = main_scene_path
		#get_tree().change_scene_to_file(main_scene_path)
		#return
#
	## Already in Main scene, continue game reset
	#if not game_timer or not hud:
		#push_error("GameManager: game_timer or hud not initialized yet!")
		#return
#
	## Continue reset logic
	#if not game_timer or not hud:
		#push_error("GameManager: game_timer or hud not initialized yet!")
		#return
#
	#AudioManager.play_music()
	## Reset the GameManager variables
	#reset()
	## Reset the PlayerState
	#PlayerState.reset()
	## Reset the Main Scene
	##get_tree().reload_current_scene()
	#
	## Reset PlayerState
	##PlayerState.has_shrunk = false
	##PlayerState.is_alive = true
	##PlayerState.coin_count = 0
	## Reset the scene
#
	## Reset internal state
	##time_left = total_time
	##game_over = false
##
	### Restart timer cleanly
	##game_timer.stop()
	##game_timer.start()
##
	### Update HUD
	##_update_hud()
#
	## Reset player position and state
	#var player = get_node_or_null("/root/Main/Player")
	#var original_direction = Vector3(0, 0, 1)  # Forward along -Z
	#var target_pos = player.global_transform.origin + original_direction
	#if player:
		#player.global_transform.origin = Vector3(60, -70, 141)
		#player.reset_rotation() 
		#player.scale = Vector3.ONE
		#player.velocity = Vector3.ZERO
		#player.set_physics_process(true)
	#
		## Reset dying flag so input works again
		##player.is_dying = false
	#reset_sharks()
	#reset_coins()
		## Re-enable collision
	##var collision_shape = player.get_node_or_null("CollisionShape3D")
	##if collision_shape:
		##collision_shape.disabled = false

var pending_game_start := false

func new_game():
	var main_scene_path = "res://Scenes/Main.tscn"
	var current_scene = get_tree().current_scene

	# If scene is not loaded or we're not in Main.tscn, switch
	if current_scene == null or current_scene.scene_file_path != main_scene_path:
		pending_game_start = true
		get_tree().change_scene_to_file(main_scene_path)
		return

	# Already in Main.tscn, start game immediately
	_start_game()


func _start_game():
	# Now safe: all nodes are guaranteed to be ready
	if not _init_nodes():
		push_error("GameManager: game_timer or hud not initialized yet!")
		return

	AudioManager.play_music()
	reset()
	PlayerState.reset()

	var player = get_node_or_null("/root/Main/Player")
	if player:
		player.global_transform.origin = Vector3(0, -58, 110)
		player.reset_rotation()
		player.scale = Vector3.ONE
		player.velocity = Vector3.ZERO
		player.set_physics_process(true)

	reset_sharks()
	reset_coins()

	if hud:
		hud.call("update_keys", 0, keys_needed)
		hud.call("show_objective", "Trouve les 3 clés cachées dans le récif, puis ramène-les au galion.")


func _on_timer_timeout():
	if game_over:
		return
	time_left -= 1
	_update_hud()

	if time_left <= 0:
		game_timer.stop()
		emit_signal("game_lost")
		# die() bails out early when game_over is already true, so kill the
		# player first and only then latch the flag.
		var player = get_node_or_null("/root/Main/Player")
		if player:
			player.die()
		game_over = true
		print("Game over: time ran out!")

func add_coin():
	# Coins are now an optional bonus (gold), not the win condition.
	if game_over:
		return
	PlayerState.coin_count += 1
	_update_hud()

func collect_key():
	if game_over:
		return
	PlayerState.keys_collected += 1
	_update_hud()
	if PlayerState.keys_collected >= keys_needed:
		if hud:
			hud.call("show_objective", "Toutes les clés ! Retourne au galion pour ouvrir le trésor.")
	else:
		if hud:
			hud.call("show_objective", "Clé trouvée ! Il en reste %d." % (keys_needed - PlayerState.keys_collected))

func deliver_treasure():
	# Called when the player reaches the galleon chest.
	if game_over:
		return
	if PlayerState.keys_collected >= keys_needed:
		win()
	elif hud:
		hud.call("show_objective", "Le coffre est verrouillé - il te manque %d clé(s)." % (keys_needed - PlayerState.keys_collected))

func _update_hud():
	# Call HUD functions to update labels, assuming HUD scene has these methods
	if hud:
		hud.call("update_time", time_left)
		hud.call("update_keys", PlayerState.keys_collected, keys_needed)
		hud.call("update_gold", PlayerState.coin_count)

func reset_coins():
	var coins = get_tree().get_nodes_in_group("coins")
	for coin_node in coins:
		# The CoinSpawner itself sits in this group and is a plain Node3D.
		var coin = coin_node as Area3D
		if coin:
			coin.collected = false
			coin.show()
			coin.get_node("MeshInstance3D").visible = true
			coin.get_node("CollisionShape3D").disabled = false
			var anim_player = coin.get_node("MeshInstance3D/Gold+Coin/AnimationPlayer")
			anim_player.stop()
			anim_player.play("CylinderAction_001")

func reset_sharks():
	var sharks = get_tree().get_nodes_in_group("sharks")
	for shark_node in sharks:
		# Both PatrolShark and Shark expose reset(); don't cast to one of them.
		if shark_node.has_method("reset"):
			shark_node.reset()

func reset():
	var player = get_node_or_null("/root/Main/Player")
	if player:
		player.is_dying = false
		var collision_shape = player.get_node_or_null("CollisionShape3D")
		if collision_shape:
			collision_shape.disabled = false

	time_left = total_time
	game_over = false
	
	game_timer.stop()
	game_timer.start()
	_update_hud()

func win():
	if game_over:
		return
	game_over = true
	game_timer.stop()

	# Stop music or play victory sound
	AudioManager.stop_music()
	winMusic.play()

	# Show win message on HUD
	if hud:
		hud.call("show_win_message")

	# Emit signal so other scripts can respond
	emit_signal("game_won")
	print("You won the game!")
	await winMusic.finished
	# Auto-start a new game after 2 seconds - only for testing... change with going to start screen
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://Scenes/start_menu.tscn")
	#GameManager.new_game()  # Assumes GameManager is autoloaded
