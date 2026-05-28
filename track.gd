extends Path2D

const BALL_SCENE = preload("res://ball.tscn")
const COLORS = ["red", "blue", "yellow"]

var pause_timer: float = 0.0
var balls_to_destroy: Array[PathFollow2D] = []

var ball_diameter: float = 65.0 
var track_speed: float = 150.0
@export var flip_balls: bool = true

var balls: Array[PathFollow2D] = []

@onready var line_2d: Line2D = $Line2D

func _ready() -> void:
	if line_2d and curve:
		line_2d.points = curve.get_baked_points()

func spawn_ball() -> void:
	
	var new_ball = BALL_SCENE.instantiate()
	add_child(new_ball)
	new_ball.set_color(COLORS.pick_random())
	new_ball.should_flip = flip_balls
	new_ball.progress = 0.0
	
	balls.append(new_ball)

func _process(delta: float) -> void:

	if pause_timer > 0.0:
		pause_timer -= delta
		if pause_timer <= 0.0:
			execute_match_deletion()
		return 

	if balls.is_empty():
		spawn_ball()
		return
		
	balls[0].progress += (track_speed-35) * delta
	
	# Keep everyone else rigidly in line
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

func insert_ball(hit_ball: PathFollow2D, hit_offset: float, color: String, texture: Texture2D) -> void:
	var new_ball = BALL_SCENE.instantiate()
	add_child(new_ball)
	new_ball.set_color(color) 
	new_ball.should_flip = flip_balls
	
	var hit_front = hit_offset > hit_ball.progress
	
	if hit_front:
		new_ball.progress = hit_ball.progress
		
		for child in get_children():
			if child is PathFollow2D and child != new_ball:
				if child.progress <= hit_ball.progress:
					child.progress -= ball_diameter
	else:
		new_ball.progress = hit_ball.progress - ball_diameter
		
		for child in get_children():
			if child is PathFollow2D and child != new_ball:
				if child.progress < hit_ball.progress:
					child.progress -= ball_diameter

	var hit_index = balls.find(hit_ball)
	if hit_front:
		balls.insert(hit_index, new_ball) 
	else:
		balls.insert(hit_index + 1, new_ball) 

	# Trigger the match check!
	var new_index = balls.find(new_ball)
	check_matches(new_index)

func check_matches(inserted_index: int) -> void:
	var target_color = balls[inserted_index].ball_color
	var matching_indices = [inserted_index]
	
	var i = inserted_index - 1
	while i >= 0:
		if balls[i].ball_color == target_color:
			matching_indices.append(i)
			i -= 1
		else:
			break
			
	# Scan forwards
	var j = inserted_index + 1
	while j < balls.size():
		if balls[j].ball_color == target_color:
			matching_indices.append(j)
			j += 1
		else:
			break
			
	if matching_indices.size() >= 3:
		matching_indices.sort_custom(func(a, b): return a > b)
		
		balls_to_destroy.clear()
		for index in matching_indices:
			var ball = balls[index]
			balls_to_destroy.append(ball)
			
			ball.modulate.a = 0.4
			ball.get_node("StaticBody2D/CollisionShape2D").disabled = true
			
		pause_timer = 0.8

func execute_match_deletion() -> void:
	for ball in balls_to_destroy:
		if ball in balls:
			var index = balls.find(ball)
			balls.remove_at(index)
			ball.queue_free()
	balls_to_destroy.clear()
