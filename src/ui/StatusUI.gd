extends Control

@onready var affinity_bar: ProgressBar = $VBoxContainer/AffinityRow/AffinityBar
@onready var arousal_bar: ProgressBar  = $VBoxContainer/ArousalRow/ArousalBar
@onready var shyness_bar: ProgressBar  = $VBoxContainer/ShynessRow/ShynessBar

@onready var affinity_label: Label = $VBoxContainer/AffinityRow/AffinityLabel
@onready var arousal_label: Label  = $VBoxContainer/ArousalRow/ArousalLabel
@onready var shyness_label: Label  = $VBoxContainer/ShynessRow/ShynessLabel


func _ready() -> void:
	## 初期値を反映
	_update_affinity(GameManager.affinity)
	_update_arousal(GameManager.arousal)
	_update_shyness(GameManager.shyness)

	## GameManager のシグナルに接続（疎結合）
	GameManager.affinity_changed.connect(_update_affinity)
	GameManager.arousal_changed.connect(_update_arousal)
	GameManager.shyness_changed.connect(_update_shyness)


func _update_affinity(value: int) -> void:
	affinity_bar.value = value
	affinity_label.text = "好感度: %d" % value


func _update_arousal(value: int) -> void:
	arousal_bar.value = value
	arousal_label.text = "興奮度: %d" % value


func _update_shyness(value: int) -> void:
	shyness_bar.value = value
	shyness_label.text = "羞恥度: %d" % value
