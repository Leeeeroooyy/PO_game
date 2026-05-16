class_name InGameHudController
extends Control

signal shop_requested

var _gold_label: Label
var _experience_label: Label
var _health_label: Label
var _hero_label: Label
var _respawn_label: Label
var _ability_slots: Array[Control] = []
var _ability_name_labels: Array[Label] = []
var _economy: EconomySystem
var _experience: ExperienceSystem
var _hero: HeroController
var _selected_actor: Actor


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bottom_bar := PanelContainer.new()
	bottom_bar.anchor_left = 0.0
	bottom_bar.anchor_right = 1.0
	bottom_bar.anchor_top = 1.0
	bottom_bar.anchor_bottom = 1.0
	bottom_bar.offset_left = 18.0
	bottom_bar.offset_right = -18.0
	bottom_bar.offset_top = -142.0
	bottom_bar.offset_bottom = -12.0
	bottom_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bottom_bar)

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 14)
	bottom_bar.add_child(row)

	var minimap := MinimapView.new()
	row.add_child(minimap)

	var info_panel := VBoxContainer.new()
	info_panel.custom_minimum_size = Vector2(240.0, 116.0)
	info_panel.add_theme_constant_override("separation", 8)
	row.add_child(info_panel)

	_hero_label = _create_hud_label("Hero")
	_hero_label.add_theme_font_size_override("font_size", 20)
	info_panel.add_child(_hero_label)

	_health_label = _create_hud_label("HP")
	_respawn_label = _create_hud_label("")
	_gold_label = _create_hud_label("Gold")
	_experience_label = _create_hud_label("Level")
	info_panel.add_child(_health_label)
	info_panel.add_child(_respawn_label)
	info_panel.add_child(_experience_label)
	info_panel.add_child(_gold_label)

	var ability_row := HBoxContainer.new()
	ability_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ability_row.alignment = BoxContainer.ALIGNMENT_CENTER
	ability_row.add_theme_constant_override("separation", 10)
	row.add_child(ability_row)

	for i in range(4):
		ability_row.add_child(_create_ability_slot(i + 1))

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	var right_panel := VBoxContainer.new()
	right_panel.custom_minimum_size = Vector2(170.0, 116.0)
	right_panel.alignment = BoxContainer.ALIGNMENT_CENTER
	right_panel.add_theme_constant_override("separation", 10)
	row.add_child(right_panel)

	var shop_button := Button.new()
	shop_button.text = "SHOP  B"
	shop_button.custom_minimum_size = Vector2(150.0, 44.0)
	shop_button.pressed.connect(func() -> void: shop_requested.emit())
	right_panel.add_child(shop_button)

	var hint := Label.new()
	hint.text = "1-4 abilities"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.modulate = Color(0.86, 0.78, 0.58)
	right_panel.add_child(hint)


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
		_set_ability_names(_hero.get_abilities())
		show_selected_actor(_hero)
		set_respawn_time(0.0)


func show_selected_actor(actor: Actor) -> void:
	if _selected_actor != null and is_instance_valid(_selected_actor) and _selected_actor.health_changed.is_connected(_on_selected_health_changed):
		_selected_actor.health_changed.disconnect(_on_selected_health_changed)

	_selected_actor = actor

	if _selected_actor == null or not is_instance_valid(_selected_actor):
		if _hero_label != null:
			_hero_label.text = "Selected: none"
		if _health_label != null:
			_health_label.text = "HP: -"
		return

	if not _selected_actor.health_changed.is_connected(_on_selected_health_changed):
		_selected_actor.health_changed.connect(_on_selected_health_changed)

	if _hero_label != null:
		_hero_label.text = "%s: %s" % [_selected_kind(_selected_actor), _selected_name(_selected_actor)]
	_on_selected_health_changed(_selected_actor.health, float(_selected_actor.stats.get("max_health", 0.0)))


func set_respawn_time(remaining: float) -> void:
	if _respawn_label == null:
		return

	if remaining > 0.0:
		_respawn_label.visible = true
		_respawn_label.text = "Respawn: %ds" % ceili(remaining)
		if _health_label != null and _selected_actor == _hero:
			_health_label.text = "HP: dead"
	else:
		_respawn_label.visible = false
		_respawn_label.text = ""


func _create_hud_label(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	label.custom_minimum_size = Vector2(180.0, 22.0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 15)
	return label


func _create_ability_slot(number: int) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(70.0, 70.0)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.tooltip_text = "No ability"
	_ability_slots.append(panel)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(box)

	var icon := ColorRect.new()
	icon.custom_minimum_size = Vector2(44.0, 36.0)
	icon.color = Color(0.22 + float(number) * 0.04, 0.24, 0.30 + float(number) * 0.05)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(icon)

	var key := Label.new()
	key.text = str(number)
	key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key.mouse_filter = Control.MOUSE_FILTER_IGNORE
	key.add_theme_font_size_override("font_size", 15)
	box.add_child(key)

	var name_label := Label.new()
	name_label.text = "-"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.clip_text = true
	name_label.custom_minimum_size = Vector2(64.0, 16.0)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.add_theme_font_size_override("font_size", 9)
	box.add_child(name_label)
	_ability_name_labels.append(name_label)

	return panel


func _set_ability_names(abilities: Array) -> void:
	for i in range(_ability_name_labels.size()):
		var label := _ability_name_labels[i]
		var slot: Control = _ability_slots[i] if i < _ability_slots.size() else null
		if i < abilities.size():
			var ability: Dictionary = abilities[i]
			label.text = String(ability.get("display_name", "-"))
			if slot != null:
				slot.tooltip_text = _ability_tooltip(i + 1, ability)
		else:
			label.text = "-"
			if slot != null:
				slot.tooltip_text = "No ability"


func _ability_tooltip(slot_number: int, ability: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("%d - %s" % [slot_number, String(ability.get("display_name", "Ability"))])
	lines.append(String(ability.get("description", "")))
	lines.append("")
	lines.append("Target: %s" % _format_targeting(String(ability.get("targeting", ""))))
	lines.append("Damage/Power: %s" % _format_number(float(ability.get("power", 0.0))))
	lines.append("Cast range: %s" % _format_number(float(ability.get("range", 0.0))))
	lines.append("Effect radius: %s" % _format_number(float(ability.get("radius", 0.0))))
	lines.append("Cooldown: %ss" % _format_number(float(ability.get("cooldown", 0.0))))
	return "\n".join(lines)


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
		_gold_label.text = "Gold: %d" % gold


func _on_experience_changed(level: int, experience: int, required_experience: int) -> void:
	if _experience_label != null:
		_experience_label.text = "Lv %d: %d/%d" % [level, experience, required_experience]


func _on_hero_health_changed(current: float, maximum: float) -> void:
	if _selected_actor == _hero and _health_label != null:
		_health_label.text = "HP: %d/%d" % [roundi(current), roundi(maximum)]


func _on_selected_health_changed(current: float, maximum: float) -> void:
	if _health_label != null:
		_health_label.text = "HP: %d/%d" % [roundi(current), roundi(maximum)]


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
		return (actor as HeroController).hero_id
	if actor is LaneUnit:
		return (actor as LaneUnit).unit_id
	if actor is NeutralUnit:
		return (actor as NeutralUnit).unit_id
	if actor is SummonedCompanion:
		return (actor as SummonedCompanion).companion_kind
	if actor is TowerStructure:
		var tower := actor as TowerStructure
		return "%s T%d" % [tower.team, tower.tower_tier]
	if actor is BaseStructure:
		return actor.team

	return actor.name
