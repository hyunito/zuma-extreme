extends Path2D

const BALL_SCENE = preload("res://ball.tscn")

@onready var line_2d: Line2D = $Line2D

var spawn_timer: float = 0.0
var spawn_interval: float = 1.0

const COLORS = ["red", "blue", "yellow"]

func _ready() -> void:
	if line_2d and curve:
		line_2d.points = curve.get_baked_points()
		
func _process(delta: float) -> void:
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		spawn_ball()
		
func spawn_ball() -> void:
	var new_ball = BALL_SCENE.instantiate()
	
	add_child(new_ball)
#	new_ball.progress = 0.0
	
	var random_color = COLORS[randi() % COLORS.size()]
	new_ball.set_color(random_color)
	
