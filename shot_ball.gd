extends CharacterBody2D

var speed: float = 2000.0
var animation_timer: float = 0.0
var frame_rate: float = 0.05 
var ball_color: String = "red"

func _physics_process(delta: float) -> void:
	var motion = transform.x * speed * delta
	var collision = move_and_collide(motion)
	
	if collision:
		var collider = collision.get_collider()
		
		if collider.is_in_group("track_ball"):
			
			var hit_ball = collider.get_parent()
			
			# Find the Track (which is the parent of the ball we hit)
			var track = hit_ball.get_parent()
			
			# Find the exact math coordinate on the track closest to where we crashed
			var hit_progress = track.curve.get_closest_offset(global_position)
			# Tell the track to run our new insertion function!
			track.insert_ball(hit_ball, hit_progress, $Sprite2D.texture)
		
			queue_free()
		else:
			var bounce_direction = motion.bounce(collision.get_normal())
			rotation = bounce_direction.angle()
		
	animation_timer += delta
	if animation_timer >= frame_rate:
		animation_timer = 0.0
		$Sprite2D.frame = ($Sprite2D.frame + 1) % 10
