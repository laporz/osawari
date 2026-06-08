extends Node2D

## 部位ごとのステータス定義
class BodyPartStatus:
	var sensitivity: float = 1.0  ## 感度倍率
	var touch_count: int   = 0    ## お触り回数

## 部位ごとの加算量
const TOUCH_AMOUNT: int = 5

## リアクションアニメのパラメータ
const SHAKE_AMOUNT: float  = 8.0
const SHAKE_DURATION: float = 0.08
const SHAKE_COUNT: int      = 3

@onready var sprite: Sprite2D = $Sprite2D
@onready var face_sprite: Sprite2D = $FaceSprite

const FACE_TEXTURES: Dictionary = {
	&"normal":    "res://assets/images/characters/chara_01/face/normal.png",
	&"smile":     "res://assets/images/characters/chara_01/face/smile.png",
	&"shy":       "res://assets/images/characters/chara_01/face/shy.png",
	&"surprise":  "res://assets/images/characters/chara_01/face/surprise.png",
	&"blush":     "res://assets/images/characters/chara_01/face/blush.png",
	&"evilsmile": "res://assets/images/characters/chara_01/face/evilsmile.png",
	&"ahegao":    "res://assets/images/characters/chara_01/face/ahegao.png",
	&"tears":     "res://assets/images/characters/chara_01/face/tears.png",
}

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
	if not _part_status.has(part_name):
		_part_status[part_name] = BodyPartStatus.new()
	var status: BodyPartStatus = _part_status[part_name]
	status.touch_count += 1
	var amt: int = int(TOUCH_AMOUNT * status.sensitivity)

	match part_name:
		&"head", &"hand":
			GameManager.add_affinity(amt)
		&"chest":
			GameManager.add_arousal(amt)
			GameManager.add_shyness(amt)
		&"belly":
			if GameManager.affinity >= GameManager.MAX_STATUS:
				GameManager.add_arousal(amt)
			else:
				GameManager.add_shyness(amt)

	_update_face()
	_play_shake_reaction()


func _update_face() -> void:
	var affinity: int = GameManager.affinity
	var arousal: int  = GameManager.arousal
	var shyness: int  = GameManager.shyness

	if arousal >= 80:
		set_face(&"ahegao")
	elif shyness >= 80:
		set_face(&"tears")
	elif arousal >= 60:
		set_face(&"evilsmile")
	elif shyness >= 60:
		set_face(&"blush")
	elif arousal >= 40:
		set_face(&"surprise")
	elif shyness >= 40:
		set_face(&"shy")
	elif affinity >= 40:
		set_face(&"smile")
	else:
		set_face(&"normal")


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


## 表情差分を切り替える
func set_face(face_name: StringName) -> void:
	if FACE_TEXTURES.has(face_name):
		face_sprite.texture = load(FACE_TEXTURES[face_name])


## 外部から感度を設定するユーティリティ
func set_sensitivity(part_name: StringName, value: float) -> void:
	if not _part_status.has(part_name):
		_part_status[part_name] = BodyPartStatus.new()
	(_part_status[part_name] as BodyPartStatus).sensitivity = value


func get_touch_count(part_name: StringName) -> int:
	if not _part_status.has(part_name):
		return 0
	return (_part_status[part_name] as BodyPartStatus).touch_count
