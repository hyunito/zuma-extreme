extends Node2D

var bullet_scene = preload("res://shot_ball.tscn")
@onready var mouth_position = $Marker2D
@onready var loaded_ball_sprite = $LoadedBall

# 1. Map color names (strings) to their textures
const BALL_TEXTURES = {
	"red": preload("res://assets/balls/Red_ball.png"),
	"blue": preload("res://assets/balls/Blue_ball.png"),
	"yellow": preload("res://assets/balls/Yellow_ball.png"),
	"gray": preload("res://assets/balls/Gray_ball.png"),
	"green": preload("res://assets/balls/Green_ball.png")
}

# 2. Store the current loaded color name
var current_color: String = "red"

func _ready() -> void:
	# Randomly load the first ball at startup
	reload()

func _process(_delta):
	look_at(get_global_mouse_position())

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		shoot()

func shoot():
	var new_bullet = bullet_scene.instantiate()
	new_bullet.shooter = "player"
	new_bullet.ball_color = current_color
	new_bullet.get_node("Sprite2D").texture = BALL_TEXTURES[current_color]
	
	new_bullet.global_position = mouth_position.global_position
	new_bullet.rotation = rotation
	new_bullet.scale = global_scale
	get_parent().add_child(new_bullet)
	
	reload()

func reload() -> void:
	current_color = BALL_TEXTURES.keys().pick_random()
	loaded_ball_sprite.texture = BALL_TEXTURES[current_color]
