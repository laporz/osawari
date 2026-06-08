extends Area2D

## 部位名（Inspectorから設定する）
@export var body_part_name: StringName = &"unknown"

signal touch_detected(part_name: StringName)


func _ready() -> void:
	input_pickable = true


func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			touch_detected.emit(body_part_name)
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.pressed:
			touch_detected.emit(body_part_name)
