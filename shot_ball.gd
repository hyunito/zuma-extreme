extends CharacterBody2D

var speed = 1000.0 
func _physics_process(delta):
	var motion = transform.x * speed * delta
	var collision = move_and_collide(motion)
	
	if collision:
		var bounce_direction = motion.bounce(collision.get_normal())
		rotation = bounce_direction.angle()
		
	# NEW LINE: This spins the image like a wheel every frame!
	# You can change the "15.0" to make it spin faster or slower.
	$Sprite2D.rotation += 15.0 * delta
