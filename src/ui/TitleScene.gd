extends Control

@onready var btn_start: Button = $VBoxContainer/BtnStart
@onready var btn_load: Button = $VBoxContainer/BtnLoad
@onready var btn_settings: Button = $VBoxContainer/BtnSettings
@onready var btn_quit: Button = $VBoxContainer/BtnQuit
@onready var settings_panel: Control = $SettingsPanel


func _ready() -> void:
	btn_start.pressed.connect(_on_start_pressed)
	btn_load.pressed.connect(_on_load_pressed)
	btn_settings.pressed.connect(_on_settings_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)

	## セーブデータがない場合はロードボタンを無効化
	btn_load.disabled = not GameManager.has_save_data()

	settings_panel.hide()


func _on_start_pressed() -> void:
	GameManager.reset()
	get_tree().change_scene_to_file("res://scenes/main_game.tscn")


func _on_load_pressed() -> void:
	if GameManager.load_game():
		get_tree().change_scene_to_file("res://scenes/main_game.tscn")


func _on_settings_pressed() -> void:
	settings_panel.show()


func _on_quit_pressed() -> void:
	get_tree().quit()
