class_name PauseMenuController
extends Control

signal resume_requested
signal main_menu_requested

var _settings_box: VBoxContainer
var _music_slider: HSlider
var _effects_slider: HSlider
var _updating_audio_sliders := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_bind_audio_director()
	_build_ui()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		resume_requested.emit()
		get_viewport().set_input_as_handled()


func _build_ui() -> void:
	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.0, 0.0, 0.0, 0.58)
	add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(360.0, 0.0)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.055, 0.065, 0.063, 0.96), Color(0.82, 0.60, 0.30, 0.52)))
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var menu := VBoxContainer.new()
	menu.alignment = BoxContainer.ALIGNMENT_CENTER
	menu.add_theme_constant_override("separation", 14)
	margin.add_child(menu)

	var title := Label.new()
	title.text = "Paused"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.95, 0.86, 0.64))
	menu.add_child(title)

	var resume_button := _create_menu_button("Continue")
	resume_button.pressed.connect(func() -> void: resume_requested.emit())
	menu.add_child(resume_button)

	var settings_button := _create_menu_button("Settings")
	settings_button.pressed.connect(_toggle_settings)
	menu.add_child(settings_button)

	_settings_box = VBoxContainer.new()
	_settings_box.visible = false
	_settings_box.add_theme_constant_override("separation", 10)
	menu.add_child(_settings_box)

	_music_slider = _create_volume_slider(_get_audio_volume("get_music_volume", 0.75))
	_music_slider.value_changed.connect(func(value: float) -> void: _set_audio_volume("set_music_volume", value))
	_settings_box.add_child(_create_volume_row("Music", _music_slider))

	_effects_slider = _create_volume_slider(_get_audio_volume("get_effects_volume", 0.85))
	_effects_slider.value_changed.connect(func(value: float) -> void: _set_audio_volume("set_effects_volume", value))
	_settings_box.add_child(_create_volume_row("Effects", _effects_slider))

	var menu_button := _create_menu_button("Main Menu")
	menu_button.pressed.connect(func() -> void: main_menu_requested.emit())
	menu.add_child(menu_button)


func _toggle_settings() -> void:
	if _settings_box != null:
		_settings_box.visible = not _settings_box.visible


func _create_menu_button(text_value: String) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(250.0, 52.0)
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_stylebox_override("normal", _button_style(Color(0.14, 0.18, 0.17), Color(0.58, 0.44, 0.24)))
	button.add_theme_stylebox_override("hover", _button_style(Color(0.20, 0.25, 0.22), Color(0.96, 0.72, 0.32)))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.10, 0.12, 0.11), Color(0.96, 0.72, 0.32)))
	return button


func _create_volume_slider(value: float) -> HSlider:
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = clampf(value, 0.0, 1.0)
	slider.custom_minimum_size = Vector2(160.0, 28.0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return slider


func _create_volume_row(text_value: String, slider: HSlider) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(250.0, 34.0)
	row.add_theme_constant_override("separation", 12)

	var label := Label.new()
	label.text = text_value
	label.custom_minimum_size = Vector2(72.0, 0.0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.90, 0.86, 0.70))
	row.add_child(label)

	row.add_child(slider)
	return row


func _panel_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _button_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := _panel_style(bg, border)
	style.set_border_width_all(2)
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


func _bind_audio_director() -> void:
	var audio := _get_audio_director()
	if audio == null or not audio.has_signal("volumes_changed"):
		return

	var callback := Callable(self, "_on_audio_volumes_changed")
	if not audio.is_connected("volumes_changed", callback):
		audio.connect("volumes_changed", callback)


func _get_audio_director() -> Node:
	return get_node_or_null("/root/AudioDirector")


func _get_audio_volume(method_name: String, fallback: float) -> float:
	var audio := _get_audio_director()
	if audio == null or not audio.has_method(method_name):
		return fallback

	return clampf(float(audio.call(method_name)), 0.0, 1.0)


func _set_audio_volume(method_name: String, value: float) -> void:
	if _updating_audio_sliders:
		return

	var audio := _get_audio_director()
	if audio != null and audio.has_method(method_name):
		audio.call(method_name, value)


func _on_audio_volumes_changed(music_volume: float, effects_volume: float) -> void:
	_updating_audio_sliders = true
	if _music_slider != null:
		_music_slider.value = music_volume
	if _effects_slider != null:
		_effects_slider.value = effects_volume
	_updating_audio_sliders = false
