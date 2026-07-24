extends Node3D

# Ambient sea life: schools of fish, octopuses on the sea bed, and a single
# whale cruising the open water.
#
# Everything here is decorative - no physics bodies - so it can never trap the
# player or interfere with the coins, sharks and boundaries.
#
# The fish are drawn through a MultiMesh (one draw call per school) because the
# level already carries ~4900 nodes; a node per fish would be wasteful. There is
# no fish model in 3D_Models, so the fish mesh is built in code to match the
# game's low-poly look. The octopus and whale use the real models.

const OCTOPUS_SCENE: PackedScene = preload("res://3D_Models/FishModels/Octopus.glb")
const WHALE_SCENE: PackedScene = preload("res://3D_Models/FishModels/Whale.blend")

@export var school_count: int = 26
@export var fish_per_school: int = 36
@export var octopus_count: int = 14
@export var spawn_whale: bool = true

# The player starts around (60, -70, 138); put the first school in plain sight
# so the ocean reads as alive immediately instead of only on a lucky encounter.
@export var first_school_near: Vector3 = Vector3(55.0, -52.0, 105.0)

# Kept just inside Boundaries.tscn's walls (x +/-450, z -500..300).
@export var min_x: float = -420.0
@export var max_x: float = 420.0
@export var min_z: float = -470.0
@export var max_z: float = 270.0
@export var floor_y: float = -70.0
@export var min_swim_y: float = -62.0
@export var max_swim_y: float = -10.0

@export var school_speed_min: float = 3.0
@export var school_speed_max: float = 7.0

# Whale cruise: a slow circle through the middle of the map.
@export var whale_scale: float = 4.5
@export var whale_radius: float = 230.0
@export var whale_centre: Vector3 = Vector3(0, -22, -110)
@export var whale_speed: float = 0.055  # radians/second

var _schools: Array = []
var _octopuses: Array = []
var _whale: Node3D = null
var _whale_angle: float = 0.0
var _rng := RandomNumberGenerator.new()
var _time: float = 0.0

const FISH_PALETTE: Array[Color] = [
	Color(1.0, 0.62, 0.18),   # clownfish orange
	Color(0.98, 0.85, 0.30),  # yellow tang
	Color(0.35, 0.72, 0.95),  # blue chromis
	Color(0.85, 0.35, 0.45),  # rosy
	Color(0.60, 0.85, 0.72),  # pale green
]


func _ready() -> void:
	_rng.randomize()
	var fish_mesh := _build_fish_mesh()
	var fish_material := _build_fish_material()

	for i in school_count:
		var school := _spawn_school(fish_mesh, fish_material)
		if i == 0:
			school["centre"] = first_school_near
		_schools.append(school)

	for i in octopus_count:
		_octopuses.append(_spawn_octopus(i))

	if spawn_whale:
		_spawn_whale()


# --- fish -------------------------------------------------------------------

func _build_fish_mesh() -> ArrayMesh:
	# Low-poly fish pointing down -Z, matching the game's forward axis.
	var nose := Vector3(0, 0, -0.65)
	var top := Vector3(0, 0.20, -0.05)
	var bot := Vector3(0, -0.20, -0.05)
	var lft := Vector3(-0.16, 0, -0.05)
	var rgt := Vector3(0.16, 0, -0.05)
	var tail_base := Vector3(0, 0, 0.38)
	var fin_top := Vector3(0, 0.30, 0.62)
	var fin_bot := Vector3(0, -0.30, 0.62)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Snout
	_tri(st, nose, top, rgt)
	_tri(st, nose, rgt, bot)
	_tri(st, nose, bot, lft)
	_tri(st, nose, lft, top)
	# Body tapering to the tail
	_tri(st, tail_base, rgt, top)
	_tri(st, tail_base, bot, rgt)
	_tri(st, tail_base, lft, bot)
	_tri(st, tail_base, top, lft)
	# Tail fin, both windings so it stays visible edge-on
	_tri(st, tail_base, fin_top, fin_bot)
	_tri(st, tail_base, fin_bot, fin_top)
	st.generate_normals()
	return st.commit()


func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)


func _build_fish_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true   # lets one material colour every school
	mat.roughness = 0.55
	mat.metallic = 0.0
	return mat


func _spawn_school(mesh: ArrayMesh, material: StandardMaterial3D) -> Dictionary:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = fish_per_school

	var node := MultiMeshInstance3D.new()
	node.multimesh = mm
	node.material_override = material
	# Fish are tiny next to the 9-unit dolphin, so keep them visible from afar.
	node.extra_cull_margin = 16.0
	add_child(node)

	var school := {
		"multimesh": mm,
		"centre": Vector3(
			_rng.randf_range(min_x, max_x),
			_rng.randf_range(min_swim_y, max_swim_y),
			_rng.randf_range(min_z, max_z)),
		"velocity": Vector3.ZERO,
		"offsets": [],
		"phases": [],
		"scales": [],
		"spread": _rng.randf_range(4.0, 9.0),
	}

	var heading := Vector3(_rng.randf_range(-1, 1), 0, _rng.randf_range(-1, 1)).normalized()
	school["velocity"] = heading * _rng.randf_range(school_speed_min, school_speed_max)

	var spread: float = school["spread"]
	for i in fish_per_school:
		school["offsets"].append(Vector3(
			_rng.randf_range(-spread, spread),
			_rng.randf_range(-spread * 0.4, spread * 0.4),
			_rng.randf_range(-spread, spread)))
		school["phases"].append(_rng.randf_range(0.0, TAU))
		school["scales"].append(_rng.randf_range(0.8, 1.5))

	# Slight per-fish colour variation so a school isn't flat.
	var base: Color = FISH_PALETTE[_rng.randi() % FISH_PALETTE.size()]
	for i in fish_per_school:
		var shade := _rng.randf_range(0.82, 1.15)
		mm.set_instance_color(i, Color(base.r * shade, base.g * shade, base.b * shade))

	return school


func _update_school(school: Dictionary, delta: float) -> void:
	var centre: Vector3 = school["centre"]
	var velocity: Vector3 = school["velocity"]

	centre += velocity * delta

	# Turn the school around at the walls instead of letting it drift away.
	if centre.x < min_x or centre.x > max_x:
		velocity.x = -velocity.x
		centre.x = clamp(centre.x, min_x, max_x)
	if centre.z < min_z or centre.z > max_z:
		velocity.z = -velocity.z
		centre.z = clamp(centre.z, min_z, max_z)
	if centre.y < min_swim_y or centre.y > max_swim_y:
		velocity.y = -velocity.y
		centre.y = clamp(centre.y, min_swim_y, max_swim_y)

	# Gentle wandering so the paths don't look like billiard balls.
	velocity = velocity.rotated(Vector3.UP, sin(_time * 0.27 + centre.x * 0.01) * delta * 0.6)
	velocity.y += sin(_time * 0.4 + centre.z * 0.02) * delta * 0.5
	velocity.y = clamp(velocity.y, -2.0, 2.0)

	school["centre"] = centre
	school["velocity"] = velocity

	var mm: MultiMesh = school["multimesh"]
	var offsets: Array = school["offsets"]
	var phases: Array = school["phases"]
	var scales: Array = school["scales"]
	var heading := velocity.normalized()
	if heading.is_zero_approx():
		heading = Vector3.FORWARD

	for i in mm.instance_count:
		var phase: float = phases[i]
		# Weave each fish around its slot so the school breathes.
		var sway := Vector3(
			sin(_time * 1.6 + phase) * 0.9,
			sin(_time * 1.1 + phase * 1.7) * 0.5,
			cos(_time * 1.4 + phase) * 0.9)
		var pos: Vector3 = centre + offsets[i] + sway

		var basis := Basis.looking_at(heading)
		# Roll a little; reads as a tail beat at this size.
		basis = basis.rotated(heading, sin(_time * 5.0 + phase) * 0.28)
		var s: float = scales[i]
		mm.set_instance_transform(i, Transform3D(basis.scaled(Vector3(s, s, s)), pos))


# --- octopuses --------------------------------------------------------------

func _spawn_octopus(index: int) -> Dictionary:
	var oct := OCTOPUS_SCENE.instantiate()
	add_child(oct)
	oct.name = "Octopus%d" % index

	var scale_factor := _rng.randf_range(0.9, 1.5)
	oct.scale = Vector3.ONE * scale_factor

	# The model's origin is not its base, so lift it by the mesh's lowest point
	# to rest it on the sea bed rather than sinking it.
	var local_bottom := _lowest_point(oct)
	var rest_y := floor_y - local_bottom * scale_factor + 0.4

	oct.position = Vector3(
		_rng.randf_range(min_x, max_x),
		rest_y,
		_rng.randf_range(min_z, max_z))
	oct.rotation.y = _rng.randf_range(0.0, TAU)

	return {
		"node": oct,
		"phase": _rng.randf_range(0.0, TAU),
		"bob_speed": _rng.randf_range(0.45, 0.85),
		"base_y": rest_y,
		"spin": _rng.randf_range(-0.15, 0.15),
	}


func _lowest_point(n: Node3D) -> float:
	var lowest := 0.0
	var found := false
	var stack: Array = [n]
	while stack.size() > 0:
		var node = stack.pop_back()
		if node is MeshInstance3D:
			var a: AABB = node.get_aabb()
			if not found or a.position.y < lowest:
				lowest = a.position.y
				found = true
		for c in node.get_children():
			stack.append(c)
	return lowest


func _update_octopus(oct: Dictionary, delta: float) -> void:
	var node: Node3D = oct["node"]
	# Breathe up and down just off the sea bed, turning slowly on the spot.
	node.position.y = oct["base_y"] + sin(_time * oct["bob_speed"] + oct["phase"]) * 0.9
	node.rotation.y += oct["spin"] * delta


# --- whale ------------------------------------------------------------------

func _spawn_whale() -> void:
	_whale = WHALE_SCENE.instantiate()
	add_child(_whale)
	_whale.scale = Vector3.ONE * whale_scale

	# The .blend carries Blender's viewport camera and lamp; a stray Camera3D
	# can steal the viewport, so drop both.
	for child in _whale.get_children():
		if child is Camera3D or child is Light3D:
			child.queue_free()

	var anim := _whale.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if anim and anim.has_animation("Swim"):
		var swim := anim.get_animation("Swim")
		swim.loop_mode = Animation.LOOP_LINEAR
		anim.play("Swim")
		anim.speed_scale = 0.6   # unhurried, it's a whale

	_whale_angle = _rng.randf_range(0.0, TAU)


func _update_whale(delta: float) -> void:
	_whale_angle += whale_speed * delta
	var pos := whale_centre + Vector3(
		cos(_whale_angle) * whale_radius,
		sin(_time * 0.12) * 6.0,
		sin(_whale_angle) * whale_radius)
	# Tangent of the circle, which is where the whale is heading.
	var heading := Vector3(-sin(_whale_angle), 0, cos(_whale_angle)).normalized()
	_whale.global_position = pos
	_whale.basis = Basis.looking_at(heading).scaled(Vector3.ONE * whale_scale)


func _process(delta: float) -> void:
	_time += delta
	for school in _schools:
		_update_school(school, delta)
	for oct in _octopuses:
		_update_octopus(oct, delta)
	if _whale:
		_update_whale(delta)
