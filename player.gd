extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# This gets the exact position of your mouse in the game world
	var mouse_pos = get_global_mouse_position()
	# Tell the player to rotate and face that exact position!
	look_at(mouse_pos)
	# This uses a sine wave to make the scale bounce smoothly between 0.95 and 1.05!
	#scale = Vector2(1.0, 1.0) + Vector2(0.05, 0.05) * sin(Time.get_ticks_msec() * 0.005)
