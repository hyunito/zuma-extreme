extends Node2D
class_name GameManager

@export var max_hp: float = 50.0
@export var match_time_limit: float = 180.0 
var player_hp_label: Label = null
var ai_hp_label: Label = null


var player_hp: float = 50.0
var ai_hp: float = 50.0

var time_remaining: float = 120.0
var is_game_over: bool = false

var player_track: Node2D = null
var ai_track: Node2D = null
var player_node: Node2D = null
var ai_node: Node2D = null

var player_hud_bar: TextureProgressBar = null
var ai_hud_bar: TextureProgressBar = null
var timer_label: Label = null

func _ready() -> void:
	
	process_mode = Node.PROCESS_MODE_ALWAYS
	player_hp = max_hp
	ai_hp = max_hp
	time_remaining = match_time_limit
	player_hp_label = get_node_or_null("HUD/PlayerHPLabel")
	ai_hp_label = get_node_or_null("HUD/AIHPLabel")

	player_track = get_node_or_null("Track")
	ai_track = get_node_or_null("Track2")
	player_node = get_node_or_null("Player")
	ai_node = get_node_or_null("AIOpponent")

	player_hud_bar = get_node_or_null("HUD/PlayerHealthBar")
	ai_hud_bar = get_node_or_null("HUD/AIHealthBar")
	timer_label = get_node_or_null("HUD/TimerLabel")
	
	_update_hud_bars()

	if player_track:
		player_track.match_cleared.connect(_on_match_cleared)
		
	if ai_track:
		ai_track.match_cleared.connect(_on_match_cleared)
		


func _process(delta: float) -> void:
	if is_game_over:
		#if Input.is_key_pressed(KEY_SPACE) or Input.is_action_just_pressed("ui_accept"):
		#	if get_tree():
		get_tree().paused = false 
		get_tree().reload_current_scene()
		return
	
	time_remaining -= delta
	_update_timer_label()
	
	if time_remaining <= 0.0:
		time_remaining = 0.0
		if ai_hp > player_hp:
			trigger_game_over("AI WINS!")
		elif player_hp > ai_hp:
			trigger_game_over("PLAYER WINS!")
		else:
			trigger_game_over("DRAW!")


func _on_match_cleared(color: String, size: int, shooter: String) -> void:
	var multiplier = float(size)
	
	if shooter == "player":
		match color:
			"green":
				heal_player(2.0 * multiplier) 
			"yellow":
				heal_player(1.0 * multiplier) 
			"red":
				damage_ai(4.0 * multiplier)  
			"gray":
				damage_ai(2.0 * multiplier)  
			"blue":
				pass 
				
	elif shooter == "ai":
		match color:
			"green":
				heal_ai(2.0 * multiplier)     
			"yellow":
				heal_ai(1.0 * multiplier)    
			"red":
				damage_player(4.0 * multiplier)
			"gray":
				damage_player(2.0 * multiplier) 
			"blue":
				pass 


func heal_player(amount: float) -> void:
	var old_hp = player_hp
	player_hp = min(max_hp, player_hp + amount)
	_update_hud_bars()

func damage_player(amount: float) -> void:
	var old_hp = player_hp
	player_hp = max(0.0, player_hp - amount)
	_update_hud_bars()
	if player_hp <= 0.0:
		trigger_game_over("AI OPPONENT WINS!")

func heal_ai(amount: float) -> void:
	var old_hp = ai_hp
	ai_hp = min(max_hp, ai_hp + amount)
	_update_hud_bars()

func damage_ai(amount: float) -> void:
	var old_hp = ai_hp
	ai_hp = max(0.0, ai_hp - amount)
	_update_hud_bars()
	if ai_hp <= 0.0:
		trigger_game_over("PLAYER WINS!")


func _update_hud_bars() -> void:
	if player_hud_bar:
		player_hud_bar.max_value = max_hp
		player_hud_bar.value = player_hp
	if ai_hud_bar:
		ai_hud_bar.max_value = max_hp
		ai_hud_bar.value = ai_hp
		
	if player_hp_label:
		player_hp_label.text = "HP: %d/%d" % [int(player_hp), int(max_hp)]
	if ai_hp_label:
		ai_hp_label.text = "HP: %d/%d" % [int(ai_hp), int(max_hp)]
		
	if ai_node and "current_hp" in ai_node:
		ai_node.current_hp = ai_hp
	if ai_node and "time_remaining" in ai_node:
		ai_node.time_remaining = time_remaining


func _update_timer_label() -> void:
	if timer_label:
		var minutes = int(time_remaining) / 60
		var seconds = int(time_remaining) % 60
		timer_label.text = "%02d:%02d" % [minutes, seconds]

func trigger_game_over(winner_text: String) -> void:
	is_game_over = true
	if get_tree():
		get_tree().paused = true

	var overlay = CanvasLayer.new()
	overlay.layer = 100

	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.75) 
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT) 
	overlay.add_child(bg)

	var container = VBoxContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	container.grow_vertical = Control.GROW_DIRECTION_BOTH

	container.add_theme_constant_override("separation", 24) 
	
	var msg_label = Label.new()
	msg_label.text = winner_text.to_upper()
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	msg_label.add_theme_font_size_override("font_size", 48)
	
	if "WIN" in winner_text.to_upper() or "PLAYER WINS" in winner_text.to_upper():
		msg_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2))
	else:
		msg_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	
	
	var sub_label = Label.new()
	sub_label.text = "Press SPACE to Restart" 
	sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	sub_label.add_theme_font_size_override("font_size", 20)
	sub_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8)) 
	
	container.add_child(msg_label)
	container.add_child(sub_label)
	overlay.add_child(container)
	add_child(overlay)
