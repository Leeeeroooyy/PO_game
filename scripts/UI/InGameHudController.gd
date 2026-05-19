class_name InGameHudController
extends Control

signal shop_requested

const HeroPortraitViewScript := preload("res://scripts/UI/HeroPortraitView.gd")
const HUD_BOTTOM_FRAME: Texture2D = preload("res://assets/ui/hud_bottom_frame.png")
const HUD_TIMER_FRAME: Texture2D = preload("res://assets/ui/hud_timer_frame.png")

var _gold_label: Button
var _experience_label: Label
var _health_label: Label
var _health_progress: ProgressBar
var _experience_progress: ProgressBar
var _hero_label: Label
var _portrait_name_label: Label
var _combat_stats_label: Label
var _utility_stats_label: Label
var _wave_timer_label: Label
var _skill_points_label: Label
var _death_overlay: Control
var _death_timer_label: Label
var _ability_tooltip_panel: PanelContainer
var _ability_tooltip_label: RichTextLabel
var _hovered_ability_slot := -1
var _portrait_view: HeroPortraitView
var _ability_slots: Array[Control] = []
var _ability_name_labels: Array[Label] = []
var _ability_cooldown_labels: Array[Label] = []
var _ability_level_labels: Array[Label] = []
var _ability_upgrade_labels: Array[Label] = []
var _economy: EconomySystem
var _experience: ExperienceSystem
var _hero: HeroController
var _selected_actor: Actor
var _hud_process_timer := 0.0


func _process(delta: float) -> void:
	_hud_process_timer = maxf(0.0, _hud_process_timer - delta)
	if _hud_process_timer > 0.0:
		return

	_hud_process_timer = 0.12
	_update_ability_cooldowns()
	_refresh_ability_tooltip()


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var top_timer := _create_match_bar()
	add_child(top_timer)

	_wave_timer_label = Label.new()
	_wave_timer_label.text = "Wave 1 in 30s"
	_wave_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wave_timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_wave_timer_label.add_theme_font_size_override("font_size", 16)
	_wave_timer_label.add_theme_color_override("font_color", Color(0.94, 0.88, 0.72))
	_wave_timer_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	_wave_timer_label.add_theme_constant_override("shadow_offset_x", 1)
	_wave_timer_label.add_theme_constant_override("shadow_offset_y", 1)
	_wave_timer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_timer.get_node("Content").add_child(_wave_timer_label)

	var bottom_bar := Control.new()
	bottom_bar.anchor_left = 0.0
	bottom_bar.anchor_right = 1.0
	bottom_bar.anchor_top = 1.0
	bottom_bar.anchor_bottom = 1.0
	bottom_bar.offset_left = 0.0
	bottom_bar.offset_right = 0.0
	bottom_bar.offset_top = -170.0
	bottom_bar.offset_bottom = -10.0
	bottom_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bottom_bar)
	_add_texture_backdrop(bottom_bar, HUD_BOTTOM_FRAME)

	var minimap := MinimapView.new()
	minimap.custom_minimum_size = Vector2(112.0, 112.0)
	minimap.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	minimap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bottom_bar.add_child(minimap)
	_place_control(minimap, Rect2(31.0, 27.0, 111.0, 111.0))

	var portrait_panel := _create_portrait_panel()
	bottom_bar.add_child(portrait_panel)
	_place_control(portrait_panel, Rect2(184.0, 13.0, 118.0, 136.0))

	_health_progress = _create_status_bar(Color(0.12, 0.72, 0.16), Color(0.05, 0.18, 0.05))
	bottom_bar.add_child(_health_progress)
	_place_control(_health_progress, Rect2(353.0, 47.0, 187.0, 10.0))

	_health_label = _create_hud_label("HP")
	_health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_health_label.add_theme_font_size_override("font_size", 10)
	_health_label.z_index = 30
	bottom_bar.add_child(_health_label)
	_place_control(_health_label, Rect2(353.0, 45.0, 187.0, 14.0))

	_experience_progress = _create_status_bar(Color(0.20, 0.42, 0.92), Color(0.05, 0.08, 0.18))
	bottom_bar.add_child(_experience_progress)
	_place_control(_experience_progress, Rect2(353.0, 96.0, 187.0, 10.0))

	_experience_label = _create_hud_label("Hero Lv")
	_experience_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_experience_label.add_theme_font_size_override("font_size", 10)
	_experience_label.z_index = 30
	bottom_bar.add_child(_experience_label)
	_place_control(_experience_label, Rect2(353.0, 94.0, 187.0, 14.0))

	_skill_points_label = _create_hud_label("Ability points: 0")
	_skill_points_label.z_index = 30
	bottom_bar.add_child(_skill_points_label)
	_place_control(_skill_points_label, Rect2(695.0, 116.0, 342.0, 18.0))

	_combat_stats_label = _create_hud_label("DMG")
	_utility_stats_label = _create_hud_label("SPD")
	_combat_stats_label.custom_minimum_size = Vector2(78.0, 42.0)
	_utility_stats_label.custom_minimum_size = Vector2(78.0, 42.0)
	_combat_stats_label.clip_text = false
	_utility_stats_label.clip_text = false
	_combat_stats_label.z_index = 30
	_utility_stats_label.z_index = 30
	_combat_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_utility_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bottom_bar.add_child(_combat_stats_label)
	bottom_bar.add_child(_utility_stats_label)
	_place_control(_combat_stats_label, Rect2(591.0, 31.0, 78.0, 42.0))
	_place_control(_utility_stats_label, Rect2(591.0, 88.0, 78.0, 42.0))

	for i in range(4):
		var ability_slot := _create_ability_slot(i + 1)
		bottom_bar.add_child(ability_slot)
		_place_control(ability_slot, Rect2(695.0 + float(i) * 88.0, 31.0, 78.0, 78.0))

	var shop_button := Button.new()
	shop_button.text = "0"
	shop_button.custom_minimum_size = Vector2(102.0, 40.0)
	shop_button.add_theme_stylebox_override("normal", _transparent_style())
	shop_button.add_theme_stylebox_override("hover", _transparent_style())
	shop_button.add_theme_stylebox_override("pressed", _transparent_style())
	shop_button.add_theme_font_size_override("font_size", 20)
	shop_button.add_theme_color_override("font_color", Color(1.0, 0.86, 0.30))
	shop_button.add_theme_color_override("font_hover_color", Color(1.0, 0.94, 0.48))
	shop_button.add_theme_color_override("font_pressed_color", Color(0.92, 0.72, 0.18))
	shop_button.z_index = 30
	shop_button.pressed.connect(func() -> void: shop_requested.emit())
	bottom_bar.add_child(shop_button)
	_place_control(shop_button, Rect2(1058.0, 58.0, 102.0, 40.0))
	_gold_label = shop_button

	_add_texture_overlay(bottom_bar, HUD_BOTTOM_FRAME, 20)

	_create_death_overlay()
	_create_ability_tooltip_panel()


func bind(economy: EconomySystem, experience: ExperienceSystem, hero: HeroController) -> void:
	if _economy != economy:
		_economy = economy
		if _economy != null and not _economy.gold_changed.is_connected(_on_gold_changed):
			_economy.gold_changed.connect(_on_gold_changed)

	if _experience != experience:
		_experience = experience
		if _experience != null and not _experience.experience_changed.is_connected(_on_experience_changed):
			_experience.experience_changed.connect(_on_experience_changed)

	if _hero != null and is_instance_valid(_hero) and _hero.health_changed.is_connected(_on_hero_health_changed):
		_hero.health_changed.disconnect(_on_hero_health_changed)

	_hero = hero

	if _economy != null:
		_on_gold_changed(_economy.gold)

	if _experience != null:
		_on_experience_changed(_experience.level, _experience.experience, _experience.required_experience())

	if _hero != null:
		if not _hero.health_changed.is_connected(_on_hero_health_changed):
			_hero.health_changed.connect(_on_hero_health_changed)
		_update_portrait()
		_set_ability_names(_hero.get_abilities())
		_update_ability_cooldowns()
		_update_skill_points()
		show_selected_actor(_hero)
		set_respawn_time(0.0)


func show_selected_actor(actor: Actor) -> void:
	if _selected_actor != null and is_instance_valid(_selected_actor) and _selected_actor.health_changed.is_connected(_on_selected_health_changed):
		_selected_actor.health_changed.disconnect(_on_selected_health_changed)

	_selected_actor = actor

	if _selected_actor == null or not is_instance_valid(_selected_actor):
		if _hero_label != null:
			_hero_label.text = "Selected: none"
		if _portrait_name_label != null:
			_portrait_name_label.text = _hero.get_display_name() if _hero != null and is_instance_valid(_hero) else "None"
		if _health_label != null:
			_health_label.text = "HP: -"
		if _health_progress != null:
			_health_progress.value = 0.0
		_update_selected_stats(null)
		_update_portrait()
		return

	if not _selected_actor.health_changed.is_connected(_on_selected_health_changed):
		_selected_actor.health_changed.connect(_on_selected_health_changed)

	if _hero_label != null:
		_hero_label.text = "%s: %s" % [_selected_kind(_selected_actor), _selected_name(_selected_actor)]
	if _portrait_name_label != null:
		_portrait_name_label.text = _selected_name(_selected_actor)
	_update_portrait_for_actor(_selected_actor)
	_on_selected_health_changed(_selected_actor.health, float(_selected_actor.stats.get("max_health", 0.0)))
	_update_selected_stats(_selected_actor)


func set_respawn_time(remaining: float) -> void:
	if _death_overlay != null:
		_death_overlay.visible = remaining > 0.0
	if _death_timer_label != null:
		_death_timer_label.text = "Respawn: %ds" % ceili(maxf(0.0, remaining))
	if remaining > 0.0 and _health_label != null and _selected_actor == _hero:
		_health_label.text = "HP: dead"
		if _health_progress != null:
			_health_progress.value = 0.0


func set_wave_timer(remaining: float, next_wave_number: int, has_catapult := false) -> void:
	if _wave_timer_label == null:
		return

	var wave_name := "Siege wave" if has_catapult else "Wave"
	var text := "%s %d in %ds" % [wave_name, next_wave_number, ceili(maxf(0.0, remaining))]
	if _wave_timer_label.text != text:
		_wave_timer_label.text = text


func _create_match_bar() -> Control:
	var panel := Control.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_left = -165.0
	panel.offset_right = 165.0
	panel.offset_top = 0.0
	panel.offset_bottom = 52.0
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_add_texture_backdrop(panel, HUD_TIMER_FRAME)

	var content := HBoxContainer.new()
	content.name = "Content"
	content.anchor_right = 1.0
	content.anchor_bottom = 1.0
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(content)

	return panel


func _add_texture_backdrop(parent: Control, texture: Texture2D) -> TextureRect:
	var backdrop := TextureRect.new()
	backdrop.texture = texture
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_SCALE
	parent.add_child(backdrop)
	parent.move_child(backdrop, 0)
	return backdrop


func _add_texture_overlay(parent: Control, texture: Texture2D, z_layer: int) -> TextureRect:
	var overlay := TextureRect.new()
	overlay.texture = texture
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	overlay.stretch_mode = TextureRect.STRETCH_SCALE
	overlay.z_index = z_layer
	parent.add_child(overlay)
	return overlay


func _place_control(control: Control, rect: Rect2) -> void:
	control.anchor_left = 0.0
	control.anchor_right = 0.0
	control.anchor_top = 0.0
	control.anchor_bottom = 0.0
	control.offset_left = rect.position.x
	control.offset_top = rect.position.y
	control.offset_right = rect.position.x + rect.size.x
	control.offset_bottom = rect.position.y + rect.size.y
	control.custom_minimum_size = rect.size


func _create_portrait_panel() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(118.0, 136.0)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.tooltip_text = "Hero portrait"
	panel.add_theme_stylebox_override("panel", _transparent_style())

	var content := Control.new()
	content.anchor_right = 1.0
	content.anchor_bottom = 1.0
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(content)

	_portrait_name_label = Label.new()
	_portrait_name_label.text = "Hero"
	_portrait_name_label.custom_minimum_size = Vector2(108.0, 18.0)
	_portrait_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_portrait_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_portrait_name_label.clip_text = true
	_portrait_name_label.add_theme_font_size_override("font_size", 12)
	_portrait_name_label.add_theme_color_override("font_color", Color(0.96, 0.88, 0.66))
	_portrait_name_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	_portrait_name_label.add_theme_constant_override("shadow_offset_x", 1)
	_portrait_name_label.add_theme_constant_override("shadow_offset_y", 1)
	_portrait_name_label.z_index = 30
	content.add_child(_portrait_name_label)
	_place_control(_portrait_name_label, Rect2(5.0, 3.0, 108.0, 18.0))

	_portrait_view = HeroPortraitViewScript.new() as HeroPortraitView
	_portrait_view.custom_minimum_size = Vector2(110.0, 98.0)
	_portrait_view.z_index = 0
	content.add_child(_portrait_view)
	_place_control(_portrait_view, Rect2(4.0, 29.0, 110.0, 98.0))

	return panel


func _create_hud_label(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	label.custom_minimum_size = Vector2(180.0, 20.0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.78, 0.74, 0.64))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	return label


func _create_status_bar(fill: Color, background: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(187.0, 10.0)
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.value = 1.0
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background_style := _bar_style(background, Color(0.02, 0.022, 0.018, 1.0))
	var fill_style := _bar_style(fill, fill.lightened(0.22))
	bar.add_theme_stylebox_override("background", background_style)
	bar.add_theme_stylebox_override("fill", fill_style)
	return bar


func _bar_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(0)
	style.content_margin_left = 0.0
	style.content_margin_top = 0.0
	style.content_margin_right = 0.0
	style.content_margin_bottom = 0.0
	return style


func _panel_style(background: Color, border: Color, border_width: int, corner_radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(corner_radius)
	style.content_margin_left = 6.0
	style.content_margin_top = 5.0
	style.content_margin_right = 6.0
	style.content_margin_bottom = 5.0
	return style


func _slot_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := _panel_style(background, border, 2, 1)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	style.shadow_size = 3
	return style


func _transparent_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	style.border_color = Color(0.0, 0.0, 0.0, 0.0)
	style.set_border_width_all(0)
	style.content_margin_left = 0.0
	style.content_margin_top = 0.0
	style.content_margin_right = 0.0
	style.content_margin_bottom = 0.0
	return style


func _create_ability_tooltip_panel() -> void:
	_ability_tooltip_panel = PanelContainer.new()
	_ability_tooltip_panel.anchor_left = 0.5
	_ability_tooltip_panel.anchor_right = 0.5
	_ability_tooltip_panel.anchor_top = 1.0
	_ability_tooltip_panel.anchor_bottom = 1.0
	_ability_tooltip_panel.offset_left = -120.0
	_ability_tooltip_panel.offset_right = 300.0
	_ability_tooltip_panel.offset_top = -430.0
	_ability_tooltip_panel.offset_bottom = -178.0
	_ability_tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ability_tooltip_panel.visible = false
	_ability_tooltip_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.035, 0.038, 0.038, 0.98), Color(0.62, 0.52, 0.34, 0.94), 2, 2))
	add_child(_ability_tooltip_panel)

	_ability_tooltip_label = RichTextLabel.new()
	_ability_tooltip_label.custom_minimum_size = Vector2(390.0, 226.0)
	_ability_tooltip_label.bbcode_enabled = true
	_ability_tooltip_label.fit_content = true
	_ability_tooltip_label.scroll_active = false
	_ability_tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ability_tooltip_label.add_theme_font_size_override("normal_font_size", 13)
	_ability_tooltip_label.add_theme_color_override("default_color", Color(0.84, 0.80, 0.70))
	_ability_tooltip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ability_tooltip_panel.add_child(_ability_tooltip_label)


func _create_death_overlay() -> void:
	_death_overlay = Control.new()
	_death_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_death_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_death_overlay.visible = false
	add_child(_death_overlay)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.58)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_death_overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_death_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(360.0, 118.0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(panel)

	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 8)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(content)

	var title := Label.new()
	title.text = "YOU ARE DEAD"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(1.0, 0.22, 0.18))
	title.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(title)

	_death_timer_label = Label.new()
	_death_timer_label.text = "Respawn: 0s"
	_death_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_death_timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_death_timer_label.add_theme_font_size_override("font_size", 22)
	_death_timer_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.72))
	_death_timer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(_death_timer_label)


func _create_ability_slot(number: int) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(78.0, 78.0)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.tooltip_text = "No ability"
	panel.add_theme_stylebox_override("panel", _transparent_style())
	panel.mouse_entered.connect(func() -> void: _show_ability_tooltip(number - 1))
	panel.mouse_exited.connect(func() -> void: _hide_ability_tooltip(number - 1))
	panel.gui_input.connect(func(event: InputEvent) -> void: _on_ability_slot_input(event, number - 1))
	_ability_slots.append(panel)

	var slot_root := Control.new()
	slot_root.custom_minimum_size = Vector2(78.0, 78.0)
	slot_root.anchor_right = 1.0
	slot_root.anchor_bottom = 1.0
	slot_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(slot_root)

	var icon := ColorRect.new()
	icon.custom_minimum_size = Vector2(54.0, 56.0)
	icon.color = Color(0.16 + float(number) * 0.04, 0.19, 0.27 + float(number) * 0.05)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.z_index = 0
	slot_root.add_child(icon)
	_place_control(icon, Rect2(9.0, 16.0, 54.0, 56.0))

	var key := Label.new()
	key.text = str(number)
	key.anchor_left = 0.0
	key.anchor_right = 0.0
	key.anchor_top = 0.0
	key.anchor_bottom = 0.0
	key.offset_left = 6.0
	key.offset_top = 8.0
	key.offset_right = 22.0
	key.offset_bottom = 22.0
	key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	key.mouse_filter = Control.MOUSE_FILTER_IGNORE
	key.add_theme_font_size_override("font_size", 11)
	key.add_theme_color_override("font_color", Color(0.96, 0.88, 0.66))
	key.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	key.add_theme_constant_override("shadow_offset_x", 1)
	key.add_theme_constant_override("shadow_offset_y", 1)
	key.z_index = 30
	slot_root.add_child(key)

	var name_label := Label.new()
	name_label.text = "-"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.clip_text = true
	name_label.custom_minimum_size = Vector2(58.0, 11.0)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.visible = false
	name_label.add_theme_font_size_override("font_size", 7)
	name_label.add_theme_color_override("font_color", Color(0.74, 0.70, 0.58))
	slot_root.add_child(name_label)
	_place_control(name_label, Rect2(10.0, 62.0, 58.0, 11.0))
	_ability_name_labels.append(name_label)

	var cooldown_label := Label.new()
	cooldown_label.anchor_right = 1.0
	cooldown_label.anchor_bottom = 1.0
	cooldown_label.z_index = 30
	cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cooldown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cooldown_label.add_theme_font_size_override("font_size", 24)
	cooldown_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.82))
	cooldown_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	cooldown_label.add_theme_constant_override("shadow_offset_x", 2)
	cooldown_label.add_theme_constant_override("shadow_offset_y", 2)
	cooldown_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cooldown_label.visible = false
	slot_root.add_child(cooldown_label)
	_ability_cooldown_labels.append(cooldown_label)

	var level_label := Label.new()
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	level_label.add_theme_font_size_override("font_size", 9)
	level_label.add_theme_color_override("font_color", Color(0.92, 0.86, 0.68))
	level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_label.z_index = 30
	slot_root.add_child(level_label)
	_place_control(level_label, Rect2(9.0, 61.0, 54.0, 13.0))
	_ability_level_labels.append(level_label)

	var upgrade_label := Label.new()
	upgrade_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	upgrade_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	upgrade_label.text = "+"
	upgrade_label.add_theme_font_size_override("font_size", 17)
	upgrade_label.add_theme_color_override("font_color", Color(0.82, 1.0, 0.28))
	upgrade_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	upgrade_label.add_theme_constant_override("shadow_offset_x", 1)
	upgrade_label.add_theme_constant_override("shadow_offset_y", 1)
	upgrade_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	upgrade_label.visible = false
	upgrade_label.z_index = 30
	slot_root.add_child(upgrade_label)
	_place_control(upgrade_label, Rect2(54.0, 5.0, 20.0, 20.0))
	_ability_upgrade_labels.append(upgrade_label)

	return panel


func _set_ability_names(abilities: Array) -> void:
	for i in range(_ability_name_labels.size()):
		var label := _ability_name_labels[i]
		var slot: Control = _ability_slots[i] if i < _ability_slots.size() else null
		if i < abilities.size():
			var ability: Dictionary = abilities[i]
			label.text = String(ability.get("display_name", "-"))
			if slot != null:
				slot.tooltip_text = String(ability.get("display_name", "Ability"))
		else:
			label.text = "-"
			if slot != null:
				slot.tooltip_text = "No ability"


func _update_portrait() -> void:
	if _hero == null or not is_instance_valid(_hero):
		return

	if _portrait_name_label != null:
		_portrait_name_label.text = _hero.get_display_name()
	if _portrait_view != null:
		_portrait_view.set_hero(_hero.hero_id, _hero.get_hero_color())


func _update_portrait_for_actor(actor: Actor) -> void:
	if _portrait_view == null or actor == null or not is_instance_valid(actor):
		return

	if actor is HeroController:
		var hero := actor as HeroController
		_portrait_view.set_actor_portrait("hero", hero.hero_id, hero.get_hero_color())
	elif actor is EnemyHeroAi:
		var enemy_hero := actor as EnemyHeroAi
		_portrait_view.set_actor_portrait("hero", enemy_hero.hero_id, enemy_hero.get_hero_color())
	elif actor is LaneUnit:
		_portrait_view.set_actor_portrait("lane_unit", (actor as LaneUnit).unit_id, _portrait_team_color(actor))
	elif actor is NeutralUnit:
		_portrait_view.set_actor_portrait("neutral", (actor as NeutralUnit).unit_id, _portrait_team_color(actor))
	elif actor is SummonedCompanion:
		_portrait_view.set_actor_portrait("summon", (actor as SummonedCompanion).companion_kind, _portrait_team_color(actor))
	elif actor is BaseStructure:
		_portrait_view.set_actor_portrait("structure", "shrine", _portrait_team_color(actor))
	elif actor is TowerStructure:
		var tower := actor as TowerStructure
		_portrait_view.set_actor_portrait("structure", "tower_t%d" % tower.tower_tier, _portrait_team_color(actor))
	else:
		_portrait_view.set_actor_portrait("hero", GameCatalog.DEFAULT_HERO_ID, _portrait_team_color(actor))


func _portrait_team_color(actor: Actor) -> Color:
	match actor.team:
		GameCatalog.TEAM_PLAYER:
			return Color(0.25, 0.78, 0.38)
		GameCatalog.TEAM_ENEMY:
			return Color(0.88, 0.24, 0.22)
		_:
			return Color(0.85, 0.72, 0.32)


func _update_ability_cooldowns() -> void:
	var skill_points := _hero.get_unspent_ability_points() if _hero != null and is_instance_valid(_hero) else 0
	var abilities := _hero.get_abilities() if _hero != null and is_instance_valid(_hero) else []
	_update_skill_points()

	for i in range(_ability_cooldown_labels.size()):
		var label := _ability_cooldown_labels[i]
		var slot: Control = _ability_slots[i] if i < _ability_slots.size() else null
		var level_label: Label = _ability_level_labels[i] if i < _ability_level_labels.size() else null
		var upgrade_label: Label = _ability_upgrade_labels[i] if i < _ability_upgrade_labels.size() else null
		var remaining := _hero.get_ability_cooldown(i) if _hero != null and is_instance_valid(_hero) else 0.0
		var ability_level := _hero.get_ability_level(i) if _hero != null and is_instance_valid(_hero) else 0

		label.visible = remaining > 0.0
		label.text = str(ceili(remaining)) if remaining > 0.0 else ""
		if level_label != null:
			level_label.text = "%d/%d" % [ability_level, GameCatalog.MAX_ABILITY_LEVEL]
		if upgrade_label != null:
			upgrade_label.visible = skill_points > 0 and ability_level < GameCatalog.MAX_ABILITY_LEVEL
		if slot != null:
			if ability_level <= 0:
				slot.modulate = Color(0.38, 0.38, 0.38, 1.0)
			elif remaining > 0.0:
				slot.modulate = Color(0.55, 0.55, 0.55, 1.0)
			elif skill_points > 0 and ability_level < GameCatalog.MAX_ABILITY_LEVEL:
				slot.modulate = Color(1.18, 1.12, 0.72, 1.0)
			else:
				slot.modulate = Color.WHITE
			if i < abilities.size():
				var ability: Dictionary = abilities[i]
				slot.tooltip_text = String(ability.get("display_name", "Ability"))


func _update_skill_points() -> void:
	if _skill_points_label == null:
		return

	var points := _hero.get_unspent_ability_points() if _hero != null and is_instance_valid(_hero) else 0
	_skill_points_label.text = "Ability points: %d" % points


func _on_ability_slot_input(event: InputEvent, slot: int) -> void:
	if not (event is InputEventMouseButton):
		return

	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
		return

	accept_event()
	if _hero != null and is_instance_valid(_hero) and _hero.try_upgrade_ability(slot):
		_update_ability_cooldowns()
		_refresh_ability_tooltip()


func _hero_initial(hero_id_value: String) -> String:
	var parts := hero_id_value.split("_")
	var initials := ""
	for part in parts:
		if not part.is_empty():
			initials += part.substr(0, 1).to_upper()

	return initials if not initials.is_empty() else "H"


func _show_ability_tooltip(slot: int) -> void:
	_hovered_ability_slot = slot
	_refresh_ability_tooltip()


func _hide_ability_tooltip(slot: int) -> void:
	if _hovered_ability_slot != slot:
		return

	_hovered_ability_slot = -1
	if _ability_tooltip_panel != null:
		_ability_tooltip_panel.visible = false


func _refresh_ability_tooltip() -> void:
	if _ability_tooltip_panel == null or _ability_tooltip_label == null or _hovered_ability_slot < 0:
		return
	if _hero == null or not is_instance_valid(_hero):
		_ability_tooltip_panel.visible = false
		return

	var abilities := _hero.get_abilities()
	if _hovered_ability_slot >= abilities.size():
		_ability_tooltip_panel.visible = false
		return

	var ability: Dictionary = abilities[_hovered_ability_slot]
	var ability_level := _hero.get_ability_level(_hovered_ability_slot)
	_ability_tooltip_label.text = _ability_tooltip(_hovered_ability_slot + 1, ability, ability_level)
	_ability_tooltip_panel.visible = true


func _ability_tooltip(slot_number: int, ability: Dictionary, ability_level: int = 0) -> String:
	var lines: Array[String] = []
	lines.append("[b]%d - %s[/b]" % [slot_number, String(ability.get("display_name", "Ability"))])
	lines.append("Level: %d/%d" % [ability_level, GameCatalog.MAX_ABILITY_LEVEL])
	lines.append("Status: %s" % ("Available" if ability_level > 0 else "Locked"))
	lines.append(String(ability.get("description", "")))
	lines.append("")
	lines.append("Target: %s" % _format_targeting(String(ability.get("targeting", ""))))
	lines.append("")
	for stat_key in _ability_tooltip_stat_keys(ability):
		lines.append("%s: %s" % [_ability_stat_label(stat_key), _format_ability_stat_levels(ability, stat_key, ability_level)])

	return "\n".join(lines)


func _ability_tooltip_stat_keys(ability: Dictionary) -> Array:
	var keys := []
	for stat_key in ["power", "cooldown", "range", "radius"]:
		if _should_show_ability_stat(ability, stat_key):
			keys.append(stat_key)

	for stat_key_value in GameCatalog.ability_scaled_stat_keys(ability):
		var stat_key := String(stat_key_value)
		if not keys.has(stat_key) and _should_show_ability_stat(ability, stat_key):
			keys.append(stat_key)

	return keys


func _should_show_ability_stat(ability: Dictionary, stat_key: String) -> bool:
	if stat_key == "cooldown":
		return true
	if not ability.has(stat_key):
		return false

	return not is_zero_approx(float(ability.get(stat_key, 0.0)))


func _format_ability_stat_levels(ability: Dictionary, stat_key: String, current_level: int) -> String:
	var values := GameCatalog.ability_stat_values(ability, stat_key)
	var parts: Array[String] = []
	for i in range(values.size()):
		var level := i + 1
		var text := _format_stat_value(stat_key, values[i])
		if current_level == level:
			text = "[b]%s[/b]" % text
		parts.append(text)

	return " / ".join(parts)


func _format_stat_value(stat_key: String, value: float) -> String:
	var number := _format_number(value)
	match stat_key:
		"cooldown", "duration", "taunt_duration", "freeze_duration":
			return "%ss" % number
		"speed_multiplier", "attack_damage_multiplier", "slow_multiplier", "damage_reduction_multiplier":
			return "%sx" % number
		_:
			return number


func _ability_stat_label(stat_key: String) -> String:
	match stat_key:
		"power":
			return "Damage/Power"
		"cooldown":
			return "Cooldown"
		"range":
			return "Cast range"
		"radius":
			return "Effect radius"
		"duration":
			return "Duration"
		"taunt_duration":
			return "Taunt"
		"freeze_duration":
			return "Freeze"
		"pull_distance":
			return "Pull"
		"speed_multiplier":
			return "Move speed"
		"attack_damage_multiplier":
			return "Attack damage"
		"slow_multiplier":
			return "Slow"
		"damage_reduction_multiplier":
			return "Damage taken"
		_:
			return stat_key.capitalize()


func _format_targeting(targeting: String) -> String:
	match targeting:
		"direction":
			return "Direction"
		"single_target":
			return "Single target"
		"self":
			return "Self"
		"area":
			return "Area"
		"point":
			return "Point"
		_:
			return targeting.capitalize()


func _format_number(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(roundi(value))

	return "%.1f" % value


func _on_gold_changed(gold: int) -> void:
	if _gold_label != null:
		_gold_label.text = "%d" % gold


func _on_experience_changed(level: int, experience: int, required_experience: int) -> void:
	if _experience_label != null:
		_experience_label.text = "Hero Lv %d: %d/%d" % [level, experience, required_experience]
	if _experience_progress != null:
		_experience_progress.value = clampf(float(experience) / maxf(float(required_experience), 1.0), 0.0, 1.0)


func _on_hero_health_changed(current: float, maximum: float) -> void:
	if _selected_actor == _hero and _health_label != null:
		_health_label.text = "HP: %d/%d" % [roundi(current), roundi(maximum)]
		if _health_progress != null:
			_health_progress.value = clampf(current / maxf(maximum, 1.0), 0.0, 1.0)
		_update_selected_stats(_hero)


func _on_selected_health_changed(current: float, maximum: float) -> void:
	if _hero_label != null and _selected_actor != null and is_instance_valid(_selected_actor):
		_hero_label.text = "%s: %s" % [_selected_kind(_selected_actor), _selected_name(_selected_actor)]
	if _health_label != null:
		_health_label.text = "HP: %d/%d" % [roundi(current), roundi(maximum)]
	if _health_progress != null:
		_health_progress.value = clampf(current / maxf(maximum, 1.0), 0.0, 1.0)
	_update_selected_stats(_selected_actor)


func _update_selected_stats(actor: Actor) -> void:
	if _combat_stats_label == null or _utility_stats_label == null:
		return
	if actor == null or not is_instance_valid(actor):
		_combat_stats_label.text = "DMG: -"
		_utility_stats_label.text = "SPD: -"
		return

	var attack_damage := float(actor.stats.get("attack_damage", 0.0))
	var attack_cooldown := float(actor.stats.get("attack_cooldown", 0.0))
	var attacks_per_second := 1.0 / maxf(attack_cooldown, 0.01)
	var move_speed := float(actor.stats.get("move_speed", 0.0))
	var health_regen := float(actor.stats.get("health_regen", 0.0))
	_combat_stats_label.text = "DMG %s\nAS %s" % [_format_number(attack_damage), _format_number(attacks_per_second)]
	_utility_stats_label.text = "SPD %s\nREG %s" % [_format_number(move_speed), _format_number(health_regen)]


func _selected_kind(actor: Actor) -> String:
	if actor is HeroController:
		return "Hero"
	if actor is EnemyHeroAi:
		return "Enemy hero"
	if actor is LaneUnit:
		return "Unit"
	if actor is NeutralUnit:
		return "Neutral"
	if actor is SummonedCompanion:
		return "Summon"
	if actor is TowerStructure:
		return "Tower"
	if actor is BaseStructure:
		return "Base"

	return "Selected"


func _selected_name(actor: Actor) -> String:
	if actor is HeroController:
		return (actor as HeroController).get_display_name()
	if actor is EnemyHeroAi:
		return (actor as EnemyHeroAi).get_display_name()
	if actor is LaneUnit:
		var lane_unit := actor as LaneUnit
		return "%s Lv %d" % [GameCatalog.unit_display_name(lane_unit.unit_id), lane_unit.upgrade_level]
	if actor is NeutralUnit:
		return GameCatalog.unit_display_name((actor as NeutralUnit).unit_id)
	if actor is SummonedCompanion:
		return _summon_display_name((actor as SummonedCompanion).companion_kind)
	if actor is TowerStructure:
		var tower := actor as TowerStructure
		return "%s Tower T%d" % [_team_display_name(tower.team), tower.tower_tier]
	if actor is BaseStructure:
		return "%s Shrine" % _team_display_name(actor.team)

	return actor.name


func _team_display_name(team: String) -> String:
	match team:
		GameCatalog.TEAM_PLAYER:
			return "Light"
		GameCatalog.TEAM_ENEMY:
			return "Dark"
		_:
			return team.capitalize()


func _summon_display_name(kind: String) -> String:
	match kind:
		"treant":
			return "Treant"
		"snake":
			return "Charmed Snake"
		_:
			return "Wolf Companion"
