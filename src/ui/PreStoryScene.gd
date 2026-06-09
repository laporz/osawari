extends Control

## ストーリーデータ：各行は {text, face} の辞書
## face は FACE_TEXTURES のキーと対応
const PRE_STORY_DATA: Dictionary = {
	&"chara_01": [
		{text = "彼女の名前は、まだ知らない。",                   face = &"normal"},
		{text = "ある日、あなたは不思議な出会いを果たした。",       face = &"normal"},
		{text = "「…何か、用ですか？」",                         face = &"shy"},
		{text = "少し警戒しながらも、彼女はその場に留まっている。", face = &"surprise"},
		{text = "まずは距離を縮めることから始めよう。",             face = &"smile"},
	],
}

## ストーリー用テクスチャパス
const STORY_BODY_PATTERN: String = \
	"res://assets/images/characters/%s/story_body/%s"
const STORY_FACE_PATTERN: String = \
	"res://assets/images/characters/%s/story_face/%s.png"

## 日数ごとの素体ファイル名
const BODY_BY_DAY: Array[String] = ["body.png", "halfundress.png", "undress.png"]

@onready var chara_sprite: Sprite2D = $CharaSprite
@onready var face_sprite: Sprite2D  = $FaceSprite
@onready var message_label: Label   = $VBoxContainer/MessageWindow/MessageLabel
@onready var btn_next: Button       = $VBoxContainer/BtnNext

var _lines: Array[Dictionary] = []
var _current_line: int = 0
var _char_id: StringName = &""


func _ready() -> void:
	btn_next.pressed.connect(_on_next_pressed)

	_char_id = GameManager.selected_character

	## 日数に応じた story_body をロード
	var day_idx: int = clampi(GameManager.current_day - 1, 0, BODY_BY_DAY.size() - 1)
	var body_path: String = STORY_BODY_PATTERN % \
		[str(_char_id), BODY_BY_DAY[day_idx]]
	var pre_img := Image.load_from_file(ProjectSettings.globalize_path(body_path))
	if pre_img:
		chara_sprite.texture = ImageTexture.create_from_image(pre_img)

	## ストーリーデータをセット
	var raw: Array = PRE_STORY_DATA.get(_char_id, [{text = "…", face = &"normal"}])
	_lines.assign(raw)

	_show_line(0)


func _show_line(index: int) -> void:
	if index >= _lines.size():
		_finish_story()
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


func _finish_story() -> void:
	get_tree().change_scene_to_file("res://scenes/main_game.tscn")
