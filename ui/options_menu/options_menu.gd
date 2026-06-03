extends Control

func _ready() -> void:
	$HSlider.value = GameSettings.bgm_volume
	$HSlider2.value = GameSettings.sfx_volume

func _on_bgm_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(1, linear_to_db(value))
	AudioServer.set_bus_mute(1, value < 0.01)
	GameSettings.bgm_volume = value

func _on_sfx_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(2, linear_to_db(value))
	AudioServer.set_bus_mute(2, value < 0.01)
	GameSettings.sfx_volume = value

func _on_home_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/main_menu/main_menu.tscn")

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://levels/main/main.tscn")
