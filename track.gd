extends Path2D

const BALL_SCENE = preload("res://ball.tscn")
const COLORS = ["red", "blue", "yellow"]

var ball_diameter: float = 58.0 

var last_spawned_ball: PathFollow2D = null
@export var flip_balls: bool = true
@onready var line_2d: Line2D = $Line2D

func _ready() -> void:
	if line_2d and curve:
		line_2d.points = curve.get_baked_points()

func _process(delta: float) -> void:
	if last_spawned_ball == null or last_spawned_ball.progress >= ball_diameter:
		spawn_ball()

func spawn_ball() -> void:
	var new_ball = BALL_SCENE.instantiate()
	add_child(new_ball)
	
	var random_color = COLORS.pick_random()
	
	new_ball.set_color(random_color)
	new_ball.should_flip = flip_balls

	last_spawned_ball = new_ball
