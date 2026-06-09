extends Control

## キャラクター定義
const CHAR_DATA: Array[Dictionary] = [
	{
		id        = &"chara_01",
		disp_name = "??",
		body_path = "res://assets/images/characters/chara_01/body/body.png",
	},
	{
		id        = &"chara_02",
		disp_name = "??",
		body_path = "res://assets/images/characters/chara_02/body/body.png",
	},
	{
		id        = &"chara_03",
		disp_name = "??",
		body_path = "res://assets/images/characters/chara_03/image.png",
	},
]

const ROUTE_LABEL: Dictionary = {
	GameManager.EndingType.GOOD:   "Good",
	GameManager.EndingType.NORMAL: "Normal",
	GameManager.EndingType.BAD:    "Bad",
}

@onready var card_container: HBoxContainer = $VBoxContainer/CardContainer
@onready var btn_back: Button              = $VBoxContainer/BtnBack
@onready var day_label: Label              = $VBoxContainer/DayLabel


func _ready() -> void:
	btn_back.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/TitleScene.tscn")
	)
	day_label.text = "Day %d" % GameManager.current_day
	_build_cards()


func _build_cards() -> void:
	for data: Dictionary in CHAR_DATA:
		card_container.add_child(_create_card(data))


func _create_card(data: Dictionary) -> PanelContainer:
	var is_unlocked: bool = GameManager.unlocked_characters.has(data.id)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(280.0, 420.0)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   12)
	margin.add_theme_constant_override("margin_top",    12)
	margin.add_theme_constant_override("margin_right",  12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	## ─── ポートレート ───────────────────────────────
	var portrait_wrap := Control.new()
	portrait_wrap.custom_minimum_size = Vector2(240.0, 320.0)
	vbox.add_child(portrait_wrap)

	var portrait := TextureRect.new()
	portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(data.body_path):
		portrait.texture = load(data.body_path)
	if not is_unlocked:
		portrait.modulate = Color(0.3, 0.3, 0.3, 1.0)
	portrait_wrap.add_child(portrait)

	## ロック中はオーバーレイを追加
	if not is_unlocked:
		var overlay := ColorRect.new()
		overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		overlay.color = Color(0.0, 0.0, 0.0, 0.5)
		portrait_wrap.add_child(overlay)

		var lock_lbl := Label.new()
		lock_lbl.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		lock_lbl.text = "🔒"
		lock_lbl.add_theme_font_size_override("font_size", 48)
		lock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		portrait_wrap.add_child(lock_lbl)

	## ─── キャラ名 ───────────────────────────────────
	var name_lbl := Label.new()
	name_lbl.text = data.disp_name if is_unlocked else "???"
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 20)
	vbox.add_child(name_lbl)

	## ─── 日別ルート履歴 ─────────────────────────────
	if is_unlocked and not GameManager.day_results.is_empty():
		var history_lbl := Label.new()
		var history_text := ""
		for day_key: int in [1, 2, 3]:
			if GameManager.day_results.has(day_key):
				var r: GameManager.EndingType = GameManager.day_results[day_key]
				history_text += "%s (Day %d)\n" % [ROUTE_LABEL.get(r, "?"), day_key]
		history_lbl.text = history_text.strip_edges()
		history_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		history_lbl.add_theme_font_size_override("font_size", 14)
		history_lbl.modulate = Color(0.9, 0.85, 0.6)
		vbox.add_child(history_lbl)

	## ─── ボタン ─────────────────────────────────────
	if is_unlocked:
		var btn := Button.new()
		btn.text = "Day %d 開始" % GameManager.current_day
		btn.custom_minimum_size = Vector2(180.0, 44.0)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var char_id: StringName = data.id
		btn.pressed.connect(func() -> void: _on_character_selected(char_id))
		vbox.add_child(btn)
	else:
		var locked_lbl := Label.new()
		locked_lbl.text = "未解放"
		locked_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		locked_lbl.add_theme_font_size_override("font_size", 16)
		locked_lbl.modulate = Color(0.6, 0.6, 0.6)
		vbox.add_child(locked_lbl)

	return panel


func _on_character_selected(char_id: StringName) -> void:
	GameManager.selected_character = char_id
	## reset() はここでは呼ばない。
	## 新規ゲーム開始時は TitleScene 側で reset() 済み。
	## 日付継続時はジェム・開発度を持ち越すため reset() 不要。
	get_tree().change_scene_to_file("res://scenes/PreStoryScene.tscn")
