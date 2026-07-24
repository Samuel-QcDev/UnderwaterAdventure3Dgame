extends Node3D

@export var coin_scene: PackedScene
@export var number_of_coins: int = 50

@export var min_x: float = -450  # West wall
@export var max_x: float = 450   # East wall
@export var min_y: float = -70   # Ocean floor
@export var max_y: float = 0     # Water surface
@export var min_z: float = -500  # North wall
@export var max_z: float = 300   # South wall

func _ready() -> void:
	randomize()
	spawn_coins()

func spawn_coins():
	var clusters = 25
	var cluster_radius = 20.0
	var clustered_coin_count = int(number_of_coins * 0.8)
	# Integer division truncates, so fold the remainder back into the scattered
	# coins instead of silently spawning fewer than number_of_coins.
	var coins_per_cluster = clustered_coin_count / clusters
	var scattered_coin_count = number_of_coins - coins_per_cluster * clusters

	# Generate cluster centers
	var cluster_centers = []
	for i in range(clusters):
		var cx = randf_range(min_x, max_x)
		var cy = randf_range(min_y, max_y)
		var cz = randf_range(min_z, max_z)
		cluster_centers.append(Vector3(cx, cy, cz))

	# Spawn clustered coins
	for center in cluster_centers:
		for j in range(coins_per_cluster):
			var offset = Vector3(
				randf_range(-cluster_radius, cluster_radius),
				randf_range(-cluster_radius, cluster_radius),
				randf_range(-cluster_radius, cluster_radius)
			)
			var position = center + offset
			spawn_coin_at(position)

	# Spawn scattered coins
	for k in range(scattered_coin_count):
		var x = randf_range(min_x, max_x)
		var y = randf_range(min_y, max_y)
		var z = randf_range(min_z, max_z)
		var position = Vector3(x, y, z)
		spawn_coin_at(position)

func spawn_coin_at(position: Vector3) -> void:
	var coin = coin_scene.instantiate()
	add_child(coin)
	coin.global_transform = Transform3D(Basis(), position)
	var anim_player = coin.get_node("MeshInstance3D/Gold+Coin/AnimationPlayer") as AnimationPlayer
	if anim_player:
		anim_player.play("CylinderAction_001")
