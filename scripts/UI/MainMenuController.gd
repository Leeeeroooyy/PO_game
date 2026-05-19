class_name MainMenuController
extends Control

signal start_pressed
signal quit_pressed

const MenuBackdropScript := preload("res://scripts/UI/MenuBackdrop.gd")
const MenuImageBackgroundScript := preload("res://scripts/UI/MenuImageBackground.gd")

var _music_slider: HSlider
var _effects_slider: HSlider
var _updating_audio_sliders := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_bind_audio_director()

	var image_background := MenuImageBackgroundScript.new() as MenuImageBackground
	image_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(image_background)

	var backdrop := MenuBackdropScript.new() as MenuBackdrop
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.accent_color = Color(0.90, 0.62, 0.26)
	add_child(backdrop)

	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.0, 0.0, 0.0, 0.32)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 68)
	margin.add_theme_constant_override("margin_right", 68)
	margin.add_theme_constant_override("margin_top", 54)
	margin.add_theme_constant_override("margin_bottom", 54)
	add_child(margin)

	var root := HBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 42)
	margin.add_child(root)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	left.add_theme_constant_override("separation", 18)
	root.add_child(left)

	var title := Label.new()
	title.text = "Last Stand: Three Fronts"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 58)
	title.add_theme_color_override("font_color", Color(0.98, 0.92, 0.78))
	title.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.72))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	left.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Three lanes, one hero, a war camp that grows with every wave."
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.custom_minimum_size = Vector2(520.0, 0.0)
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_color", Color(0.78, 0.84, 0.78))
	left.add_child(subtitle)

	var pillars := HBoxContainer.new()
	pillars.add_theme_constant_override("separation", 12)
	left.add_child(pillars)
	for text in ["Push lanes", "Upgrade waves", "Scale skills"]:
		pillars.add_child(_create_tag(text))

	var menu_panel := PanelContainer.new()
	menu_panel.custom_minimum_size = Vector2(360.0, 460.0)
	menu_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	menu_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.055, 0.065, 0.063, 0.92), Color(0.82, 0.60, 0.30, 0.45)))
	root.add_child(menu_panel)

	var menu_margin := MarginContainer.new()
	menu_margin.add_theme_constant_override("margin_left", 24)
	menu_margin.add_theme_constant_override("margin_right", 24)
	menu_margin.add_theme_constant_override("margin_top", 24)
	menu_margin.add_theme_constant_override("margin_bottom", 24)
	menu_panel.add_child(menu_margin)

	var menu := VBoxContainer.new()
	menu.alignment = BoxContainer.ALIGNMENT_CENTER
	menu.add_theme_constant_override("separation", 14)
	menu_margin.add_child(menu)

	var menu_title := Label.new()
	menu_title.text = "Command"
	menu_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_title.add_theme_font_size_override("font_size", 28)
	menu_title.add_theme_color_override("font_color", Color(0.95, 0.86, 0.64))
	menu.add_child(menu_title)

	var start_button := _create_menu_button("Choose Hero")
	start_button.pressed.connect(func() -> void: start_pressed.emit())
	menu.add_child(start_button)

	var settings_title := Label.new()
	settings_title.text = "Audio"
	settings_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	settings_title.add_theme_font_size_override("font_size", 18)
	settings_title.add_theme_color_override("font_color", Color(0.82, 0.90, 0.78))
	menu.add_child(settings_title)

	_music_slider = _create_volume_slider(_get_audio_volume("get_music_volume", 0.75))
	_music_slider.value_changed.connect(func(value: float) -> void: _set_audio_volume("set_music_volume", value))
	menu.add_child(_create_volume_row("Music", _music_slider))

	_effects_slider = _create_volume_slider(_get_audio_volume("get_effects_volume", 0.85))
	_effects_slider.value_changed.connect(func(value: float) -> void: _set_audio_volume("set_effects_volume", value))
	menu.add_child(_create_volume_row("Effects", _effects_slider))

	var quit_button := _create_menu_button("Quit")
	quit_button.pressed.connect(func() -> void: quit_pressed.emit())
	menu.add_child(quit_button)

	var hint := Label.new()
	hint.text = "Build your hero before entering the battlefield."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.66, 0.73, 0.68))
	menu.add_child(hint)


func _create_menu_button(text_value: String) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(250.0, 54.0)
	button.add_theme_font_size_override("font_size", 19)
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


func _create_tag(text_value: String) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(138.0, 34.0)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.08, 0.10, 0.095, 0.78), Color(0.54, 0.64, 0.46, 0.36)))

	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(0.92, 0.86, 0.68))
	panel.add_child(label)
	return panel


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
