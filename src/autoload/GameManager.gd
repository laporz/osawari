extends Node

## エンディング種別
enum EndingType { GOOD, NORMAL, BAD }

## 分岐閾値定数
const GOOD_AFFINITY_THRESHOLD: int = 70
const BAD_AFFINITY_THRESHOLD: int = 30
const BAD_AROUSAL_THRESHOLD: int = 80

## ステータス上限
const MAX_STATUS: int = 100

## セーブファイルパス
const SAVE_PATH: String = "user://save.cfg"

## シグナル
signal affinity_changed(value: int)
signal arousal_changed(value: int)
signal shyness_changed(value: int)
signal game_saved()
signal game_loaded()

## ステータス
var affinity: int = 0 :
	set(value):
		affinity = clampi(value, 0, MAX_STATUS)
		affinity_changed.emit(affinity)

var arousal: int = 0 :
	set(value):
		arousal = clampi(value, 0, MAX_STATUS)
		arousal_changed.emit(arousal)

var shyness: int = 0 :
	set(value):
		shyness = clampi(value, 0, MAX_STATUS)
		shyness_changed.emit(shyness)


func _ready() -> void:
	pass


## ステータスをゲーム開始時の初期値にリセットする
func reset() -> void:
	affinity = 0
	arousal = 0
	shyness = 0


## 各ステータスを加算する
func add_affinity(amount: int) -> void:
	affinity += amount

func add_arousal(amount: int) -> void:
	arousal += amount

func add_shyness(amount: int) -> void:
	shyness += amount


## ステータスに基づいてエンディング種別を返す
func get_ending_type() -> EndingType:
	if arousal >= BAD_AROUSAL_THRESHOLD:
		return EndingType.BAD
	if affinity >= GOOD_AFFINITY_THRESHOLD:
		return EndingType.GOOD
	if affinity <= BAD_AFFINITY_THRESHOLD:
		return EndingType.BAD
	return EndingType.NORMAL


## セーブ
func save_game() -> void:
	var config := ConfigFile.new()
	config.set_value("status", "affinity", affinity)
	config.set_value("status", "arousal", arousal)
	config.set_value("status", "shyness", shyness)
	config.save(SAVE_PATH)
	game_saved.emit()


## ロード。セーブデータが存在しない場合は false を返す
func load_game() -> bool:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return false
	affinity = config.get_value("status", "affinity", 0)
	arousal  = config.get_value("status", "arousal",  0)
	shyness  = config.get_value("status", "shyness",  0)
	game_loaded.emit()
	return true


## セーブデータが存在するか確認する
func has_save_data() -> bool:
	return FileAccess.file_exists(SAVE_PATH)
