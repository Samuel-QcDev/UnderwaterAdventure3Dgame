extends CharacterBody3D
class_name Shark 

var start_position: Vector3

@export var speed = 10.0
@export var target_path: NodePath
var target: Node3D

var dolphin = null
var is_shrunk = false

@onready var damage = $DamageSound
@onready var shrink = $PowerDown
@onready var animation_player = $MeshInstance3D/Shark2/AnimationPlayer

func _ready():
	start_position = global_transform.origin
	target = get_node(target_path)
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		dolphin = players[0]

func reset():
	global_transform = Transform3D(global_transform.basis, start_position)
	velocity = Vector3.ZERO
	visible = true
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

	if not target:
		return

	var direction = (target.global_transform.origin - global_transform.origin).normalized()
	velocity = direction * speed
	move_and_slide()
	look_at(target.global_transform.origin, Vector3.UP)
	if not animation_player.is_playing():
		animation_player.play("ArmatureAction")

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"): 
		if not PlayerState.has_shrunk:
			shrink.play()
			body.shrink()
#			dolphin.scale *= 0.5
#			PlayerState.has_shrunk = true
			back_up()
		else:
			back_up()
			damage.play()
			body.die()
			
var back_up_distance = 3.5
var back_up_duration = 2.5

func back_up():
	var backward_dir = transform.basis.z.normalized()
	var target_pos = position + backward_dir * back_up_distance
	var tween = create_tween()
	tween.tween_property(self, "position", target_pos, back_up_duration)
