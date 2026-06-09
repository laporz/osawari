extends PanelContainer

const SETTINGS_PATH: String = "user://settings.cfg"

const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160),
]

@onready var resolution_option: OptionButton = $MarginContainer/VBoxContainer/ResolutionRow/ResolutionOption
@onready var fullscreen_check: CheckBox     = $MarginContainer/VBoxContainer/FullscreenCheck
@onready var bgm_slider: HSlider            = $MarginContainer/VBoxContainer/BGMRow/BGMSlider
@onready var se_slider: HSlider             = $MarginContainer/VBoxContainer/SERow/SESlider
@onready var btn_close: Button              = $MarginContainer/VBoxContainer/BtnClose


func _ready() -> void:
	_build_resolution_options()
	_load_settings()

	resolution_option.item_selected.connect(_on_resolution_selected)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	bgm_slider.value_changed.connect(_on_bgm_changed)
	se_slider.value_changed.connect(_on_se_changed)
	btn_close.pressed.connect(hide)


func _build_resolution_options() -> void:
	resolution_option.clear()
	for res: Vector2i in RESOLUTIONS:
		resolution_option.add_item("%dx%d" % [res.x, res.y])


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	var res_index: int = config.get_value("display", "resolution_index", 0)
	resolution_option.selected = res_index
	_apply_resolution(res_index)

	var fs: bool = config.get_value("display", "fullscreen", false)
	fullscreen_check.button_pressed = fs
	_apply_fullscreen(fs)
	resolution_option.disabled = fs

	var bgm_vol: float = config.get_value("audio", "bgm_volume", 1.0)
	var se_vol: float  = config.get_value("audio", "se_volume",  1.0)
	bgm_slider.value = bgm_vol
	se_slider.value  = se_vol
	_apply_bgm_volume(bgm_vol)
	_apply_se_volume(se_vol)


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("display", "resolution_index", resolution_option.selected)
	config.set_value("display", "fullscreen", fullscreen_check.button_pressed)
	config.set_value("audio", "bgm_volume", bgm_slider.value)
	config.set_value("audio", "se_volume",  se_slider.value)
	config.save(SETTINGS_PATH)


func _apply_resolution(index: int) -> void:
	if index < 0 or index >= RESOLUTIONS.size():
		return
	## フルスクリーン中は解像度変更をスキップ（OSが管理するため）
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		return
	var res: Vector2i = RESOLUTIONS[index]
	DisplayServer.window_set_size(res)


func _apply_fullscreen(enabled: bool) -> void:
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		## フルスクリーン解除後に保存済み解像度を再適用
		_apply_resolution(resolution_option.selected)


func _apply_bgm_volume(value: float) -> void:
	var db: float = linear_to_db(value)
	var idx: int = AudioServer.get_bus_index("BGM")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, db)


func _apply_se_volume(value: float) -> void:
	var db: float = linear_to_db(value)
	var idx: int = AudioServer.get_bus_index("SE")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, db)


func _on_resolution_selected(index: int) -> void:
	_apply_resolution(index)
	_save_settings()


func _on_fullscreen_toggled(enabled: bool) -> void:
	_apply_fullscreen(enabled)
	resolution_option.disabled = enabled
	_save_settings()


func _on_bgm_changed(value: float) -> void:
	_apply_bgm_volume(value)
	_save_settings()


func _on_se_changed(value: float) -> void:
	_apply_se_volume(value)
	_save_settings()
