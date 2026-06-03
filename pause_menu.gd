extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	get_tree().paused = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		_toggle_pause()

func _toggle_pause() -> void:
	visible = not visible
	get_tree().paused = visible

func show_pause_menu() -> void:
	visible = true
	get_tree().paused = true

func hide_pause_menu() -> void:
	visible = false
	get_tree().paused = false

func _on_resume_pressed() -> void:
	hide_pause_menu()

func _on_menu_pressed() -> void:
	hide_pause_menu()
	BgmMainMenu.play_music()
	get_tree().change_scene_to_file("res://main_menu.tscn")
