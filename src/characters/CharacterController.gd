extends Node2D

## 部位ごとのステータス定義
class BodyPartStatus:
	var sensitivity: float = 1.0  ## 感度倍率
	var touch_count: int   = 0    ## お触り回数

## 各部位の affinity/arousal/shyness 加算量（部位名をキーにする）
const TOUCH_AFFINITY: Dictionary = {
	&"head":  5,
	&"chest": 8,
	&"belly": 6,
	&"hand":  3,
}
const TOUCH_AROUSAL: Dictionary = {
	&"head":  2,
	&"chest": 10,
	&"belly": 7,
	&"hand":  2,
}
const TOUCH_SHYNESS: Dictionary = {
	&"head":  3,
	&"chest": 8,
	&"belly": 6,
	&"hand":  2,
}

## リアクションアニメのパラメータ
const SHAKE_AMOUNT: float  = 8.0
const SHAKE_DURATION: float = 0.08
const SHAKE_COUNT: int      = 3

@onready var sprite: Sprite2D = $Sprite2D

## 部位ごとのステータスを保持する辞書
var _part_status: Dictionary = {}

## リアクション中に元の位置を保持する
var _base_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	_base_position = position

	## 子の BodyPartArea2D をすべて検出してシグナルを接続する
	for child: Node in get_children():
		if child is Area2D and child.has_signal(&"touch_detected"):
			child.touch_detected.connect(_on_touch_detected)
			_part_status[child.body_part_name] = BodyPartStatus.new()


func _on_touch_detected(part_name: StringName) -> void:
	## ステータス更新
	if not _part_status.has(part_name):
		_part_status[part_name] = BodyPartStatus.new()
	var status: BodyPartStatus = _part_status[part_name]
	status.touch_count += 1
	var multiplier: float = status.sensitivity

	GameManager.add_affinity(int(TOUCH_AFFINITY.get(part_name, 3) * multiplier))
	GameManager.add_arousal(int(TOUCH_AROUSAL.get(part_name, 2) * multiplier))
	GameManager.add_shyness(int(TOUCH_SHYNESS.get(part_name, 2) * multiplier))

	## リアクションアニメーション（ぷるぷる）
	_play_shake_reaction()


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


## 外部から感度を設定するユーティリティ
func set_sensitivity(part_name: StringName, value: float) -> void:
	if not _part_status.has(part_name):
		_part_status[part_name] = BodyPartStatus.new()
	(_part_status[part_name] as BodyPartStatus).sensitivity = value


func get_touch_count(part_name: StringName) -> int:
	if not _part_status.has(part_name):
		return 0
	return (_part_status[part_name] as BodyPartStatus).touch_count
