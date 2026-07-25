extends Node3D

# Builds the "galleon treasure hunt" in a compact, structured reef arena.
#
#   Goal: find the 3 hidden keys (Reef, Kelp, Grotto), then bring them to the
#   galleon's chest to open the treasure and win.
#
# Each key sits in a themed pocket of the arena; two of them are guarded by a
# patrolling shark (repositioned in Main.tscn). Coins remain only as optional
# bonus gold, scattered lightly - they no longer decide the win.

const CHEST := preload("res://Scenes/chest.tscn")
const PIRATE := preload("res://3D_Models/Ocean/pirate_ship.glb")
const CORAL := preload("res://3D_Models/Ocean/small_coral.glb")
const KELP := preload("res://3D_Models/Ocean/long_plant.glb")
const ROCKS := preload("res://3D_Models/Ocean/Rocks.glb")
const COIN := preload("res://Scenes/collectible.tscn")
const KEY := preload("res://Scripts/key_pickup.gd")
const DELIVERY := preload("res://Scripts/treasure_delivery.gd")

@export var floor_y: float = -70.0
@export var galleon_pos: Vector3 = Vector3(0, -68, 40)

# Key pockets: name, centre, decor style.
var zones := [
	{"pos": Vector3(-115, -63, -30), "decor": "coral"},   # Reef
	{"pos": Vector3(115, -63, -40), "decor": "kelp"},      # Kelp forest
	{"pos": Vector3(0, -61, -120), "decor": "rocks"},      # Grotto
]

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_clear_redundant_props()
	_build_galleon()
	for z in zones:
		_build_zone(z["pos"], z["decor"])
	_scatter_bonus_gold()


func _clear_redundant_props() -> void:
	# The old sandbox left a crashed ship, a stray chest and a batch of
	# hand-placed coins near the origin; they clash with the galleon goal, so
	# remove them and let this script own the objective props.
	for name in ["crashed_ship", "chest", "Collectibles"]:
		var n := get_parent().get_node_or_null(name)
		if n:
			n.queue_free()


func _spawn(scene: PackedScene, pos: Vector3, yaw: float, scl: float) -> Node3D:
	var n := scene.instantiate() as Node3D
	add_child(n)
	n.position = pos
	n.rotation.y = yaw
	n.scale = Vector3.ONE * scl
	return n


func _build_galleon() -> void:
	# The landmark goal.
	_spawn(PIRATE, Vector3(galleon_pos.x, floor_y + 1.0, galleon_pos.z), 0.5, 1.8)
	# The treasure chest beside it.
	var chest_pos := Vector3(galleon_pos.x + 2, floor_y + 0.5, galleon_pos.z + 10)
	_spawn(CHEST, chest_pos, PI, 2.2)
	# The delivery trigger over the chest.
	var d := DELIVERY.new()
	add_child(d)
	d.position = chest_pos + Vector3(0, 2, 0)


func _build_zone(centre: Vector3, decor: String) -> void:
	match decor:
		"coral":
			for i in 10:
				var a := _rng.randf() * TAU
				var d := _rng.randf() * 16.0
				var p := centre + Vector3(cos(a) * d, 0, sin(a) * d)
				p.y = floor_y + 0.2
				_spawn(CORAL, p, _rng.randf() * TAU, _rng.randf_range(1.2, 2.6))
		"kelp":
			for i in 9:
				var p := centre + Vector3(_rng.randf_range(-16, 16), 0, _rng.randf_range(-16, 16))
				p.y = floor_y - 2.0
				_spawn(KELP, p, _rng.randf() * TAU, _rng.randf_range(0.24, 0.4))
		"rocks":
			for i in 8:
				var a := _rng.randf() * TAU
				var d := _rng.randf_range(6.0, 20.0)
				var p := centre + Vector3(cos(a) * d, 0, sin(a) * d)
				p.y = floor_y + 0.2
				_spawn(ROCKS, p, _rng.randf() * TAU, _rng.randf_range(1.5, 3.0))

	# The key floats at the heart of the pocket.
	var key := KEY.new()
	add_child(key)
	key.position = centre + Vector3(0, 5, 0)


func _spawn_coin(pos: Vector3) -> void:
	var c := COIN.instantiate() as Node3D
	add_child(c)
	c.global_position = pos
	c.scale = Vector3.ONE * 0.7


func _scatter_bonus_gold() -> void:
	# A light sprinkle of optional gold along the way (not required to win).
	var anchors := [galleon_pos, zones[0]["pos"], zones[1]["pos"], zones[2]["pos"]]
	for anchor in anchors:
		for k in 4:
			var off := Vector3(_rng.randf_range(-18, 18), _rng.randf_range(2, 12), _rng.randf_range(-18, 18))
			_spawn_coin(anchor + off)
