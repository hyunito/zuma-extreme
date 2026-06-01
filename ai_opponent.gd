extends Node2D

var bullet_scene = preload("res://shot_ball.tscn")
@onready var mouth_position = $Marker2D
@onready var loaded_ball_sprite = $LoadedBall

@export var ai_track: Node2D     
@export var player_track: Node2D 

const BALL_TEXTURES = {
	"red": preload("res://assets/balls/Red_ball.png"),
	"blue": preload("res://assets/balls/Blue_ball.png"),
	"yellow": preload("res://assets/balls/Yellow_ball.png"),
	"green": preload("res://assets/balls/Green_ball.png"),
	"gray": preload("res://assets/balls/Gray_ball.png")
}

var current_color: String = "red"

var learning_rate: float = 0.2
var discount_factor: float = 0.9
var exploration_rate: float = 0.15
var q_table: Dictionary = {}
var wants_to_throw_away: bool = false
var current_hp: float = 50.0
var max_hp: float = 50.0
var time_remaining: float = 180.0
var total_match_time: float = 180.0

var decision_timer: float = 0.0
var decision_cooldown: float = .5
var last_had_target: bool = false
var last_state: int = 0
var last_action: int = 0

var target_ball: PathFollow2D = null
var smooth_rotate_speed: float = 8.0 

func _ready() -> void:
	
	for state in range(9):
		q_table[state] = {
			Actions.HEAL: 0.0,
			Actions.ATTACK: 0.0,
			Actions.CLEAR: 0.0,
			Actions.WAIT: 0.0
		}
	
	
	if not ai_track:
		ai_track = get_parent().get_node_or_null("Track2")  
	if not player_track:
		player_track = get_parent().get_node_or_null("Track")
		
	reload()
	load_brain()

func _exit_tree() -> void:
	save_brain()

func _physics_process(delta: float) -> void:
	think_and_act(delta)

enum Actions { HEAL, ATTACK, CLEAR, WAIT }

func get_fuzzy_state() -> int:

	var hp_ratio = current_hp / max_hp
	
	var hp_low = clamp((0.4 - hp_ratio) / 0.4, 0.0, 1.0) if hp_ratio < 0.4 else 0.0
	var hp_high = clamp((hp_ratio - 0.6) / 0.4, 0.0, 1.0) if hp_ratio > 0.6 else 0.0
	var hp_medium = 1.0 - hp_low - hp_high
	
	var health_state = "MEDIUM"
	if hp_low > hp_medium and hp_low > hp_high:
		health_state = "LOW"
	elif hp_high > hp_medium and hp_high > hp_low:
		health_state = "HIGH"

	var time_ratio = time_remaining / total_match_time
	
	var time_urgent = clamp((0.3 - time_ratio) / 0.3, 0.0, 1.0) if time_ratio < 0.3 else 0.0
	var time_plenty = clamp((time_ratio - 0.7) / 0.3, 0.0, 1.0) if time_ratio > 0.7 else 0.0
	var time_ticking = 1.0 - time_urgent - time_plenty
	
	var time_state = "TICKING"
	if time_urgent > time_ticking and time_urgent > time_plenty:
		time_state = "URGENT"
	elif time_plenty > time_ticking and time_plenty > time_urgent:
		time_state = "PLENTY"

	var health_idx = 0
	if health_state == "MEDIUM": health_idx = 1
	elif health_state == "HIGH": health_idx = 2
	
	var time_idx = 0
	if time_state == "TICKING": time_idx = 1
	elif time_state == "URGENT": time_idx = 2
	
	var state_index = (health_idx * 3) + time_idx
	return state_index

func choose_action(state: int) -> int:
	
	if randf() < exploration_rate:
		return Actions.values().pick_random()
		
	var state_actions = q_table[state]
	var best_action = Actions.HEAL
	var max_q_value = -99999.0
	
	for action in state_actions:
		var q_val = state_actions[action]
		if q_val > max_q_value:
			max_q_value = q_val
			best_action = action
			
	return best_action

func find_target_ball(action: int) -> PathFollow2D:
	if action == Actions.WAIT:
		return null
		
	if action == Actions.HEAL:
		if not ai_track or ai_track.balls.is_empty():
			return null
		if current_color in ["green", "yellow"]:
			var same_color_candidates = []
			for ball in ai_track.balls:
				if ball.ball_color == current_color:
					same_color_candidates.append(ball)
			
			if not same_color_candidates.is_empty():
				return same_color_candidates.pick_random()
				
		action = Actions.CLEAR 

	if action == Actions.CLEAR:
		if not ai_track or ai_track.balls.is_empty():
			return null
			
		var same_color_candidates = []
		for ball in ai_track.balls:
			if ball.ball_color == current_color:
				same_color_candidates.append(ball)
				
		if not same_color_candidates.is_empty():
			return same_color_candidates.pick_random()
			
		return null

	if action == Actions.ATTACK:
			
		var same_color_candidates = []
		for ball in player_track.balls:
			if ball.ball_color == current_color and has_line_of_sight(ball.global_position):
				same_color_candidates.append(ball)
				
		if not same_color_candidates.is_empty():
			return same_color_candidates.pick_random()
			
		var any_sight_candidates = []
		for ball in player_track.balls:
			if has_line_of_sight(ball.global_position):
				any_sight_candidates.append(ball)
				
		if not any_sight_candidates.is_empty():
			return any_sight_candidates.pick_random()

	return null

func has_line_of_sight(target_pos: Vector2) -> bool:
	if not ai_track or ai_track.balls.is_empty():
		return true 
		
	var start_pos = global_position
	
	for ball in ai_track.balls:
		var ball_pos = ball.global_position
		
		var line_vec = target_pos - start_pos
		var line_len = line_vec.length()
		if line_len == 0: continue
		
		var line_dir = line_vec.normalized()
		
		var projection = (ball_pos - start_pos).dot(line_dir)
		
		if projection > 0.0 and projection < line_len:
			var closest_point = start_pos + line_dir * projection
			var distance = ball_pos.distance_to(closest_point)
			
			if distance < 32.0:
				return false 
				
	return true 
func reload() -> void:
	current_color = BALL_TEXTURES.keys().pick_random()
	if loaded_ball_sprite:
		loaded_ball_sprite.texture = BALL_TEXTURES[current_color]

func shoot() -> void:
	if not bullet_scene: return
	var new_bullet = bullet_scene.instantiate()
	new_bullet.shooter = "ai"
	new_bullet.ball_color = current_color
	new_bullet.get_node("Sprite2D").texture = BALL_TEXTURES[current_color]
	
	new_bullet.global_position = mouth_position.global_position
	new_bullet.rotation = rotation
	new_bullet.scale = global_scale
	
	get_parent().add_child(new_bullet)
	
	reload()

func learn(state: int, action: int, reward: float, current_state: int) -> void:
	var old_q = q_table[state][action]
	
	var max_future_q = -99999.0
	for a in q_table[current_state]:
		if q_table[current_state][a] > max_future_q:
			max_future_q = q_table[current_state][a]
			
	q_table[state][action] = old_q + learning_rate * (reward + discount_factor * max_future_q - old_q)

func think_and_act(delta: float) -> void:
	decision_timer += delta
	var current_state = get_fuzzy_state()
	match current_state:
			0: 
				decision_cooldown = .3
			1: 
				decision_cooldown = .3
			2: 
				decision_cooldown = .25
			3: 
				decision_cooldown = .5
			4: 
				decision_cooldown = .5
			5: 
				decision_cooldown = .3
			6: 
				decision_cooldown = .7
			7: 
				decision_cooldown = .5
			8: 
				decision_cooldown = .25
	if decision_timer >= decision_cooldown:
		decision_timer = 0.0
		var action = choose_action(current_state)
		target_ball = find_target_ball(action)
		var reward = 0.0
		
		if wants_to_throw_away:
			reward = -8.0 
		elif last_action == Actions.WAIT:
			reward = -0.5
		elif last_action == Actions.HEAL and current_hp < 45.0:
			if last_had_target:
				reward = 4.0 
			else:
				reward = -2.0 
		elif last_action == Actions.CLEAR:
			if last_had_target:
				reward = 10.0 
			else:
				reward = -2.0 
		elif last_action == Actions.ATTACK:
			if last_had_target:
				reward = 6.0 
			else:
				reward = -2.0 

		learn(last_state, last_action, reward, current_state)
		last_had_target = (target_ball != null)

		if target_ball == null and action != Actions.WAIT:
			wants_to_throw_away = true
		else:
			wants_to_throw_away = false
			
		last_state = current_state
		last_action = action

	if is_instance_valid(target_ball):
		wants_to_throw_away = false
		var target_pos = target_ball.global_position
		var target_angle = (target_pos - global_position).angle()
		
		rotation = rotate_toward(rotation, target_angle, smooth_rotate_speed * delta)
		
		var angle_diff = abs(angle_difference(rotation, target_angle))
		if angle_diff < 0.04 and has_line_of_sight(target_pos):
			shoot()
			target_ball = null 
			
	elif wants_to_throw_away:
		var throw_angle = 3 #-1.57079
		rotation = rotate_toward(rotation, throw_angle, smooth_rotate_speed * delta)
		
		var angle_diff = abs(angle_difference(rotation, throw_angle))
		if angle_diff < 0.05:
			shoot()
			wants_to_throw_away = false
	else:
		target_ball = null

func save_brain() -> void:
	var file = FileAccess.open("user://ai_brain.json", FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(q_table)
		file.store_string(json_string)
		file.close()
		print("Successfully saved scorecard to disk at user://ai_brain.json.")
	else:
		print("Could not open file to save scorecard.")

func load_brain() -> void:
	var file_path = "user://ai_brain.json"
	
	if not FileAccess.file_exists(file_path):
		if FileAccess.file_exists("res://ai_brain.json"):
			file_path = "res://ai_brain.json"
			print("No local save found. Loading pre-trained shipped brain from res://")
		else:
			print("No local save found. Starting with a fresh blank scorecard")
			return
			
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		
		var parsed_data = JSON.parse_string(content)
		if parsed_data is Dictionary:
			for str_state in parsed_data.keys():
				var state_int = int(str_state)
				var actions_dict = parsed_data[str_state]
				for str_action in actions_dict.keys():
					var action_int = int(str_action)
					q_table[state_int][action_int] = float(actions_dict[str_action])
			print("Successfully loaded brain scorecard")
