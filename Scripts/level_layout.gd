extends Node3D

# Builds the guided "treasure journey": landmark zones connected by a trail of
# coins, so the flat sandbox becomes a path the player follows.
#
#   1 Shallows (start)  -> 2 Kelp forest -> 3 Pirate wreck
#                                        -> 4 Submarine / grotto -> 5 Deep pit
#
# Coins are laid along the polyline between the zone centres, with denser
# clusters (and treasure chests) at the landmarks. The random CoinSpawner is
# disabled in Main.tscn so coins come only from this designed layout.

const COIN := preload("res://Scenes/collectible.tscn")
const CHEST := preload("res://Scenes/chest.tscn")
const CORAL := preload("res://3D_Models/Ocean/small_coral.glb")
const PIRATE := preload("res://3D_Models/Ocean/pirate_ship.glb")
const SUB := preload("res://3D_Models/Ocean/submarine.glb")
const KELP := preload("res://3D_Models/Ocean/long_plant.glb")

@export var floor_y: float = -70.0

# Ordered zone centres of the journey (the coin trail follows this polyline).
var path: Array[Vector3] = [
	Vector3(60, -60, 128),     # 1 shallows / start
	Vector3(-30, -58, 35),     # 2 kelp forest
	Vector3(-180, -60, -110),  # 3 pirate wreck
	Vector3(150, -58, -230),   # 4 submarine / grotto
	Vector3(250, -62, -420),   # 5 deep pit (final treasure)
]

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_build_landmarks()
	_lay_coin_trail()


func _spawn(scene: PackedScene, pos: Vector3, yaw: float, scl: float) -> Node3D:
	var n := scene.instantiate() as Node3D
	add_child(n)
	n.position = pos
	n.rotation.y = yaw
	n.scale = Vector3.ONE * scl
	return n


func _coral_cluster(centre: Vector3, count: int, radius: float) -> void:
	for i in count:
		var a := _rng.randf() * TAU
		var d := _rng.randf() * radius
		var p := centre + Vector3(cos(a) * d, 0, sin(a) * d)
		p.y = floor_y + 0.2
		_spawn(CORAL, p, _rng.randf() * TAU, _rng.randf_range(1.0, 2.4))


func _build_landmarks() -> void:
	# Zone 1 - welcoming reef in the shallows
	_coral_cluster(path[0], 9, 24)

	# Zone 2 - kelp forest (big plants) + coral
	for i in 12:
		var p := path[1] + Vector3(_rng.randf_range(-28, 28), 0, _rng.randf_range(-28, 28))
		p.y = floor_y - 2.0
		_spawn(KELP, p, _rng.randf() * TAU, _rng.randf_range(0.22, 0.36))
	_coral_cluster(path[1], 5, 22)

	# Zone 3 - pirate wreck + guarded chest
	_spawn(PIRATE, Vector3(path[2].x, floor_y + 1.0, path[2].z), _rng.randf() * TAU, 1.7)
	_spawn(CHEST, Vector3(path[2].x + 9, floor_y + 0.4, path[2].z + 6), 0.6, 1.7)

	# Zone 4 - half-buried submarine + rocks
	_spawn(SUB, Vector3(path[3].x, floor_y + 1.5, path[3].z), 0.8, 2.6)
	_coral_cluster(path[3], 6, 24)

	# Zone 5 - deep pit hoard
	_spawn(SUB, Vector3(path[4].x - 16, floor_y + 1.0, path[4].z + 12), 2.2, 2.0)
	_spawn(CHEST, Vector3(path[4].x, floor_y + 0.4, path[4].z), 0.0, 2.1)
	_spawn(CHEST, Vector3(path[4].x + 7, floor_y + 0.4, path[4].z + 5), 1.2, 1.9)


func _spawn_coin(pos: Vector3) -> void:
	var c := COIN.instantiate() as Node3D
	add_child(c)
	c.global_position = pos
	# The coin's visual mesh is oversized next to the dolphin; scale it down to
	# a coin-like proportion (its collision sphere still covers pickup).
	c.scale = Vector3.ONE * 0.7


func _lay_coin_trail() -> void:
	# Breadcrumb of coins along the polyline between zones.
	for i in range(path.size() - 1):
		var a: Vector3 = path[i]
		var b: Vector3 = path[i + 1]
		var count := int(a.distance_to(b) / 15.0)
		for j in range(1, count):
			var p: Vector3 = a.lerp(b, float(j) / count)
			p += Vector3(_rng.randf_range(-6, 6), _rng.randf_range(-4, 10), _rng.randf_range(-6, 6))
			_spawn_coin(p)

	# Denser hoards at each zone (grows toward the deep pit).
	var cluster_counts := [6, 8, 12, 10, 16]
	for i in path.size():
		for k in cluster_counts[i]:
			var off := Vector3(_rng.randf_range(-14, 14), _rng.randf_range(-2, 12), _rng.randf_range(-14, 14))
			_spawn_coin(path[i] + off)
