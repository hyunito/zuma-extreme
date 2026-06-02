extends CharacterBody2D

var speed: float = 2000.0
var animation_timer: float = 0.0
var frame_rate: float = 0.05 
var ball_color: String = "red"
var shooter: String = "player" 


func _physics_process(delta: float) -> void:
	var motion = transform.x * speed * delta
	var collision = move_and_collide(motion)
	
	if collision:
		var collider = collision.get_collider()
		
		if collider.is_in_group("track_ball"):
			var hit_ball = collider.get_parent()
			var track = hit_ball.get_parent()
			var hit_progress = track.curve.get_closest_offset(global_position)
			track.insert_ball(hit_ball, hit_progress, ball_color, $Sprite2D.texture, shooter)
			queue_free()
		else:
			var bounce_direction = motion.bounce(collision.get_normal())
			rotation = bounce_direction.angle()
		
	animation_timer += delta
	if animation_timer >= frame_rate:
		animation_timer = 0.0
		$Sprite2D.frame = ($Sprite2D.frame + 1) % 10
