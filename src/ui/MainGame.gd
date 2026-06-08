extends Node2D

@onready var btn_end: Button = $UILayer/BtnEnd


func _ready() -> void:
	btn_end.pressed.connect(_on_end_pressed)


func _on_end_pressed() -> void:
	GameManager.save_game()
	get_tree().change_scene_to_file("res://scenes/EndingScene.tscn")
