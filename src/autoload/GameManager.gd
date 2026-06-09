extends Node

## エンディング種別
enum EndingType { GOOD, NORMAL, BAD }

## 定数
const MAX_STATUS: int = 100
const MAX_GEMS: int = 5
const GOOD_AFFINITY_THRESHOLD: int = 70
const BAD_AFFINITY_THRESHOLD: int = 30
const BAD_AROUSAL_THRESHOLD: int = 80

## 部位開発度の閾値（タッチ回数）
const DEV_THRESHOLDS: Array[int] = [5, 15, 30, 50]
## 開発度ごとの感度倍率
const DEV_SENSITIVITY: Array[float] = [1.0, 1.2, 1.5, 2.0, 3.0]

const SAVE_PATH: String = "user://save.cfg"

## ─── シグナル ───────────────────────────────────────
signal affinity_changed(value: int)
signal arousal_changed(value: int)
signal shyness_changed(value: int)
signal dependency_changed(value: int)
signal gem_earned(stat_name: StringName, total: int)
signal part_dev_changed(part_name: StringName, level: int)
signal game_saved()
signal game_loaded()

## ─── ステータス（100 到達でジェム加算 & リセット）────
## ジェムが MAX_GEMS に達したらゲージを 100 で固定（MAXロック）
var affinity: int = 0:
	set(value):
		if affinity_gems >= MAX_GEMS:
			affinity = MAX_STATUS          ## MAXロック：常に満タンで固定
			affinity_changed.emit(affinity)
			return
		var v := maxi(value, 0)
		if v >= MAX_STATUS:
			affinity_gems = mini(affinity_gems + v / MAX_STATUS, MAX_GEMS)
			gem_earned.emit(&"affinity", affinity_gems)
			affinity = MAX_STATUS if affinity_gems >= MAX_GEMS else v % MAX_STATUS
		else:
			affinity = v
		affinity_changed.emit(affinity)

var arousal: int = 0:
	set(value):
		if arousal_gems >= MAX_GEMS:
			arousal = MAX_STATUS
			arousal_changed.emit(arousal)
			return
		var v := maxi(value, 0)
		if v >= MAX_STATUS:
			arousal_gems = mini(arousal_gems + v / MAX_STATUS, MAX_GEMS)
			gem_earned.emit(&"arousal", arousal_gems)
			arousal = MAX_STATUS if arousal_gems >= MAX_GEMS else v % MAX_STATUS
		else:
			arousal = v
		arousal_changed.emit(arousal)

var shyness: int = 0:
	set(value):
		if shyness_gems >= MAX_GEMS:
			shyness = MAX_STATUS
			shyness_changed.emit(shyness)
			return
		var v := maxi(value, 0)
		if v >= MAX_STATUS:
			shyness_gems = mini(shyness_gems + v / MAX_STATUS, MAX_GEMS)
			gem_earned.emit(&"shyness", shyness_gems)
			shyness = MAX_STATUS if shyness_gems >= MAX_GEMS else v % MAX_STATUS
		else:
			shyness = v
		shyness_changed.emit(shyness)

var dependency: int = 0:
	set(value):
		if dependency_gems >= MAX_GEMS:
			dependency = MAX_STATUS
			dependency_changed.emit(dependency)
			return
		var v := maxi(value, 0)
		if v >= MAX_STATUS:
			dependency_gems = mini(dependency_gems + v / MAX_STATUS, MAX_GEMS)
			gem_earned.emit(&"dependency", dependency_gems)
			dependency = MAX_STATUS if dependency_gems >= MAX_GEMS else v % MAX_STATUS
		else:
			dependency = v
		dependency_changed.emit(dependency)

## ─── ジェムカウンター ──────────────────────────────
var affinity_gems: int = 0
var arousal_gems: int = 0
var shyness_gems: int = 0
var dependency_gems: int = 0

## ─── 部位開発度 ────────────────────────────────────
var part_touch_counts: Dictionary = {&"head": 0, &"hand": 0, &"chest": 0, &"belly": 0}
var part_dev_levels: Dictionary   = {&"head": 0, &"hand": 0, &"chest": 0, &"belly": 0}

## ─── キャラクター進行 ──────────────────────────────
var selected_character: StringName = &"chara_01"
var unlocked_characters: Array[StringName] = [&"chara_01"]

## ─── 日数・ルート管理 ──────────────────────────────
var current_day: int = 1
## {1: EndingType, 2: EndingType, 3: EndingType}
var day_results: Dictionary = {}


func _ready() -> void:
	pass


## 新規ゲーム開始時にすべてリセット
func reset() -> void:
	current_day  = 1
	day_results  = {}
	affinity     = 0
	arousal      = 0
	shyness      = 0
	dependency   = 0
	affinity_gems    = 0
	arousal_gems     = 0
	shyness_gems     = 0
	dependency_gems  = 0
	part_touch_counts = {&"head": 0, &"hand": 0, &"chest": 0, &"belly": 0}
	part_dev_levels   = {&"head": 0, &"hand": 0, &"chest": 0, &"belly": 0}


## 日を進める（ステータス値のみリセット、ジェム・開発度は持ち越し）
func advance_day() -> void:
	current_day += 1
	## ステータス値リセット（ジェムMAX済みの場合はセッターが MAX_STATUS に固定）
	affinity   = 0
	arousal    = 0
	shyness    = 0
	dependency = 0
	## タッチカウントを現在の開発レベルを維持できる最小値に設定
	for part_name: StringName in part_touch_counts.keys():
		var lv: int = part_dev_levels.get(part_name, 0)
		part_touch_counts[part_name] = DEV_THRESHOLDS[lv - 1] if lv > 0 else 0


## 現在の日のゲーム結果を評価して保存し、EndingType を返す
func evaluate_day_result() -> EndingType:
	var result: EndingType = _calc_day_result()
	day_results[current_day] = result
	return result


func _calc_day_result() -> EndingType:
	var dep: int = get_dependency_total()
	var af: int  = get_affinity_total()
	var ar: int  = get_arousal_total()
	match current_day:
		1:
			if ar >= 200 or dep < 100:
				return EndingType.BAD
			if dep >= 200 and af >= 200:
				return EndingType.GOOD
		2:
			if ar >= 400 or dep < 200:
				return EndingType.BAD
			if dep >= 400 and af >= 400:
				return EndingType.GOOD
		3:
			if ar >= 500 or dep < 300:
				return EndingType.BAD
			if dep >= 500 and af >= 500:
				return EndingType.GOOD
	return EndingType.NORMAL


## ─── ステータス加算 ────────────────────────────────
func add_affinity(amount: int) -> void:
	affinity += amount

func add_arousal(amount: int) -> void:
	arousal += amount

func add_shyness(amount: int) -> void:
	shyness += amount

func add_dependency(amount: int) -> void:
	dependency += amount


## ─── 部位タッチ ────────────────────────────────────
## タッチを記録して開発度を更新。新しい開発レベルを返す
func add_part_touch(part_name: StringName) -> int:
	if not part_touch_counts.has(part_name):
		part_touch_counts[part_name] = 0
	part_touch_counts[part_name] += 1
	var new_level: int = _compute_dev_level(part_touch_counts[part_name])
	if new_level != part_dev_levels.get(part_name, 0):
		part_dev_levels[part_name] = new_level
		part_dev_changed.emit(part_name, new_level)
	return new_level


func get_part_dev_level(part_name: StringName) -> int:
	return part_dev_levels.get(part_name, 0)


## 開発度に応じた感度倍率を返す
func get_part_sensitivity(part_name: StringName) -> float:
	var lv: int = get_part_dev_level(part_name)
	return DEV_SENSITIVITY[mini(lv, DEV_SENSITIVITY.size() - 1)]


func _compute_dev_level(touch_count: int) -> int:
	var level: int = 0
	for threshold: int in DEV_THRESHOLDS:
		if touch_count >= threshold:
			level += 1
		else:
			break
	return level


## ─── トータル値（現在値 + ジェム数 × 100）─────────
## 表情・エンディング判定はこちらを使う（0〜500）
func get_affinity_total() -> int:
	return affinity + affinity_gems * MAX_STATUS

func get_arousal_total() -> int:
	return arousal + arousal_gems * MAX_STATUS

func get_shyness_total() -> int:
	return shyness + shyness_gems * MAX_STATUS

func get_dependency_total() -> int:
	return dependency + dependency_gems * MAX_STATUS


## ─── エンディング種別（3日目の結果を返す）──────────
## EndingScene から呼び出す
func get_ending_type() -> EndingType:
	return day_results.get(3, EndingType.NORMAL)


## ─── キャラクター解放 ──────────────────────────────
func unlock_character(char_name: StringName) -> void:
	if not unlocked_characters.has(char_name):
		unlocked_characters.append(char_name)


## ─── セーブ / ロード ───────────────────────────────
func save_game() -> void:
	var config := ConfigFile.new()
	config.set_value("status", "affinity",   affinity)
	config.set_value("status", "arousal",    arousal)
	config.set_value("status", "shyness",    shyness)
	config.set_value("status", "dependency", dependency)
	config.set_value("gems", "affinity",   affinity_gems)
	config.set_value("gems", "arousal",    arousal_gems)
	config.set_value("gems", "shyness",    shyness_gems)
	config.set_value("gems", "dependency", dependency_gems)
	for part_name: StringName in part_touch_counts:
		config.set_value("parts", str(part_name), part_touch_counts[part_name])
	var unlocked_str: Array[String] = []
	for c: StringName in unlocked_characters:
		unlocked_str.append(str(c))
	config.set_value("progress", "unlocked", unlocked_str)
	config.set_value("progress", "current_day", current_day)
	for day_key: int in day_results:
		config.set_value("day_results", str(day_key), int(day_results[day_key]))
	config.save(SAVE_PATH)
	game_saved.emit()


func load_game() -> bool:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return false
	affinity   = config.get_value("status", "affinity",   0)
	arousal    = config.get_value("status", "arousal",    0)
	shyness    = config.get_value("status", "shyness",    0)
	dependency = config.get_value("status", "dependency", 0)
	affinity_gems   = config.get_value("gems", "affinity",   0)
	arousal_gems    = config.get_value("gems", "arousal",    0)
	shyness_gems    = config.get_value("gems", "shyness",    0)
	dependency_gems = config.get_value("gems", "dependency", 0)
	for part_name: StringName in part_touch_counts.keys():
		part_touch_counts[part_name] = config.get_value("parts", str(part_name), 0)
		part_dev_levels[part_name]   = _compute_dev_level(part_touch_counts[part_name])
	var unlocked_arr: Array = config.get_value("progress", "unlocked", ["chara_01"])
	unlocked_characters.clear()
	for c: Variant in unlocked_arr:
		unlocked_characters.append(StringName(str(c)))
	current_day = config.get_value("progress", "current_day", 1)
	day_results = {}
	for day_key: int in [1, 2, 3]:
		var val: int = config.get_value("day_results", str(day_key), -1)
		if val >= 0:
			day_results[day_key] = val as EndingType
	game_loaded.emit()
	return true


func has_save_data() -> bool:
	return FileAccess.file_exists(SAVE_PATH)
