extends Area3D
class_name KeyPickup

# A glowing golden key the player swims into. Built entirely in code (no model
# exists for it). Picking one up counts toward opening the galleon treasure.

var collected := false
@export var spin_speed := 1.5
@export var bob_amp := 0.6

var _base_y := 0.0
var _t := 0.0


func _ready() -> void:
	add_to_group("keys")
	_base_y = position.y
	_build_visual()

	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 3.5   # generous pickup radius
	col.shape = shape
	add_child(col)

	body_entered.connect(_on_body_entered)


func _build_visual() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.84, 0.2)
	mat.metallic = 0.8
	mat.roughness = 0.25
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.72, 0.12)
	mat.emission_energy_multiplier = 1.8

	# Bow (the round head of the key).
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.55
	torus.outer_radius = 1.15
	ring.mesh = torus
	ring.material_override = mat
	ring.rotation.x = PI / 2.0
	ring.position = Vector3(0, 1.2, 0)
	add_child(ring)

	# Shaft.
	var shaft := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.32, 2.6, 0.32)
	shaft.mesh = box
	shaft.material_override = mat
	shaft.position = Vector3(0, -0.5, 0)
	add_child(shaft)

	# Two teeth at the tip.
	for i in 2:
		var tooth := MeshInstance3D.new()
		var tb := BoxMesh.new()
		tb.size = Vector3(0.7 - i * 0.2, 0.32, 0.32)
		tooth.mesh = tb
		tooth.material_override = mat
		tooth.position = Vector3(0.4 - i * 0.1, -1.5 - i * 0.5, 0)
		add_child(tooth)


func _process(delta: float) -> void:
	_t += delta
	rotate_y(spin_speed * delta)
	position.y = _base_y + sin(_t * 1.6) * bob_amp


func _on_body_entered(body: Node3D) -> void:
	if collected:
		return
	if body.is_in_group("Player"):
		collected = true
		GameManager.collect_key()
		set_deferred("monitoring", false)
		hide()
		queue_free()
