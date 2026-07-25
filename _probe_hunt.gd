extends SceneTree

var fails := 0
func chk(n: String, ok: bool, d := "") -> void:
	if not ok: fails += 1
	print("%s  %s %s" % ["PASS" if ok else "FAIL", n, d])

func _initialize():
	var PlayerState = root.get_node("PlayerState")
	var GameManager = root.get_node("GameManager")
	var main = load("res://Scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await create_timer(1.5).timeout

	# 3 keys exist
	var keys := get_nodes_in_group("keys").size()
	chk("three_keys", keys == 3, "(%d keys)" % keys)

	# 2 shark guardians
	var sharks := 0
	for s in get_nodes_in_group("sharks"):
		if s is CharacterBody3D: sharks += 1
	chk("two_guardians", sharks == 2, "(%d sharks)" % sharks)

	# delivery zone exists on the galleon
	var deliveries := 0
	for n in main.get_node("LevelLayout").get_children():
		if n is TreasureDelivery: deliveries += 1
	chk("delivery_zone", deliveries == 1, "(%d)" % deliveries)

	# collecting keys does NOT win; delivering without all keys does NOT win
	PlayerState.keys_collected = 0
	GameManager.game_over = false
	GameManager.collect_key()
	GameManager.collect_key()
	chk("partial_no_win", not GameManager.game_over and PlayerState.keys_collected == 2,
		"(keys=%d, over=%s)" % [PlayerState.keys_collected, GameManager.game_over])
	GameManager.deliver_treasure()
	chk("locked_without_keys", not GameManager.game_over, "(over=%s)" % GameManager.game_over)

	# third key + delivery wins
	GameManager.collect_key()
	GameManager.deliver_treasure()
	await process_frame
	chk("deliver_wins", GameManager.game_over, "(keys=%d, over=%s)" % [PlayerState.keys_collected, GameManager.game_over])

	# arena is compact: boundaries pulled in
	var north = main.get_node_or_null("Boundaries/NorthWall/CollisionShape3D")
	chk("compact_arena", north != null and absf(north.global_position.z) < 200,
		"(north.z=%.0f)" % (north.global_position.z if north else 999))

	print("HUNT_FAILURES=", fails)
	quit()
