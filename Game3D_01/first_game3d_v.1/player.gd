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
	# We create a local variable to store the input direction
	var direction = Vector3.ZERO

	# We check for each move input and update the direction accordingly
	if Input.is_action_pressed("Move_right"):
		direction.x = direction.x + 1
	if Input.is_action_pressed("Move_left"):
		direction.x = direction.x - 1
	if Input.is_action_pressed("Move_back"):
		# Notice how we are working with the vector's x and z axes.
		# In 3D, the XZ plane is the ground plane.
		direction.z = direction.z + 1
	if Input.is_action_pressed("Move_forward"):
		direction.z = direction.z - 1

	# Prevent diagonal movement being very fast
	if direction != Vector3.ZERO:
		direction = direction.normalized()
		# Setting the basis property will affect the rotation of the node.
		$RootNode.basis = Basis.looking_at(direction)
		$AnimationPlayer.speed_scale = 1
		$AnimationPlayer.play("CharacterArmature|CharacterArmature|CharacterArmature|Run")
	else:
		$AnimationPlayer.speed_scale = 4
		$AnimationPlayer.play("CharacterArmature|CharacterArmature|CharacterArmature|Idle")

	# Ground Velocity
	target_velocity.x = direction.x * speed
	target_velocity.z = direction.z * speed

	# Vertical Velocity
	if not is_on_floor(): # If in the air, fall towards the floor
		target_velocity.y = target_velocity.y - (fall_acceleration * delta)

	# Jumping.
	if is_on_floor() and Input.is_action_just_pressed("Jump"):
		target_velocity.y = jump_impulse
		$AnimationPlayer.play("CharacterArmature|CharacterArmature|CharacterArmature|Jump")

	# Iterate through all collisions that occurred this frame
	# in C this would be for(int i = 0; i < collisions.Count; i++)
	for index in range(get_slide_collision_count()):
		# We get one of the collisions with the player
		var collision = get_slide_collision(index)

		# If the collision is with ground
		if collision.get_collider() == null:
			continue

		# If the collider is with a mob
		if collision.get_collider().is_in_group("mob"):
			var mob = collision.get_collider()
			# we check that we are hitting it from above.
			if Vector3.UP.dot(collision.get_normal()) > 0.1:
				# If so, we squash it and bounce.
				$sfx_kill.play()
				mob.squash()
				target_velocity.y = bounce_impulse
				# Prevent further duplicate calls.
				break

	# Moving the Character
	velocity = target_velocity
	move_and_slide()

	$RootNode.rotation.x = PI / 6 * velocity.y / jump_impulse

# And this function at the bottom.
func die():
	hit.emit()
	queue_free()

func _on_mob_detector_body_entered(body: Node3D) -> void:
	die()
