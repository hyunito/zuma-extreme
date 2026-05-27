extends Node2D

var bullet_scene = preload("res://shot_ball.tscn")
@onready var mouth_position = $Marker2D
@onready var loaded_ball_sprite = $LoadedBall

var possible_textures = [
	preload("res://assets/balls/Red_ball.png"),
	preload("res://assets/balls/Blue_ball.png"),
	preload("res://assets/balls/Yellow_ball.png")
]

func _process(delta):
	look_at(get_global_mouse_position())

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		shoot()

func shoot():
	# 1. Create the bullet
	var new_bullet = bullet_scene.instantiate()
	
	# 2. MATCH THE COLORS! We force the bullet to use the exact same image as our Dummy ball.
	# (We use get_node to find the Sprite2D inside the newly spawned bullet)
	new_bullet.get_node("Sprite2D").texture = loaded_ball_sprite.texture
	
	# 3. Position and fire!
	new_bullet.global_position = mouth_position.global_position
	new_bullet.rotation = rotation
	get_tree().current_scene.add_child(new_bullet)
	
	# 4. Reload the mouth with a brand new random color for the next shot!
	loaded_ball_sprite.texture = possible_textures.pick_random()
