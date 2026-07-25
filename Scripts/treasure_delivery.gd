extends Area3D
class_name TreasureDelivery

# Sits on the galleon's chest. When the player reaches it, ask the GameManager
# to open the treasure (wins only if all keys have been collected).

func _ready() -> void:
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 10.0
	col.shape = shape
	add_child(col)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		GameManager.deliver_treasure()
