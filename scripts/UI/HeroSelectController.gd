class_name HeroSelectController
extends Control

signal hero_chosen(hero_id: String)
signal back_requested

const HeroPortraitViewScript := preload("res://scripts/UI/HeroPortraitView.gd")
const MenuBackdropScript := preload("res://scripts/UI/MenuBackdrop.gd")

const CARD_SIZE := Vector2(250.0, 330.0)
const CARD_SPACING := 210.0

var _heroes: Array[Dictionary] = []
var _selected_index := 0
var _carousel_layer: Control
var _card_nodes: Array[Button] = []
var _name_label: Label
var _description_label: Label
var _stats_label: RichTextLabel
var _abilities_label: RichTextLabel
var _select_button: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_load_heroes()
	_build_layout()
	_update_selection(false)
	call_deferred("_layout_cards", false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _carousel_layer != null:
		_layout_cards(false)


func _load_heroes() -> void:
	_heroes.clear()
	for hero in GameCatalog.create_hero_definitions().values():
		var hero_definition: Dictionary = hero
		_heroes.append(hero_definition)


func _build_layout() -> void:
	var backdrop := MenuBackdropScript.new() as MenuBackdrop
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.accent_color = Color(0.48, 0.74, 0.52)
	add_child(backdrop)

	var veil := ColorRect.new()
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.color = Color(0.0, 0.0, 0.0, 0.26)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	add_child(margin)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 18)
	margin.add_child(root)

	root.add_child(_create_header())

	var body := HBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 22)
	root.add_child(body)

	body.add_child(_create_carousel_panel())
	body.add_child(_create_details_panel())


func _create_header() -> Control:
	var header := HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_theme_constant_override("separation", 14)

	var back_button := _small_button("Back")
	back_button.pressed.connect(func() -> void: back_requested.emit())
	header.add_child(back_button)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_box)

	var title := Label.new()
	title.text = "Choose Hero"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(0.97, 0.91, 0.74))
	title.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.78))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	title_box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Browse the roster, compare stats and inspect every skill before the match."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.72, 0.80, 0.74))
	title_box.add_child(subtitle)

	_select_button = _small_button("Start")
	_select_button.pressed.connect(_confirm_selected_hero)
	header.add_child(_select_button)

	return header


func _create_carousel_panel() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560.0, 0.0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.045, 0.056, 0.054, 0.88), Color(0.50, 0.68, 0.48, 0.40)))

	var stack := Control.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(stack)

	_carousel_layer = Control.new()
	_carousel_layer.anchor_right = 1.0
	_carousel_layer.anchor_bottom = 1.0
	_carousel_layer.offset_left = 70.0
	_carousel_layer.offset_right = -70.0
	_carousel_layer.offset_top = 18.0
	_carousel_layer.offset_bottom = -18.0
	stack.add_child(_carousel_layer)

	var left_button := _arrow_button("<")
	left_button.anchor_left = 0.0
	left_button.anchor_right = 0.0
	left_button.anchor_top = 0.5
	left_button.anchor_bottom = 0.5
	left_button.offset_left = 18.0
	left_button.offset_right = 62.0
	left_button.offset_top = -26.0
	left_button.offset_bottom = 26.0
	left_button.pressed.connect(func() -> void: _move_selection(-1))
	stack.add_child(left_button)

	var right_button := _arrow_button(">")
	right_button.anchor_left = 1.0
	right_button.anchor_right = 1.0
	right_button.anchor_top = 0.5
	right_button.anchor_bottom = 0.5
	right_button.offset_left = -62.0
	right_button.offset_right = -18.0
	right_button.offset_top = -26.0
	right_button.offset_bottom = 26.0
	right_button.pressed.connect(func() -> void: _move_selection(1))
	stack.add_child(right_button)

	for i in range(_heroes.size()):
		var card: Button = _create_hero_card(_heroes[i], i)
		_card_nodes.append(card)
		_carousel_layer.add_child(card)

	return panel


func _create_details_panel() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(460.0, 0.0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.045, 0.050, 0.055, 0.92), Color(0.78, 0.58, 0.30, 0.42)))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 30)
	_name_label.add_theme_color_override("font_color", Color(0.98, 0.90, 0.68))
	root.add_child(_name_label)

	_description_label = Label.new()
	_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description_label.add_theme_font_size_override("font_size", 14)
	_description_label.add_theme_color_override("font_color", Color(0.74, 0.80, 0.74))
	root.add_child(_description_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	var scroll_content := VBoxContainer.new()
	scroll_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_content.add_theme_constant_override("separation", 12)
	scroll.add_child(scroll_content)

	_stats_label = _details_text()
	scroll_content.add_child(_section("Base Stats", _stats_label))

	_abilities_label = _details_text()
	scroll_content.add_child(_section("Skills", _abilities_label))

	return panel


func _create_hero_card(hero: Dictionary, index: int) -> Button:
	var hero_id := String(hero.get("id", GameCatalog.DEFAULT_HERO_ID))
	var card := Button.new()
	card.text = ""
	card.custom_minimum_size = CARD_SIZE
	card.size = CARD_SIZE
	card.pivot_offset = CARD_SIZE * 0.5
	card.add_theme_stylebox_override("normal", _card_style(Color(0.065, 0.080, 0.074, 0.96), _hero_color(hero_id).darkened(0.22)))
	card.add_theme_stylebox_override("hover", _card_style(Color(0.095, 0.115, 0.104, 0.98), _hero_color(hero_id).lightened(0.18)))
	card.add_theme_stylebox_override("pressed", _card_style(Color(0.045, 0.052, 0.050, 0.98), _hero_color(hero_id)))
	card.pressed.connect(_select_card.bind(index))

	var margin := MarginContainer.new()
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(margin)

	var layout := VBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 10)
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(layout)

	var portrait := HeroPortraitViewScript.new() as HeroPortraitView
	portrait.custom_minimum_size = Vector2(156.0, 156.0)
	portrait.set_hero(hero_id, _hero_color(hero_id))
	layout.add_child(portrait)

	var name_label := Label.new()
	name_label.text = String(hero.get("display_name", "Hero"))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", Color(0.98, 0.91, 0.70))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(name_label)

	var role_label := Label.new()
	role_label.text = _hero_role(hero_id)
	role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	role_label.add_theme_font_size_override("font_size", 13)
	role_label.add_theme_color_override("font_color", Color(0.72, 0.82, 0.72))
	role_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(role_label)

	return card


func _move_selection(direction: int) -> void:
	if _heroes.is_empty():
		return

	_selected_index = wrapi(_selected_index + direction, 0, _heroes.size())
	_update_selection(true)


func _select_card(index: int) -> void:
	if index == _selected_index:
		_confirm_selected_hero()
		return

	_selected_index = clampi(index, 0, _heroes.size() - 1)
	_update_selection(true)


func _confirm_selected_hero() -> void:
	if _heroes.is_empty():
		return

	hero_chosen.emit(String(_heroes[_selected_index].get("id", GameCatalog.DEFAULT_HERO_ID)))


func _update_selection(animate: bool) -> void:
	if _heroes.is_empty():
		return

	var hero: Dictionary = _heroes[_selected_index]
	_name_label.text = String(hero.get("display_name", "Hero"))
	_description_label.text = String(hero.get("description", ""))
	_stats_label.text = _stats_text(hero)
	_abilities_label.text = _abilities_text(hero)
	if _select_button != null:
		_select_button.text = "Start: %s" % String(hero.get("display_name", "Hero"))

	_layout_cards(animate)


func _layout_cards(animate: bool) -> void:
	if _carousel_layer == null or _card_nodes.is_empty():
		return

	var center: Vector2 = _carousel_layer.size * 0.5
	for i in range(_card_nodes.size()):
		var card: Button = _card_nodes[i]
		var rel: int = _relative_index(i)
		var abs_rel: int = absi(rel)
		card.visible = abs_rel <= 2
		card.disabled = abs_rel > 2
		if not card.visible:
			continue

		var target_position: Vector2 = center - CARD_SIZE * 0.5 + Vector2(float(rel) * CARD_SPACING, 0.0)
		var target_scale: Vector2 = Vector2.ONE * (1.0 if rel == 0 else (0.82 if abs_rel == 1 else 0.66))
		var alpha: float = 1.0 if rel == 0 else (0.72 if abs_rel == 1 else 0.24)
		card.z_index = 10 - abs_rel

		if animate:
			var tween: Tween = create_tween()
			tween.set_parallel(true)
			tween.tween_property(card, "position", target_position, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tween.tween_property(card, "scale", target_scale, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tween.tween_property(card, "modulate", Color(1.0, 1.0, 1.0, alpha), 0.18)
		else:
			card.position = target_position
			card.scale = target_scale
			card.modulate = Color(1.0, 1.0, 1.0, alpha)


func _relative_index(index: int) -> int:
	var count: int = _heroes.size()
	var rel: int = index - _selected_index
	if rel > count / 2:
		rel -= count
	elif rel < -count / 2:
		rel += count

	return rel


func _stats_text(hero: Dictionary) -> String:
	var stats: Dictionary = hero.get("stats", {})
	var attack_cooldown: float = float(stats.get("attack_cooldown", 1.0))
	var attacks_per_second: float = 1.0 / maxf(attack_cooldown, 0.01)
	var lines: Array[String] = []
	lines.append("[b]Health[/b]: %s" % _format_number(float(stats.get("max_health", 0.0))))
	lines.append("[b]Damage[/b]: %s" % _format_number(float(stats.get("attack_damage", 0.0))))
	lines.append("[b]Attack speed[/b]: %s/s" % _format_number(attacks_per_second))
	lines.append("[b]Attack range[/b]: %s" % _format_number(float(stats.get("attack_range", 0.0))))
	lines.append("[b]Move speed[/b]: %s" % _format_number(float(stats.get("move_speed", 0.0))))
	lines.append("[b]HP regen[/b]: %s/s" % _format_number(float(stats.get("health_regen", 0.0))))
	return "\n".join(lines)


func _abilities_text(hero: Dictionary) -> String:
	var lines: Array[String] = []
	for ability_value in hero.get("abilities", []):
		var ability: Dictionary = ability_value
		lines.append("[b]%s[/b]" % String(ability.get("display_name", "Skill")))
		lines.append(String(ability.get("description", "")))
		lines.append("Target: %s" % _format_targeting(String(ability.get("targeting", ""))))
		lines.append("Values: Lv1 / Lv2 / Lv3 / Lv4")
		for stat_key in _ability_stat_keys(ability):
			lines.append("%s: %s" % [_ability_stat_label(stat_key), _format_ability_levels(ability, stat_key)])
		lines.append("")

	return "\n".join(lines).strip_edges()


func _ability_stat_keys(ability: Dictionary) -> Array[String]:
	var keys: Array[String] = []
	for stat_key in ["power", "cooldown", "range", "radius"]:
		if _should_show_ability_stat(ability, stat_key):
			keys.append(stat_key)

	for stat_key_value in GameCatalog.ability_scaled_stat_keys(ability):
		var stat_key: String = String(stat_key_value)
		if not keys.has(stat_key) and _should_show_ability_stat(ability, stat_key):
			keys.append(stat_key)

	return keys


func _should_show_ability_stat(ability: Dictionary, stat_key: String) -> bool:
	if stat_key == "cooldown":
		return true
	if not ability.has(stat_key):
		return false

	return not is_zero_approx(float(ability.get(stat_key, 0.0)))


func _format_ability_levels(ability: Dictionary, stat_key: String) -> String:
	var values: Array = GameCatalog.ability_stat_values(ability, stat_key)
	var parts: Array[String] = []
	for value in values:
		parts.append(_format_stat_value(stat_key, float(value)))

	return " / ".join(parts)


func _format_stat_value(stat_key: String, value: float) -> String:
	var number: String = _format_number(value)
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


func _details_text() -> RichTextLabel:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("normal_font_size", 13)
	label.add_theme_color_override("default_color", Color(0.84, 0.88, 0.82))
	return label


func _section(title: String, content: Control) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.035, 0.041, 0.042, 0.76), Color(0.36, 0.46, 0.36, 0.34)))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	var header := Label.new()
	header.text = title
	header.add_theme_font_size_override("font_size", 17)
	header.add_theme_color_override("font_color", Color(0.94, 0.80, 0.54))
	box.add_child(header)

	box.add_child(content)
	return panel


func _small_button(text_value: String) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(132.0, 42.0)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_stylebox_override("normal", _button_style(Color(0.12, 0.15, 0.14), Color(0.52, 0.60, 0.44)))
	button.add_theme_stylebox_override("hover", _button_style(Color(0.18, 0.22, 0.19), Color(0.92, 0.72, 0.36)))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.08, 0.10, 0.095), Color(0.92, 0.72, 0.36)))
	return button


func _arrow_button(text_value: String) -> Button:
	var button: Button = _small_button(text_value)
	button.custom_minimum_size = Vector2(44.0, 52.0)
	button.add_theme_font_size_override("font_size", 24)
	return button


func _panel_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _button_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = _panel_style(bg, border)
	style.set_border_width_all(2)
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _card_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = _panel_style(bg, border)
	style.set_border_width_all(2)
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style


func _hero_role(hero_id: String) -> String:
	match hero_id:
		"bard_frog":
			return "Support / Control"
		"axe_barbarian":
			return "Melee / Durable"
		"sorcerer":
			return "Caster / Area"
		"ancient_druid":
			return "Summoner / Control"
		_:
			return "Ranged / Mobile"


func _hero_color(hero_id: String) -> Color:
	match hero_id:
		"bard_frog":
			return Color(0.35, 0.78, 0.92)
		"axe_barbarian":
			return Color(0.90, 0.38, 0.22)
		"sorcerer":
			return Color(0.65, 0.45, 1.0)
		"ancient_druid":
			return Color(0.28, 0.66, 0.26)
		_:
			return Color(0.34, 0.78, 0.36)
