extends CharacterBody2D

var speed: float = 2000.0
var animation_timer: float = 0.0
var frame_rate: float = 0.05 # lower = faster roll

func _physics_process(delta: float) -> void:
	var motion = transform.x * speed * delta
	var collision = move_and_collide(motion)
	
	if collision:
		var bounce_direction = motion.bounce(collision.get_normal())
		rotation = bounce_direction.angle()
		
	# Animate the rolling frame every frame
	animation_timer += delta
	if animation_timer >= frame_rate:
		animation_timer = 0.0
		$Sprite2D.frame = ($Sprite2D.frame + 1) % 10
