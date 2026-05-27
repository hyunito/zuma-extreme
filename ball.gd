extends PathFollow2D

@export var speed: float = 150.0

const BALL_TEXTURES = {
	"red": preload("res://assets/balls/Red_ball.png"),
	"blue": preload("res://assets/balls/Blue_ball.png"),
	"yellow": preload("res://assets/balls/Yellow_ball.png")
}

var ball_color: String = "red"

@onready var sprite: Sprite2D = $Sprite2D

func _physics_process(delta: float) -> void:
	progress += speed * delta
	
	if sprite:
	# Define how many pixels the ball needs to move to advance 1 frame of rotation
		var distance_per_frame: float = 15.0 
	
		sprite.frame = int(progress / distance_per_frame) % 10
	if progress_ratio >= 1.0:
		reach_end()

func set_color(new_color: String) -> void:
	ball_color = new_color
	
	if not is_node_ready():
		await ready
		
	if sprite and BALL_TEXTURES.has(new_color):
		sprite.texture = BALL_TEXTURES[new_color]

func reach_end() -> void:
	queue_free()
