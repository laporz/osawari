extends Control

## ジェム最大数
const MAX_GEMS: int = 5

## 各ステータスの表示設定
const GEM_CONFIGS: Array[Dictionary] = [
	{
		stat    = &"affinity",
		label   = "好感度",
		char    = "♦",
		color_on  = Color(1.0, 0.9, 0.0, 1.0),   ## 黄色
		color_off = Color(0.25, 0.22, 0.05, 1.0),
	},
	{
		stat    = &"arousal",
		label   = "興奮度",
		char    = "❤",
		color_on  = Color(1.0, 0.2, 0.2, 1.0),   ## 赤
		color_off = Color(0.25, 0.06, 0.06, 1.0),
	},
	{
		stat    = &"shyness",
		label   = "羞恥度",
		char    = "♣",
		color_on  = Color(0.3, 0.9, 1.0, 1.0),   ## 水色
		color_off = Color(0.07, 0.22, 0.25, 1.0),
	},
	{
		stat    = &"dependency",
		label   = "依存度",
		char    = "♠",
		color_on  = Color(0.2, 1.0, 0.35, 1.0),  ## 緑
		color_off = Color(0.06, 0.25, 0.1, 1.0),
	},
]

## 動的生成したノードへの参照
var _stat_bars: Dictionary  = {}   ## stat_name -> ProgressBar
var _max_labels: Dictionary = {}   ## stat_name -> Label（MAXオーバーレイ）
var _gem_labels: Dictionary = {}   ## stat_name -> Array[Label]
var _dev_labels: Dictionary = {}   ## part_name -> Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	## パネル作成
	var panel := PanelContainer.new()
	panel.position = Vector2(16.0, 16.0)
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   12)
	margin.add_theme_constant_override("margin_top",     8)
	margin.add_theme_constant_override("margin_right",  12)
	margin.add_theme_constant_override("margin_bottom",  8)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	## ステータス行を生成
	for cfg: Dictionary in GEM_CONFIGS:
		_build_stat_row(vbox, cfg)

	## 開発度セクションを生成
	_build_dev_section(vbox)

	## GameManager シグナルに接続
	GameManager.affinity_changed.connect(func(v: int) -> void: _update_bar(&"affinity", v))
	GameManager.arousal_changed.connect(func(v: int) -> void:  _update_bar(&"arousal",  v))
	GameManager.shyness_changed.connect(func(v: int) -> void:  _update_bar(&"shyness",  v))
	GameManager.dependency_changed.connect(func(v: int) -> void: _update_bar(&"dependency", v))
	GameManager.gem_earned.connect(_on_gem_earned)
	GameManager.part_dev_changed.connect(_on_part_dev_changed)

	## 初期値を反映
	_update_bar(&"affinity",   GameManager.affinity)
	_update_bar(&"arousal",    GameManager.arousal)
	_update_bar(&"shyness",    GameManager.shyness)
	_update_bar(&"dependency", GameManager.dependency)
	_refresh_all_gems()
	_refresh_all_dev()


## ─── ステータス行の生成 ───────────────────────────
func _build_stat_row(parent: VBoxContainer, cfg: Dictionary) -> void:
	var stat_name: StringName = cfg.stat

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	parent.add_child(hbox)

	## ラベル
	var name_lbl := Label.new()
	name_lbl.text = cfg.label
	name_lbl.custom_minimum_size = Vector2(58.0, 0.0)
	name_lbl.add_theme_font_size_override("font_size", 14)
	hbox.add_child(name_lbl)

	## プログレスバー（MAX ラベルをオーバーレイするため Control でラップ）
	var bar_wrap := Control.new()
	bar_wrap.custom_minimum_size = Vector2(130.0, 20.0)
	bar_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(bar_wrap)

	var bar := ProgressBar.new()
	bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bar.min_value = 0.0
	bar.max_value = float(GameManager.MAX_STATUS)
	bar.show_percentage = false
	bar_wrap.add_child(bar)
	_stat_bars[stat_name] = bar

	## MAX オーバーレイラベル（ジェムが MAX_GEMS に達したら表示）
	var max_lbl := Label.new()
	max_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	max_lbl.text = "MAX"
	max_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	max_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	max_lbl.add_theme_font_size_override("font_size", 12)
	max_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	max_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	max_lbl.visible = false
	bar_wrap.add_child(max_lbl)
	_max_labels[stat_name] = max_lbl

	## ジェム枠
	var gem_hbox := HBoxContainer.new()
	gem_hbox.add_theme_constant_override("separation", 2)
	hbox.add_child(gem_hbox)

	var gems: Array[Label] = []
	for _i: int in MAX_GEMS:
		var gem_lbl := Label.new()
		gem_lbl.text = cfg.char
		gem_lbl.add_theme_font_size_override("font_size", 16)
		gem_lbl.custom_minimum_size = Vector2(22.0, 0.0)
		gem_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		gem_lbl.modulate = cfg.color_off
		gem_hbox.add_child(gem_lbl)
		gems.append(gem_lbl)
	_gem_labels[stat_name] = gems


## ─── 開発度セクションの生成 ───────────────────────
func _build_dev_section(parent: VBoxContainer) -> void:
	var sep := HSeparator.new()
	parent.add_child(sep)

	var title_lbl := Label.new()
	title_lbl.text = "開発度"
	title_lbl.add_theme_font_size_override("font_size", 13)
	parent.add_child(title_lbl)

	var dev_hbox := HBoxContainer.new()
	dev_hbox.add_theme_constant_override("separation", 14)
	parent.add_child(dev_hbox)

	for part_name: StringName in [&"head", &"hand", &"chest", &"belly"]:
		var col := VBoxContainer.new()
		dev_hbox.add_child(col)

		var part_lbl := Label.new()
		part_lbl.text = _part_display_name(part_name)
		part_lbl.add_theme_font_size_override("font_size", 12)
		part_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(part_lbl)

		var lv_lbl := Label.new()
		lv_lbl.text = "未"
		lv_lbl.add_theme_font_size_override("font_size", 13)
		lv_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(lv_lbl)
		_dev_labels[part_name] = lv_lbl


## ─── 更新処理 ─────────────────────────────────────
func _update_bar(stat_name: StringName, value: int) -> void:
	if _stat_bars.has(stat_name):
		_stat_bars[stat_name].value = float(value)


func _on_gem_earned(stat_name: StringName, total: int) -> void:
	_update_gems(stat_name, total)


func _update_gems(stat_name: StringName, count: int) -> void:
	if not _gem_labels.has(stat_name):
		return
	var cfg: Dictionary = _get_gem_config(stat_name)
	var gems: Array = _gem_labels[stat_name]
	for i: int in gems.size():
		(gems[i] as Label).modulate = cfg.color_on if i < count else cfg.color_off

	## MAX 到達でバーを満タン固定 & MAX ラベルを表示
	var is_max: bool = count >= GameManager.MAX_GEMS
	if _max_labels.has(stat_name):
		(_max_labels[stat_name] as Label).visible = is_max
	if is_max and _stat_bars.has(stat_name):
		(_stat_bars[stat_name] as ProgressBar).value = float(GameManager.MAX_STATUS)


func _refresh_all_gems() -> void:
	_update_gems(&"affinity",   GameManager.affinity_gems)
	_update_gems(&"arousal",    GameManager.arousal_gems)
	_update_gems(&"shyness",    GameManager.shyness_gems)
	_update_gems(&"dependency", GameManager.dependency_gems)


func _on_part_dev_changed(part_name: StringName, level: int) -> void:
	if _dev_labels.has(part_name):
		(_dev_labels[part_name] as Label).text = _dev_level_text(level)


func _refresh_all_dev() -> void:
	for part_name: StringName in [&"head", &"hand", &"chest", &"belly"]:
		var lv: int = GameManager.get_part_dev_level(part_name)
		if _dev_labels.has(part_name):
			(_dev_labels[part_name] as Label).text = _dev_level_text(lv)


## ─── ユーティリティ ───────────────────────────────
func _dev_level_text(level: int) -> String:
	return "未" if level == 0 else "Lv.%d" % level


func _part_display_name(part_name: StringName) -> String:
	match part_name:
		&"head":  return "頭"
		&"hand":  return "手"
		&"chest": return "胸"
		&"belly": return "腹"
	return str(part_name)


func _get_gem_config(stat_name: StringName) -> Dictionary:
	for cfg: Dictionary in GEM_CONFIGS:
		if cfg.stat == stat_name:
			return cfg
	return {}
