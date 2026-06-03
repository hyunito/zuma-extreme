extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://levels/main/main.tscn")

func _on_options_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/options_menu/options_menu.tscn")

func _on_tutorial_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/tutorial_menu/tutorial_menu.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
