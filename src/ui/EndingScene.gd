extends Control

## エンディングごとのデータ（各行に face キーを追加）
const ENDING_DATA: Dictionary = {
	GameManager.EndingType.GOOD: {
		"title": "Good End",
		"lines": [
			{text = "あなたのやさしい触れ方に、彼女はすっかり心を開いてくれた。", face = &"smile"},
			{text = "「…またね」と笑顔でつぶやく彼女の言葉が、いつまでも耳に残る。", face = &"smile"},
			{text = "――ふたりの時間は、まだ続く。",                               face = &"smile"},
		],
	},
	GameManager.EndingType.NORMAL: {
		"title": "Normal End",
		"lines": [
			{text = "彼女は少し照れながら、そっと距離を取った。",   face = &"shy"},
			{text = "「今日は、ここまでにしましょうか」",            face = &"blush"},
			{text = "――また会える日を、静かに待とう。",             face = &"normal"},
		],
	},
	GameManager.EndingType.BAD: {
		"title": "Bad End",
		"lines": [
			{text = "あなたの手は少し、乱暴すぎたかもしれない。", face = &"surprise"},
			{text = "「…もう、来ないでください」",                face = &"tears"},
			{text = "――彼女の背中が、遠ざかっていく。",           face = &"tears"},
		],
	},
}

const STORY_BODY_PATTERN: String = \
	"res://assets/images/characters/%s/story_body/%s"
const STORY_FACE_PATTERN: String = \
	"res://assets/images/characters/%s/story_face/%s.png"
const BODY_BY_DAY: Array[String] = ["body.png", "halfundress.png", "undress.png"]

@onready var chara_sprite: Sprite2D  = $CharaSprite
@onready var face_sprite: Sprite2D   = $FaceSprite
@onready var title_label: Label      = $VBoxContainer/TitleLabel
@onready var message_label: Label    = $VBoxContainer/MessageWindow/MessageLabel
@onready var btn_next: Button        = $VBoxContainer/BtnNext
@onready var btn_title: Button       = $VBoxContainer/BtnTitle

var _lines: Array[Dictionary] = []
var _current_line: int = 0
var _char_id: StringName = &""


func _ready() -> void:
	btn_next.pressed.connect(_on_next_pressed)
	btn_title.pressed.connect(_on_title_pressed)
	btn_title.hide()

	_char_id = GameManager.selected_character

	## 日数に応じた story_body をロード（EndingScene は必ず day 3）
	var day_idx: int = clampi(GameManager.current_day - 1, 0, BODY_BY_DAY.size() - 1)
	var body_path: String = STORY_BODY_PATTERN % [str(_char_id), BODY_BY_DAY[day_idx]]
	var end_img := Image.load_from_file(ProjectSettings.globalize_path(body_path))
	if end_img:
		chara_sprite.texture = ImageTexture.create_from_image(end_img)

	var ending_type: GameManager.EndingType = GameManager.get_ending_type()
	var data: Dictionary = ENDING_DATA[ending_type]
	title_label.text = data["title"]
	_lines.assign(data["lines"])
	_show_line(0)


func _show_line(index: int) -> void:
	if index >= _lines.size():
		_on_story_finished()
		return
	var entry: Dictionary = _lines[index]
	message_label.text = entry.get("text", "")
	_set_face(entry.get("face", &"normal"))
	_current_line = index


func _set_face(face_name: StringName) -> void:
	var path: String = STORY_FACE_PATTERN % [str(_char_id), str(face_name)]
	if ResourceLoader.exists(path):
		face_sprite.texture = load(path)
	else:
		face_sprite.texture = null


func _on_next_pressed() -> void:
	_show_line(_current_line + 1)


func _on_story_finished() -> void:
	btn_next.hide()
	message_label.text = ""
	btn_title.show()


func _on_title_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/TitleScene.tscn")
