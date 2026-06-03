extends AnimatedSprite2D

func _ready() -> void:
	play("explosion")
	animation_finished.connect(queue_free)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
