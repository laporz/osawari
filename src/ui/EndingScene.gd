extends Control

## エンディングごとのデータ
const ENDING_DATA: Dictionary = {
	GameManager.EndingType.GOOD: {
		"title": "Good End",
		"lines": [
			"あなたのやさしい触れ方に、彼女はすっかり心を開いてくれた。",
			"「…またね」と笑顔でつぶやく彼女の言葉が、いつまでも耳に残る。",
			"――ふたりの時間は、まだ続く。",
		],
	},
	GameManager.EndingType.NORMAL: {
		"title": "Normal End",
		"lines": [
			"彼女は少し照れながら、そっと距離を取った。",
			"「今日は、ここまでにしましょうか」",
			"――また会える日を、静かに待とう。",
		],
	},
	GameManager.EndingType.BAD: {
		"title": "Bad End",
		"lines": [
			"あなたの手は少し、乱暴すぎたかもしれない。",
			"「…もう、来ないでください」",
			"――彼女の背中が、遠ざかっていく。",
		],
	},
}

@onready var title_label: Label   = $VBoxContainer/TitleLabel
@onready var message_label: Label = $VBoxContainer/MessageLabel
@onready var btn_next: Button     = $VBoxContainer/BtnNext
@onready var btn_title: Button    = $VBoxContainer/BtnTitle

var _lines: Array[String] = []
var _current_line: int = 0


func _ready() -> void:
	btn_next.pressed.connect(_on_next_pressed)
	btn_title.pressed.connect(_on_title_pressed)
	btn_title.hide()

	var ending_type: GameManager.EndingType = GameManager.get_ending_type()
	var data: Dictionary = ENDING_DATA[ending_type]

	title_label.text = data["title"]
	_lines.assign(data["lines"])
	_show_line(0)


func _show_line(index: int) -> void:
	if index >= _lines.size():
		_on_story_finished()
		return
	message_label.text = _lines[index]
	_current_line = index


func _on_next_pressed() -> void:
	_show_line(_current_line + 1)


func _on_story_finished() -> void:
	btn_next.hide()
	message_label.text = ""
	btn_title.show()


func _on_title_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/TitleScene.tscn")
