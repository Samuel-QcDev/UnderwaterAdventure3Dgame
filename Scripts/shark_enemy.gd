extends CharacterBody3D
class_name PatrolShark

@export var speed = 8.0
@export var chase_radius: float = 40.0
@export var patrol_radius: float = 50.0
@export var target_path: NodePath  # Usually the dolphin/player

var target: Node3D
var start_position: Vector3
var dolphin = null
var is_patrolling = true
var patrol_target: Vector3

@onready var damage = $DamageSound
@onready var shrink = $PowerDown
@onready var animation_player = $VisualRoot/MeshInstance3D/Shark2/AnimationPlayer

func _ready():
	start_position = global_transform.origin
	target = get_node(target_path)
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		dolphin = players[0]
	choose_new_patrol_target()

func reset():
	global_transform = Transform3D(global_transform.basis, start_position)
	velocity = Vector3.ZERO
	visible = true
	is_patrolling = true
	choose_new_patrol_target()

	if not animation_player.is_playing():
		animation_player.play("ArmatureAction")

	var shape1 = get_node_or_null("Area3D/CollisionShape3D")
	if shape1:
		shape1.disabled = false
	else:
		print("CollisionShape3D not found in ", self.name)

	var shape2 = get_node_or_null("CollisionShape3D_2")
	if shape2:
		shape2.disabled = false
	else:
		print("CollisionShape3D_2 not found in ", self.name)

func _physics_process(delta):
	if GameManager.game_over:
		if not animation_player.is_playing():
			animation_player.play("ArmatureAction")
		return

	if not dolphin:
		return

	var distance_to_player = global_transform.origin.distance_to(dolphin.global_transform.origin)

	if distance_to_player <= chase_radius:
		chase_player()
		is_patrolling = false
	else:
		if not is_patrolling:
			is_patrolling = true
			choose_new_patrol_target()
		patrol(delta)

	if not animation_player.is_playing():
		animation_player.play("ArmatureAction")

func chase_player():
	var direction = (dolphin.global_transform.origin - global_transform.origin).normalized()
	velocity = direction * speed
	move_and_slide()
	look_at(dolphin.global_transform.origin, Vector3.UP)

func patrol(delta):
	var direction = (patrol_target - global_transform.origin)
	if direction.length() < 1.0:
		choose_new_patrol_target()
	else:
		var dir_norm = direction.normalized()
		velocity = dir_norm * (speed * 0.5)  # Patrol more slowly
		move_and_slide()
		look_at(patrol_target, Vector3.UP)

func choose_new_patrol_target():
	var angle = randf() * TAU
	var distance = randf_range(5.0, patrol_radius)
	var offset = Vector3(cos(angle), 0, sin(angle)) * distance
	patrol_target = start_position + offset

# Collision logic when touching the player
func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"): 
		if not PlayerState.has_shrunk:
			shrink.play()
			body.shrink()
			back_up()
		else:
			back_up()
			damage.play()
			body.die()

# Retreat briefly after contact
var back_up_distance = 10.5
var back_up_duration = 1.5

func back_up():
	var backward_dir = transform.basis.z.normalized()
	var target_pos = position + backward_dir * back_up_distance
	var tween = create_tween()
	tween.tween_property(self, "position", target_pos, back_up_duration)
