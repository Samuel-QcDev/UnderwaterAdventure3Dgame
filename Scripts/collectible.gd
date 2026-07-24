extends Area3D

@onready var coinSound = $"MeshInstance3D/Gold+Coin/AudioStreamPlayer3D"
@onready var animation_player = $"MeshInstance3D/Gold+Coin/AnimationPlayer"

var collected := false

func _ready() -> void:
	if animation_player and not animation_player.is_playing():
		animation_player.play("CylinderAction_001")

func _on_body_entered(body: Node3D) -> void:
	if collected:
		return
	# Match how the sharks identify the player, so a renamed node still works.
	if body.is_in_group("Player"):
		collected = true
		coinSound.play()
		GameManager.add_coin()
		$CollisionShape3D.set_deferred("disabled", true)
		$MeshInstance3D.visible = false
		
		# Wait for the sound to finish, then remove the node
		await coinSound.finished
		hide()
		#queue_free()
