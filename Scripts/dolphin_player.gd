extends CharacterBody3D

# Mouse-steered dolphin.
#
#   Mouse      : aim (yaw + pitch) - the camera is a child of this body, so it
#                sits behind the dolphin at all times. No flip logic, no inversion.
#   W / Up     : swim forward along the aim
#   S / Down   : swim backward / brake
#   Shift      : sprint
#   Space      : rise toward the surface
#   Esc        : release the mouse (and pause-menu hook)

var is_dying := false

@export var speed := 28.0
@export var normal_speed := 28.0
@export var sprint_speed := 44.0
@export var rise_speed := 20.0

@export var mouse_sensitivity := 0.0022
@export var min_pitch_deg := -75.0
@export var max_pitch_deg := 75.0
# Turn smoothing: how quickly the body eases toward the mouse aim.
@export var turn_sharpness := 12.0

var water_level_y := 0.0
@export var gravity_above_water := 1200.0

# Aim state, driven by the mouse.
var yaw := 0.0
var pitch := 0.0

var original_basis: Basis

@onready var dolphin := $Dolphin
@onready var animation_player = $Dolphin/AnimationPlayer
@onready var camera_pivot = $CameraPivot
@onready var DieSound = AudioManager.get_node("Die")
@onready var GameOverSound = AudioManager.get_node("GameOver")
@onready var music = AudioManager.get_node("Music")


func _ready() -> void:
	original_basis = global_transform.basis
	yaw = rotation.y
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * mouse_sensitivity
		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, deg_to_rad(min_pitch_deg), deg_to_rad(max_pitch_deg))
	elif event.is_action_pressed("ui_cancel"):
		# Toggle the mouse free so the player can reach the window / menu,
		# instead of hard-quitting mid-dive.
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	if is_dying:
		velocity = Vector3.DOWN * 100.0
		move_and_slide()
		return

	# Ease the body yaw toward the mouse aim so turns read smoothly.
	var target_yaw := yaw
	rotation.y = lerp_angle(rotation.y, target_yaw, clamp(turn_sharpness * delta, 0.0, 1.0))

	# Forward direction from the aim (body yaw + pitch), independent of the body's
	# upright collision capsule.
	var aim := Basis(Vector3.UP, rotation.y) * Basis(Vector3.RIGHT, pitch)
	var forward := aim * Vector3(0, 0, -1)

	# Throttle: W / Up to go forward, S / Down to brake / reverse.
	var throttle := 0.0
	if Input.is_action_pressed("swim_forward") or Input.is_action_pressed("swim_up"):
		throttle += 1.0
	if Input.is_action_pressed("swim_backward") or Input.is_action_pressed("swim_down"):
		throttle -= 1.0

	speed = sprint_speed if Input.is_action_pressed("Sprint") else normal_speed

	var new_velocity := forward * (throttle * speed)

	# Space gives a straight lift toward the surface, on top of the aim.
	if Input.is_action_pressed("ui_accept"):
		new_velocity.y += rise_speed

	# Underwater the dolphin is neutrally buoyant (holds its depth). Only when it
	# breaches does gravity yank it back down, so it can't fly off.
	if global_transform.origin.y > water_level_y:
		new_velocity.y -= gravity_above_water * delta

	velocity = new_velocity
	move_and_slide()

	# Point the model along the aim. The Dolphin model's snout is on its +Z, so
	# aim -forward (Basis.looking_at points -Z at its target) to face it forward.
	if forward.length() > 0.001:
		var scale_backup: Vector3 = dolphin.scale
		dolphin.global_basis = Basis.looking_at(-forward, Vector3.UP)
		dolphin.scale = scale_backup

	# Animate only while actively swimming.
	if absf(throttle) > 0.0 or Input.is_action_pressed("ui_accept"):
		if not animation_player.is_playing():
			animation_player.play("Swim")
	else:
		if animation_player.is_playing():
			animation_player.stop()

	# Gently tilt the camera with the aim so diving/climbing reads, without ever
	# leaving the "behind the dolphin" framing.
	camera_pivot.rotation.x = lerp_angle(camera_pivot.rotation.x, pitch * 0.4, clamp(8.0 * delta, 0.0, 1.0))


func reset_rotation() -> void:
	global_transform.basis = original_basis
	yaw = 0.0
	pitch = 0.0
	rotation = Vector3.ZERO
	camera_pivot.rotation = Vector3.ZERO


func shrink() -> void:
	if GameManager.game_over:
		return
	if not PlayerState.has_shrunk:
		scale *= 0.4
		PlayerState.has_shrunk = true


func die() -> void:
	if GameManager.game_over:
		return
	if PlayerState.is_alive:
		PlayerState.is_alive = false
		music.stop()
		DieSound.play()
		is_dying = true
		set_physics_process(false)
		scale *= 0.2
		await get_tree().create_timer(1.0).timeout
		var collider = $CollisionShape3D
		if collider:
			collider.disabled = true
		set_physics_process(true)
		await DieSound.finished
		await get_tree().create_timer(0.5).timeout
		GameOverSound.play()
		await get_tree().create_timer(0.25).timeout
		get_tree().change_scene_to_file("res://Scenes/start_menu.tscn")
