class_name InGameHudController
extends Control

signal shop_requested

const HeroPortraitViewScript := preload("res://scripts/UI/HeroPortraitView.gd")

var _gold_label: Label
var _experience_label: Label
var _health_label: Label
var _hero_label: Label
var _respawn_label: Label
var _wave_timer_label: Label
var _skill_points_label: Label
var _ability_tooltip_panel: PanelContainer
var _ability_tooltip_label: Label
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


func _process(_delta: float) -> void:
	_update_ability_cooldowns()
	_refresh_ability_tooltip()


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var top_timer := PanelContainer.new()
	top_timer.anchor_left = 0.5
	top_timer.anchor_right = 0.5
	top_timer.anchor_top = 0.0
	top_timer.anchor_bottom = 0.0
	top_timer.offset_left = -98.0
	top_timer.offset_right = 98.0
	top_timer.offset_top = 14.0
	top_timer.offset_bottom = 52.0
	top_timer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_timer)

	_wave_timer_label = Label.new()
	_wave_timer_label.text = "Wave 1 in 30s"
	_wave_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wave_timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_wave_timer_label.add_theme_font_size_override("font_size", 18)
	_wave_timer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_timer.add_child(_wave_timer_label)

	var bottom_bar := PanelContainer.new()
	bottom_bar.anchor_left = 0.0
	bottom_bar.anchor_right = 1.0
	bottom_bar.anchor_top = 1.0
	bottom_bar.anchor_bottom = 1.0
	bottom_bar.offset_left = 18.0
	bottom_bar.offset_right = -18.0
	bottom_bar.offset_top = -158.0
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

	row.add_child(_create_portrait_panel())

	var info_panel := VBoxContainer.new()
	info_panel.custom_minimum_size = Vector2(220.0, 132.0)
	info_panel.add_theme_constant_override("separation", 4)
	row.add_child(info_panel)

	_hero_label = _create_hud_label("Hero")
	_hero_label.add_theme_font_size_override("font_size", 20)
	info_panel.add_child(_hero_label)

	_health_label = _create_hud_label("HP")
	_respawn_label = _create_hud_label("")
	_gold_label = _create_hud_label("Gold")
	_experience_label = _create_hud_label("Hero Lv")
	_skill_points_label = _create_hud_label("Skill pts: 0")
	info_panel.add_child(_health_label)
	info_panel.add_child(_respawn_label)
	info_panel.add_child(_experience_label)
	info_panel.add_child(_skill_points_label)
	info_panel.add_child(_gold_label)

	var ability_offset := Control.new()
	ability_offset.custom_minimum_size = Vector2(28.0, 1.0)
	row.add_child(ability_offset)

	var ability_row := HBoxContainer.new()
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


func set_wave_timer(remaining: float, next_wave_number: int, has_catapult := false) -> void:
	if _wave_timer_label == null:
		return

	var wave_name := "Catapult wave" if has_catapult else "Wave"
	_wave_timer_label.text = "%s %d in %ds" % [wave_name, next_wave_number, ceili(maxf(0.0, remaining))]


func _create_portrait_panel() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(104.0, 104.0)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.tooltip_text = "Hero portrait"

	var stack := CenterContainer.new()
	panel.add_child(stack)

	_portrait_view = HeroPortraitViewScript.new() as HeroPortraitView
	_portrait_view.custom_minimum_size = Vector2(92.0, 92.0)
	stack.add_child(_portrait_view)

	return panel


func _create_hud_label(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	label.custom_minimum_size = Vector2(180.0, 22.0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 15)
	return label


func _create_ability_tooltip_panel() -> void:
	_ability_tooltip_panel = PanelContainer.new()
	_ability_tooltip_panel.anchor_left = 0.5
	_ability_tooltip_panel.anchor_right = 0.5
	_ability_tooltip_panel.anchor_top = 1.0
	_ability_tooltip_panel.anchor_bottom = 1.0
	_ability_tooltip_panel.offset_left = -120.0
	_ability_tooltip_panel.offset_right = 300.0
	_ability_tooltip_panel.offset_top = -328.0
	_ability_tooltip_panel.offset_bottom = -178.0
	_ability_tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ability_tooltip_panel.visible = false
	add_child(_ability_tooltip_panel)

	_ability_tooltip_label = Label.new()
	_ability_tooltip_label.custom_minimum_size = Vector2(390.0, 126.0)
	_ability_tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ability_tooltip_label.add_theme_font_size_override("font_size", 13)
	_ability_tooltip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ability_tooltip_panel.add_child(_ability_tooltip_label)


func _create_ability_slot(number: int) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(70.0, 70.0)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.tooltip_text = "No ability"
	panel.mouse_entered.connect(func() -> void: _show_ability_tooltip(number - 1))
	panel.mouse_exited.connect(func() -> void: _hide_ability_tooltip(number - 1))
	panel.gui_input.connect(func(event: InputEvent) -> void: _on_ability_slot_input(event, number - 1))
	_ability_slots.append(panel)

	var slot_root := Control.new()
	slot_root.custom_minimum_size = Vector2(70.0, 70.0)
	slot_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(slot_root)

	var box := VBoxContainer.new()
	box.anchor_right = 1.0
	box.anchor_bottom = 1.0
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_root.add_child(box)

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

	var cooldown_label := Label.new()
	cooldown_label.anchor_right = 1.0
	cooldown_label.anchor_bottom = 1.0
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
	level_label.anchor_left = 0.0
	level_label.anchor_right = 1.0
	level_label.anchor_top = 0.0
	level_label.anchor_bottom = 1.0
	level_label.offset_left = 4.0
	level_label.offset_right = -4.0
	level_label.offset_bottom = -2.0
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	level_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	level_label.add_theme_font_size_override("font_size", 10)
	level_label.add_theme_color_override("font_color", Color(0.92, 0.86, 0.68))
	level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_root.add_child(level_label)
	_ability_level_labels.append(level_label)

	var upgrade_label := Label.new()
	upgrade_label.anchor_left = 0.0
	upgrade_label.anchor_right = 1.0
	upgrade_label.anchor_top = 0.0
	upgrade_label.anchor_bottom = 1.0
	upgrade_label.offset_left = 4.0
	upgrade_label.offset_top = 2.0
	upgrade_label.offset_right = -4.0
	upgrade_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	upgrade_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	upgrade_label.text = "+"
	upgrade_label.add_theme_font_size_override("font_size", 18)
	upgrade_label.add_theme_color_override("font_color", Color(0.42, 1.0, 0.45))
	upgrade_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	upgrade_label.add_theme_constant_override("shadow_offset_x", 1)
	upgrade_label.add_theme_constant_override("shadow_offset_y", 1)
	upgrade_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	upgrade_label.visible = false
	slot_root.add_child(upgrade_label)
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
				slot.tooltip_text = _ability_tooltip(i + 1, ability, _hero.get_ability_level(i) if _hero != null and is_instance_valid(_hero) else 0)
		else:
			label.text = "-"
			if slot != null:
				slot.tooltip_text = "No ability"


func _update_portrait() -> void:
	if _hero == null or not is_instance_valid(_hero):
		return

	if _portrait_view != null:
		_portrait_view.set_hero(_hero.hero_id, _hero.get_hero_color())


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
			level_label.text = "%d/4" % ability_level
		if upgrade_label != null:
			upgrade_label.visible = skill_points > 0 and ability_level < 4
		if slot != null:
			if ability_level <= 0:
				slot.modulate = Color(0.38, 0.38, 0.38, 1.0)
			elif remaining > 0.0:
				slot.modulate = Color(0.55, 0.55, 0.55, 1.0)
			else:
				slot.modulate = Color.WHITE
			if i < abilities.size():
				var ability: Dictionary = abilities[i]
				slot.tooltip_text = _ability_tooltip(i + 1, ability, ability_level)


func _update_skill_points() -> void:
	if _skill_points_label == null:
		return

	var points := _hero.get_unspent_ability_points() if _hero != null and is_instance_valid(_hero) else 0
	_skill_points_label.text = "Skill pts: %d" % points


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
	lines.append("%d - %s" % [slot_number, String(ability.get("display_name", "Ability"))])
	lines.append("Level: %d/4" % ability_level)
	lines.append("Status: %s" % ("Available" if ability_level > 0 else "Locked"))
	lines.append(String(ability.get("description", "")))
	lines.append("")
	lines.append("Target: %s" % _format_targeting(String(ability.get("targeting", ""))))
	lines.append("Damage/Power: %s" % _format_ability_power(ability, ability_level))
	if ability_level > 0 and ability_level < 4:
		lines.append("Next level: %s" % _format_number(_ability_power_at_level(ability, ability_level + 1)))
	elif ability_level <= 0:
		lines.append("Learned value: %s" % _format_number(_ability_power_at_level(ability, 1)))
	lines.append("Cast range: %s" % _format_number(float(ability.get("range", 0.0))))
	lines.append("Effect radius: %s" % _format_number(float(ability.get("radius", 0.0))))
	lines.append("Cooldown: %ss" % _format_number(float(ability.get("cooldown", 0.0))))
	return "\n".join(lines)


func _format_ability_power(ability: Dictionary, ability_level: int) -> String:
	if ability_level <= 0:
		return "-"

	return _format_number(_ability_power_at_level(ability, ability_level))


func _ability_power_at_level(ability: Dictionary, ability_level: int) -> float:
	var base_power := float(ability.get("power", 0.0))
	return base_power * (1.0 + float(maxi(ability_level, 1) - 1) * 0.25)


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
		_experience_label.text = "Hero Lv %d: %d/%d" % [level, experience, required_experience]


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
