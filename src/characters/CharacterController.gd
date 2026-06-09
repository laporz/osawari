extends Node2D

## 基本タッチ加算量（感度倍率を掛ける前の値）
const TOUCH_AMOUNT: int = 5
## 全タッチ共通の依存度加算量
const DEPENDENCY_PER_TOUCH: int = 2

## リアクションアニメのパラメータ
const SHAKE_AMOUNT: float   = 8.0
const SHAKE_DURATION: float = 0.08
const SHAKE_COUNT: int      = 3

@onready var sprite: Sprite2D      = $Sprite2D
@onready var face_sprite: Sprite2D = $FaceSprite

## 日数ごとの素体ファイル名（1日目〜3日目）
const BODY_BY_DAY: Array[String] = ["body.png", "halfundress.png", "undress.png"]

## 表情差分テクスチャパス（キャラIDは実行時に解決）
const FACE_NAMES: Array[StringName] = [
	&"normal", &"smile", &"shy", &"surprise",
	&"blush", &"evilsmile", &"ahegao", &"tears",
]

var _base_position: Vector2 = Vector2.ZERO
var _char_id: StringName = &""


func _ready() -> void:
	_base_position = position
	_char_id = GameManager.selected_character

	## 日数に応じた素体をロード
	var day_idx: int = clampi(GameManager.current_day - 1, 0, BODY_BY_DAY.size() - 1)
	var body_path := "res://assets/images/characters/%s/body/%s" % \
		[str(_char_id), BODY_BY_DAY[day_idx]]
	var img := Image.load_from_file(ProjectSettings.globalize_path(body_path))
	if img:
		sprite.texture = ImageTexture.create_from_image(img)

	## 初期表情をロード
	set_face(&"normal")

	## 子の BodyPartArea2D をすべて検出してシグナルを接続する
	for child: Node in get_children():
		if child is Area2D and child.has_signal(&"touch_detected"):
			child.touch_detected.connect(_on_touch_detected)


func _on_touch_detected(part_name: StringName) -> void:
	## 部位タッチを GameManager に記録して感度を取得
	var sensitivity: float = GameManager.get_part_sensitivity(part_name)
	GameManager.add_part_touch(part_name)
	var amt: int = int(TOUCH_AMOUNT * sensitivity)

	match part_name:
		&"head", &"hand":
			GameManager.add_affinity(amt)
		&"chest":
			GameManager.add_arousal(amt)
			GameManager.add_shyness(amt)
		&"belly":
			## 好感度ジェムを1個以上獲得 or 好感度が50以上なら興奮度を加算
			if GameManager.affinity_gems > 0 or GameManager.affinity >= 50:
				GameManager.add_arousal(amt)
			else:
				GameManager.add_shyness(amt)

	## 全タッチ共通で依存度を加算
	GameManager.add_dependency(DEPENDENCY_PER_TOUCH)

	_update_face()
	_play_shake_reaction()


## ステータスのトータル値（0〜500）に応じて表情を切り替える
##
##  トータル値 = 現在値 + ジェム数 × 100
##  ジェムが溜まっても表情がリセットされなくなる
##
##  閾値一覧（優先度順）:
##    ahegao   : 興奮度 ≥ 400
##    tears    : 羞恥度 ≥ 300
##    evilsmile: 興奮度 ≥ 200
##    blush    : 羞恥度 ≥ 200
##    surprise : 興奮度 ≥ 100
##    shy      : 羞恥度 ≥ 100
##    smile    : 好感度 ≥ 100
##    normal   : それ以外
##
func _update_face() -> void:
	var ar: int = GameManager.get_arousal_total()
	var sh: int = GameManager.get_shyness_total()
	var af: int = GameManager.get_affinity_total()

	if ar >= 400:
		set_face(&"ahegao")
	elif sh >= 300:
		set_face(&"tears")
	elif ar >= 200:
		set_face(&"evilsmile")
	elif sh >= 200:
		set_face(&"blush")
	elif ar >= 100:
		set_face(&"surprise")
	elif sh >= 100:
		set_face(&"shy")
	elif af >= 100:
		set_face(&"smile")
	else:
		set_face(&"normal")


## 表情差分テクスチャを切り替える（face/ フォルダ・顔のみ透過PNG）
func set_face(face_name: StringName) -> void:
	if face_name not in FACE_NAMES:
		return
	var path := "res://assets/images/characters/%s/face/%s.png" % \
		[str(_char_id), str(face_name)]
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	if img:
		face_sprite.texture = ImageTexture.create_from_image(img)


## Tween で横方向に微振動させるリアクション
func _play_shake_reaction() -> void:
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	for i: int in SHAKE_COUNT:
		var direction: float = 1.0 if i % 2 == 0 else -1.0
		tween.tween_property(
			self, "position",
			_base_position + Vector2(SHAKE_AMOUNT * direction, 0.0),
			SHAKE_DURATION
		)
	tween.tween_property(self, "position", _base_position, SHAKE_DURATION)
