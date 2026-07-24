extends CharacterBody3D

# How fast the player moves in meters per second.
@export var speed = 14
# The downward acceleration when in the air, in meters per second squared.
@export var fall_acceleration = 10

var target_velocity = Vector3.ZERO
var angle = 30

func _physics_process(delta):
	# We create a local variable to store the input direction.
	var direction = Vector3.ZERO

	# We check for each move input and update the direction accordingly.
	if Input.is_action_pressed("swim_right"):
		direction.x -= 1
	if Input.is_action_pressed("swim_left"):
		direction.x += 1
	if Input.is_action_pressed("swim_backward"):
		# Notice how we are working with the vector's x and z axes.
		# In 3D, the XZ plane is the ground plane.
		direction.z -= 1
	if Input.is_action_pressed("swim_forward"):
		direction.z += 1
	if Input.is_action_pressed("swim_up"):
		direction.y += 0.2    # smaller vertical value for shallow angle
		direction.z += 0.8    # move forward while moving up
		
	if Input.is_action_pressed("swim_down"):
		direction.y -= 0.2    # smaller vertical value for shallow angle
		direction.z += 0.8    # move backward while moving down
		
	if direction != Vector3.ZERO:
		direction = direction.normalized()
		# Setting the basis property will affect the rotation of the node.
		$Pivot.basis = Basis.looking_at(-direction)
	# Full 3D velocity
	target_velocity = direction * speed

	# Vertical Velocity
	if not is_on_floor(): # If in the air, fall towards the floor. Literally gravity
		target_velocity.y = target_velocity.y - (fall_acceleration * delta)
	if is_on_floor():
		velocity.y = 0


	# Moving the Character
	velocity = target_velocity
	move_and_slide()
	
