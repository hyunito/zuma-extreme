extends Path2D

const BALL_SCENE = preload("res://ball.tscn")
const COLORS = ["red", "blue", "yellow", "gray", "green"]
var pause_timer: float = 0.0

var balls_to_destroy: Array[PathFollow2D] = []

var was_gap_active: bool = false
var collision_recoil: float = 0.0
var ball_diameter: float = 65.0 
var track_speed: float = 150.0
@export var flip_balls: bool = true
var combo_count: int = 0
var balls: Array[PathFollow2D] = []
var last_gap_index: int = -1


func _ready() -> void:
	pass

func spawn_ball() -> void:
	var new_ball = BALL_SCENE.instantiate()
	
	add_child(new_ball)
	
	new_ball.set_color(COLORS.pick_random())

	new_ball.should_flip = flip_balls

	new_ball.progress = 0.0

	balls.append(new_ball)


func _physics_process(delta: float) -> void:

	if pause_timer > 0.0:
		pause_timer -= delta
		
		if pause_timer <= 0.0:
			execute_match_deletion()
		return 

	if balls.is_empty():
		spawn_ball()
		return
		
	if collision_recoil > 0.0:

		collision_recoil = move_toward(collision_recoil, 0.0, 1500.0 * delta)
		
	var gap_index = find_first_gap()
	var current_has_gap = (gap_index != -1)
	
	if was_gap_active and not current_has_gap:
		var combo_triggered = false
		if last_gap_index >= 0 and last_gap_index < balls.size():
			combo_triggered = check_matches(last_gap_index)
			
		if combo_triggered:
			combo_count += 1

			var base_combo_recoil = 1000.0
			var extra_per_combo = 700.0
			collision_recoil = base_combo_recoil + (extra_per_combo * combo_count)
		else:
			combo_count = 0
			collision_recoil = 700.0 


	if current_has_gap:
		last_gap_index = gap_index
		var rewind_speed = 800.0
		balls[0].progress = max(0.0, balls[0].progress - rewind_speed * delta)

		for i in range(1, gap_index):
			balls[i].progress = balls[i-1].progress - ball_diameter

		for i in range(gap_index, balls.size()):
			balls[i].progress += track_speed * delta
			
		for i in range(gap_index + 1, balls.size()):
			var perfect_spot = balls[i-1].progress - ball_diameter
			if balls[i].progress > perfect_spot:
				balls[i].progress = perfect_spot
	else:

		var active_speed = track_speed - collision_recoil

		balls[0].progress = max(0.0, balls[0].progress + active_speed * delta)
		
		for i in range(1, balls.size()):
			balls[i].progress = balls[i-1].progress - ball_diameter

	was_gap_active = current_has_gap

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

	var new_index = balls.find(new_ball)
	var matched = check_matches(new_index)
	
	if matched:
		combo_count = 1
	else:
		combo_count = 0

func check_matches(inserted_index: int) -> bool:
	var target_color = balls[inserted_index].ball_color
	var matching_indices = [inserted_index] 
	
	var i = inserted_index - 1
	while i >= 0:
		if balls[i].ball_color == target_color:
			matching_indices.append(i)
			i -= 1
		else:
			break 
		
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
			
		
		pause_timer = 0.25
		return true 
		
	return false

func execute_match_deletion() -> void:
	for ball in balls_to_destroy:
		if ball in balls:
			var index = balls.find(ball)
			balls.remove_at(index) 
			ball.queue_free() 
	balls_to_destroy.clear() 

func find_first_gap() -> int:
	for i in range(1, balls.size()):
		
		if balls[i-1].progress - balls[i].progress > ball_diameter + 5.0:
			return i 
	return -1 
