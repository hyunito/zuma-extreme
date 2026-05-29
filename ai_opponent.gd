extends Node2D

# --- Node References ---
var bullet_scene = preload("res://shot_ball.tscn")
@onready var mouth_position = $Marker2D
@onready var loaded_ball_sprite = $LoadedBall

# --- Track Mappings ---
@export var ai_track: Node2D      # The AI's own track (for healing/clearing)
@export var player_track: Node2D  # The Player's track (for attacking/sabotage)

# --- Texture Mappings ---
const BALL_TEXTURES = {
	"red": preload("res://assets/balls/Red_ball.png"),
	"blue": preload("res://assets/balls/Blue_ball.png"),
	"yellow": preload("res://assets/balls/Yellow_ball.png"),
	"green": preload("res://assets/balls/Green_ball.png"),
	"gray": preload("res://assets/balls/Gray_ball.png")
}

var current_color: String = "red"

# --- Q-Learning Hyperparameters ---
var learning_rate: float = 0.2
var discount_factor: float = 0.9
var exploration_rate: float = 0.15 # 15% exploration
var q_table: Dictionary = {}

# --- Game Context Variables ---
var current_hp: float = 50.0
var max_hp: float = 50.0
var time_remaining: float = 120.0
var total_match_time: float = 120.0

# --- Decision Timer ---
var decision_timer: float = 0.0
var decision_cooldown: float = 1.5 # Thinks every 1.5 seconds

# Remember last state/action for learning
var last_state: int = 0
var last_action: int = 0
# --- Motor & Targeting Control ---
var target_ball: PathFollow2D = null
var smooth_rotate_speed: float = 8.0 # How fast the AI rotates to face its target


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Initialize our 9 states x 4 actions Q-Table
	for state in range(9):
		q_table[state] = {
			Actions.HEAL: 0.0,
			Actions.ATTACK: 0.0,
			Actions.CLEAR: 0.0,
			Actions.WAIT: 0.0
		}
	
	# Automatically assign tracks if they aren't set in the inspector
	if not ai_track:
		ai_track = get_parent().get_node_or_null("Track2") # AI's track
	if not player_track:
		player_track = get_parent().get_node_or_null("Track") # Player's track
		
	# Load the first bullet color
	reload()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	# Run the AI decision and aiming loop in sync with physics frames
	think_and_act(delta)


# 1. Update the Actions enum to match our new strategic actions!
enum Actions { HEAL, ATTACK, CLEAR, WAIT }

# 2. Add the Fuzzy Logic State Fuzzifier function
func get_fuzzy_state() -> int:
	# --- FUZZIFY AI HEALTH ---
	var hp_ratio = current_hp / max_hp
	
	# Calculate membership values (0.0 to 1.0)
	var hp_low = clamp((0.4 - hp_ratio) / 0.4, 0.0, 1.0) if hp_ratio < 0.4 else 0.0
	var hp_high = clamp((hp_ratio - 0.6) / 0.4, 0.0, 1.0) if hp_ratio > 0.6 else 0.0
	var hp_medium = 1.0 - hp_low - hp_high
	
	# Winner-take-all classification for Health
	var health_state = "MEDIUM"
	if hp_low > hp_medium and hp_low > hp_high:
		health_state = "LOW"
	elif hp_high > hp_medium and hp_high > hp_low:
		health_state = "HIGH"

	# --- FUZZIFY TIME REMAINING ---
	var time_ratio = time_remaining / total_match_time
	
	# Calculate membership values (0.0 to 1.0)
	var time_urgent = clamp((0.3 - time_ratio) / 0.3, 0.0, 1.0) if time_ratio < 0.3 else 0.0
	var time_plenty = clamp((time_ratio - 0.7) / 0.3, 0.0, 1.0) if time_ratio > 0.7 else 0.0
	var time_ticking = 1.0 - time_urgent - time_plenty
	
	# Winner-take-all classification for Time
	var time_state = "TICKING"
	if time_urgent > time_ticking and time_urgent > time_plenty:
		time_state = "URGENT"
	elif time_plenty > time_ticking and time_plenty > time_urgent:
		time_state = "PLENTY"

	# --- MAP TO Q-TABLE STATE INDEX (0 to 8) ---
	# We map combinations to indices:
	# 0: LOW & PLENTY,   1: LOW & TICKING,   2: LOW & URGENT
	# 3: MEDIUM & PLENTY,4: MEDIUM & TICKING,5: MEDIUM & URGENT
	# 6: HIGH & PLENTY,  7: HIGH & TICKING,  8: HIGH & URGENT
	var health_idx = 0
	if health_state == "MEDIUM": health_idx = 1
	elif health_state == "HIGH": health_idx = 2
	
	var time_idx = 0
	if time_state == "TICKING": time_idx = 1
	elif time_state == "URGENT": time_idx = 2
	
	# Calculate the final state index (0 to 8)
	var state_index = (health_idx * 3) + time_idx
	return state_index

# Selects an action using the Epsilon-Greedy Strategy
func choose_action(state: int) -> int:
	# 1. EXPLORE: Try a random action (Epsilon chance)
	if randf() < exploration_rate:
		return Actions.values().pick_random()
		
	# 2. EXPLOIT: Find the best action with the highest Q-value in this state
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
	# 1. HEAL / CLEAR: Look at our own track
	if action == Actions.HEAL or action == Actions.CLEAR:
		if not ai_track or ai_track.balls.is_empty():
			return null
		
		var target_colors = ["green", "yellow"] if action == Actions.HEAL else [current_color]
		var candidates = []
		for ball in ai_track.balls:
			if ball.ball_color in target_colors:
				candidates.append(ball)
		
		if not candidates.is_empty():
			return candidates.pick_random()
		return ai_track.balls.pick_random() # Fallback to any ball on own track

	# 2. ATTACK: Try to target the player's track to disrupt them!
	elif action == Actions.ATTACK:
		if not player_track or player_track.balls.is_empty():
			# Fallback to clear our own track if player track is empty
			if ai_track and not ai_track.balls.is_empty():
				return ai_track.balls.pick_random()
			return null
			
		var candidates = []
		for ball in player_track.balls:
			# Only target player balls that we have a clear line of sight to!
			if has_line_of_sight(ball.global_position):
				# A high-IQ attack targets colors that match what the player is trying to clear,
				# or we just target the front of their train to slow them down!
				candidates.append(ball)
				
		if not candidates.is_empty():
			return candidates.pick_random()
			
		# Fallback: If player track is blocked, focus on defending/clearing our own track!
		if ai_track and not ai_track.balls.is_empty():
			return ai_track.balls.pick_random()
			
	return null


# Returns true if there is a clear shot to the target (no AI balls blocking the path)
func has_line_of_sight(target_pos: Vector2) -> bool:
	if not ai_track or ai_track.balls.is_empty():
		return true # No balls to block us!
		
	var start_pos = global_position
	
	# Loop through all balls on the AI's own track to see if they block the ray
	for ball in ai_track.balls:
		var ball_pos = ball.global_position
		
		# Find the closest point on our shooting line segment to the ball
		var line_vec = target_pos - start_pos
		var line_len = line_vec.length()
		if line_len == 0: continue
		
		var line_dir = line_vec.normalized()
		
		# Project ball position onto the line segment
		var projection = (ball_pos - start_pos).dot(line_dir)
		
		# If the projection lies within the segment length, check the distance
		if projection > 0.0 and projection < line_len:
			var closest_point = start_pos + line_dir * projection
			var distance = ball_pos.distance_to(closest_point)
			
			# If the distance is less than a ball's collision radius, it blocks the shot!
			if distance < 32.0: # Ball radius is ~32.5 pixels
				return false # Blocked!
				
	return true # Clear shot!
func reload() -> void:
	current_color = BALL_TEXTURES.keys().pick_random()
	if loaded_ball_sprite:
		loaded_ball_sprite.texture = BALL_TEXTURES[current_color]

func shoot() -> void:
	if not bullet_scene: return
	var new_bullet = bullet_scene.instantiate()
	
	new_bullet.ball_color = current_color
	new_bullet.get_node("Sprite2D").texture = BALL_TEXTURES[current_color]
	
	new_bullet.global_position = mouth_position.global_position
	new_bullet.rotation = rotation
	new_bullet.scale = global_scale
	
	get_parent().add_child(new_bullet)
	
	reload()
func learn(state: int, action: int, reward: float, next_state: int) -> void:
	var old_q = q_table[state][action]
	
	# Find the maximum possible future Q-value in the new state
	var max_future_q = -99999.0
	for a in q_table[next_state]:
		if q_table[next_state][a] > max_future_q:
			max_future_q = q_table[next_state][a]
			
	# Q-learning Bellman Update formula
	q_table[state][action] = old_q + learning_rate * (reward + discount_factor * max_future_q - old_q)
func think_and_act(delta: float) -> void:
	# 1. Decision-making interval (every 1.5 seconds)
	decision_timer += delta
	if decision_timer >= decision_cooldown:
		decision_timer = 0.0
		
		# Define reward based on HP changes since last state (to be integrated fully with HP engine later)
		var reward = 0.0
		var next_state = get_fuzzy_state()
		
		# Simple heuristic rewards to teach the AI:
		# Positive feedback for defending when health is low
		if last_action == Actions.HEAL and current_hp < 20.0:
			reward = 10.0
		# Positive feedback for attacking/putting pressure
		elif last_action == Actions.ATTACK:
			reward = 5.0 
			
		# Update Q-table with the results of our last action!
		learn(last_state, last_action, reward, next_state)
		
		# Select new strategic action using Fuzzy State
		var state = next_state
		var action = choose_action(state)
		
		# Find suitable target ball on the appropriate track
		target_ball = find_target_ball(action)
		
		# Remember for next learning phase
		last_state = state
		last_action = action
		
	# 2. Motor system: Smoothly aim towards target and shoot
	if is_instance_valid(target_ball):
		var target_pos = target_ball.global_position
		var target_angle = (target_pos - global_position).angle()
		
		# Interpolate rotation smoothly to face target
		rotation = rotate_toward(rotation, target_angle, smooth_rotate_speed * delta)
		
		# 3. Fire when aimed and the path is clear!
		var angle_diff = abs(angle_difference(rotation, target_angle))
		if angle_diff < 0.08 and has_line_of_sight(target_pos):
			shoot()
			target_ball = null # Reset target after firing
	else:
		target_ball = null
