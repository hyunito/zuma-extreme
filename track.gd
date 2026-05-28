extends Path2D

const BALL_SCENE = preload("res://ball.tscn")
const COLORS = ["red", "blue", "yellow"]

var ball_diameter: float = 65.0 
var track_speed: float = 150.0
@export var flip_balls: bool = true

var balls: Array[PathFollow2D] = []

@onready var line_2d: Line2D = $Line2D

func _ready() -> void:
	if line_2d and curve:
		line_2d.points = curve.get_baked_points()

func _process(delta: float) -> void:
	if balls.is_empty():
		spawn_ball()
		return
		
	balls[0].progress += track_speed * delta
	
	for i in range(1, balls.size()):
		var front_ball = balls[i-1]
		var my_ball = balls[i]

		var perfect_spot = front_ball.progress - ball_diameter
		
		if my_ball.progress > perfect_spot:

			my_ball.progress -= 800.0 * delta
			if my_ball.progress < perfect_spot:
				my_ball.progress = perfect_spot
		elif my_ball.progress < perfect_spot:
			
			my_ball.progress += 800.0 * delta
			if my_ball.progress > perfect_spot:
				my_ball.progress = perfect_spot
				
	if balls[-1].progress >= ball_diameter:
		spawn_ball()
		
	if balls[0].progress_ratio >= 1.0:
		var dead_ball = balls.pop_front()
		dead_ball.queue_free()

func spawn_ball() -> void:
	var new_ball = BALL_SCENE.instantiate()
	add_child(new_ball)
	new_ball.set_color(COLORS.pick_random())
	new_ball.should_flip = flip_balls
	new_ball.progress = 0.0
	
	# Add it to the end of our master array
	balls.append(new_ball)

func insert_ball(hit_ball: PathFollow2D, hit_offset: float, texture: Texture2D) -> void:
	var new_ball = BALL_SCENE.instantiate()
	add_child(new_ball)
	new_ball.set_texture(texture)
	new_ball.should_flip = flip_balls
	
	var hit_index = balls.find(hit_ball)
	
	new_ball.progress = hit_ball.progress
	
	if hit_offset > hit_ball.progress:
		balls.insert(hit_index, new_ball) 
	else:
		balls.insert(hit_index + 1, new_ball) 
