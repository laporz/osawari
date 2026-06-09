extends Control

## ─── ポストストーリーデータ ───────────────────────
## {キャラID: {日数: {EndingType: [{text, face}, ...]}}}
const POST_STORY_DATA: Dictionary = {
	&"chara_01": {
		1: {
			GameManager.EndingType.GOOD: [
				{text = "今日の触れ合いは、思いのほか心地よかったようだ。",         face = &"smile"},
				{text = "「…また、来てもいいですか？」彼女が小さく問いかける。",     face = &"shy"},
				{text = "その言葉に、確かな手応えを感じた。",                       face = &"smile"},
			],
			GameManager.EndingType.NORMAL: [
				{text = "お互いを探り合うような、ぎこちない時間だった。",            face = &"normal"},
				{text = "「今日はもう……いいです」と彼女は背を向けた。",             face = &"shy"},
				{text = "それでも明日も来よう、とあなたは心に決めた。",             face = &"normal"},
			],
			GameManager.EndingType.BAD: [
				{text = "彼女は終始、どこか冷めた目をしていた。",                   face = &"surprise"},
				{text = "「…もう少し、加減してください」声が震えていた。",          face = &"tears"},
				{text = "それでもあなたは、引き返すつもりはなかった。",             face = &"normal"},
			],
		},
		2: {
			GameManager.EndingType.GOOD: [
				{text = "2日目の今日、彼女の表情は昨日より柔らかかった。",          face = &"smile"},
				{text = "「また来てくれたんですね」小さな笑顔が見えた。",           face = &"smile"},
				{text = "距離は確実に縮まっている、あなたはそう感じた。",           face = &"smile"},
			],
			GameManager.EndingType.NORMAL: [
				{text = "2日目も、まだぎこちなさは残っていた。",                   face = &"normal"},
				{text = "「……今日も来たんですね」複雑な表情をした。",              face = &"shy"},
				{text = "あと一歩、踏み込む勇気が必要だった。",                    face = &"normal"},
			],
			GameManager.EndingType.BAD: [
				{text = "彼女の表情は、昨日よりさらに硬くなっていた。",             face = &"surprise"},
				{text = "「あなたって……」言葉が途切れ、首を横に振った。",          face = &"tears"},
				{text = "最後のチャンス、それがあなたにはわかっていた。",           face = &"normal"},
			],
		},
		3: {
			GameManager.EndingType.GOOD: [
				{text = "3日目、彼女はあなたを見て、自分から近づいてきた。",        face = &"smile"},
				{text = "「好き……かもしれない」その言葉が空気を震わせた。",         face = &"blush"},
				{text = "長い時間をかけた、ふたりの答えがそこにあった。",           face = &"smile"},
			],
			GameManager.EndingType.NORMAL: [
				{text = "3日目の終わり、彼女はどこか寂しそうな顔をしていた。",      face = &"shy"},
				{text = "「また……来てもいいですか？」今度は彼女から問いかけた。",   face = &"blush"},
				{text = "完全ではないけれど、何かが変わった気がした。",             face = &"normal"},
			],
			GameManager.EndingType.BAD: [
				{text = "3日目、何かが決定的に壊れた気がした。",                   face = &"tears"},
				{text = "「もう……来ないでください」今度こそ、本気の言葉だった。",   face = &"tears"},
				{text = "その背中を、あなたはただ見送るしかなかった。",             face = &"normal"},
			],
		},
	},
}

const STORY_BODY_PATTERN: String = \
	"res://assets/images/characters/%s/story_body/%s"
const STORY_FACE_PATTERN: String = \
	"res://assets/images/characters/%s/story_face/%s.png"
const BODY_BY_DAY: Array[String] = ["body.png", "halfundress.png", "undress.png"]

const ROUTE_LABEL: Dictionary = {
	GameManager.EndingType.GOOD:   "Good",
	GameManager.EndingType.NORMAL: "Normal",
	GameManager.EndingType.BAD:    "Bad",
}

@onready var chara_sprite: Sprite2D = $CharaSprite
@onready var face_sprite: Sprite2D  = $FaceSprite
@onready var title_label: Label     = $VBoxContainer/TitleLabel
@onready var message_label: Label   = $VBoxContainer/MessageWindow/MessageLabel
@onready var btn_next: Button       = $VBoxContainer/BtnNext

var _lines: Array[Dictionary] = []
var _current_line: int = 0
var _char_id: StringName = &""
var _day_result: GameManager.EndingType = GameManager.EndingType.NORMAL


func _ready() -> void:
	btn_next.pressed.connect(_on_next_pressed)

	_char_id = GameManager.selected_character

	## 日数に応じた story_body をロード
	var day_idx: int = clampi(GameManager.current_day - 1, 0, BODY_BY_DAY.size() - 1)
	var body_path := STORY_BODY_PATTERN % [str(_char_id), BODY_BY_DAY[day_idx]]
	var post_img := Image.load_from_file(ProjectSettings.globalize_path(body_path))
	if post_img:
		chara_sprite.texture = ImageTexture.create_from_image(post_img)

	## 今日の結果を評価・保存
	_day_result = GameManager.evaluate_day_result()

	## タイトルラベル：「Day X - Good / Normal / Bad」
	title_label.text = "Day %d  —  %s" % [
		GameManager.current_day,
		ROUTE_LABEL.get(_day_result, "Normal"),
	]

	## ストーリーデータをセット
	var char_data: Dictionary = POST_STORY_DATA.get(_char_id, {})
	var day_data: Dictionary  = char_data.get(GameManager.current_day, {})
	var raw: Array = day_data.get(_day_result, [{text = "…", face = &"normal"}])
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
	var path := STORY_FACE_PATTERN % [str(_char_id), str(face_name)]
	if ResourceLoader.exists(path):
		face_sprite.texture = load(path)
	else:
		face_sprite.texture = null


func _on_next_pressed() -> void:
	_show_line(_current_line + 1)


func _finish_story() -> void:
	GameManager.save_game()
	if GameManager.current_day >= 3:
		## 3日目終了 → エンディングへ
		get_tree().change_scene_to_file("res://scenes/EndingScene.tscn")
	else:
		## 日を進めてキャラ選択へ
		GameManager.advance_day()
		get_tree().change_scene_to_file("res://scenes/SelectScene.tscn")
