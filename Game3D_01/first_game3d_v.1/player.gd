extends CharacterBody3D

# How fast the player moves in meters per second.
@export var speed = 14
# The downward acceleration when in the air, in meters per second squared.
@export var fall_acceleration = 75

@export var jump_impulse = 30
# Vertical impulse applied to the character upon bouncing over a mob in
# meters per second.
@export var bounce_impulse = 16
# Emitted when the player was hit by a mob.
# Put this at the top of the script.
signal hit


var target_velocity = Vector3.ZERO


func _physics_process(delta):
	var direction = Vector3.ZERO
	

	if Input.is_action_pressed("Move_right"):
		direction.x += 1
	if Input.is_action_pressed("Move_left"):
		direction.x -= 1
	if Input.is_action_pressed("Move_back"):
		direction.z += 1
	if Input.is_action_pressed("Move_forward"):
		direction.z -= 1

	if direction != Vector3.ZERO:
		direction = direction.normalized()
		# Setting the basis property will affect the rotation of the node.
		$Privot.basis = Basis.looking_at(direction)
		
		
	# Iterate through all collisions that occurred this frame
	for index in range(get_slide_collision_count()):
		# We get one of the collisions with the player
		var collision = get_slide_collision(index)

		# If there are duplicate collisions with a mob in a single frame
		# the mob will be deleted after the first collision, and a second call to
		# get_collider will return null, leading to a null pointer when calling
		# collision.get_collider().is_in_group("mob").
		# This block of code prevents processing duplicate collisions.
		if collision.get_collider() == null:
			continue

		# If the collider is with a mob
		if collision.get_collider().is_in_group("mob"):
			var mob = collision.get_collider()
			# we check that we are hitting it from above.
			if Vector3.UP.dot(collision.get_normal()) > 0.1:
				# If so, we squash it and bounce.
				mob.squash()
				target_velocity.y = bounce_impulse
				# Prevent further duplicate calls.
				break

	# Jumping.
	if is_on_floor() and Input.is_action_just_pressed("Jump"):
		target_velocity.y = jump_impulse
	
	# Ground Velocity
	target_velocity.x = direction.x * speed
	target_velocity.z = direction.z * speed

	# Vertical Velocity
	if not is_on_floor(): # If in the air, fall towards the floor. Literally gravity
		target_velocity.y = target_velocity.y - (fall_acceleration * delta)

	# Moving the Character
	velocity = target_velocity
	move_and_slide()

# And this function at the bottom.
func die():
	hit.emit()
	queue_free()

func _on_mob_detector_body_entered(body: Node3D) -> void:
	die()
