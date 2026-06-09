extends Node2D

@onready var btn_end: Button   = $UILayer/BtnEnd
@onready var day_label: Label  = $UILayer/DayLabel


func _ready() -> void:
	btn_end.pressed.connect(_on_end_pressed)
	day_label.text = "Day %d" % GameManager.current_day


func _on_end_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/PostStoryScene.tscn")
