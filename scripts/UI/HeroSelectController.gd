class_name HeroSelectController
extends Control

signal hero_chosen(hero_id: String)
signal back_requested

const HeroPortraitViewScript := preload("res://scripts/UI/HeroPortraitView.gd")


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var background := ColorRect.new()
	background.color = Color(0.09, 0.10, 0.12)
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	add_child(background)

	var margin := MarginContainer.new()
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.add_theme_constant_override("margin_left", 42)
	margin.add_theme_constant_override("margin_right", 42)
	margin.add_theme_constant_override("margin_top", 36)
	margin.add_theme_constant_override("margin_bottom", 36)
	add_child(margin)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 16)
	margin.add_child(root)

	var title := Label.new()
	title.text = "Choose Hero"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	root.add_child(title)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	root.add_child(grid)

	for hero in GameCatalog.create_hero_definitions().values():
		var button := _create_hero_button(hero)
		var hero_id := String(hero.get("id", GameCatalog.DEFAULT_HERO_ID))
		button.pressed.connect(_choose_hero.bind(hero_id))
		grid.add_child(button)

	var back_button := Button.new()
	back_button.text = "Back"
	back_button.custom_minimum_size = Vector2(160.0, 42.0)
	back_button.pressed.connect(func() -> void: back_requested.emit())
	root.add_child(back_button)


func _choose_hero(hero_id: String) -> void:
	hero_chosen.emit(hero_id)


func _create_hero_button(hero: Dictionary) -> Button:
	var button := Button.new()
	button.text = ""
	button.custom_minimum_size = Vector2(420.0, 132.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var layout := HBoxContainer.new()
	layout.anchor_right = 1.0
	layout.anchor_bottom = 1.0
	layout.offset_left = 14.0
	layout.offset_top = 12.0
	layout.offset_right = -14.0
	layout.offset_bottom = -12.0
	layout.add_theme_constant_override("separation", 14)
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(layout)

	var hero_id := String(hero.get("id", GameCatalog.DEFAULT_HERO_ID))
	var portrait := HeroPortraitViewScript.new() as HeroPortraitView
	portrait.custom_minimum_size = Vector2(94.0, 94.0)
	portrait.set_hero(hero_id, _hero_color(hero_id))
	layout.add_child(portrait)

	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.alignment = BoxContainer.ALIGNMENT_CENTER
	text_box.add_theme_constant_override("separation", 5)
	text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(text_box)

	var name_label := Label.new()
	name_label.text = String(hero.get("display_name", "Hero"))
	name_label.add_theme_font_size_override("font_size", 21)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.add_child(name_label)

	var description_label := Label.new()
	description_label.text = String(hero.get("description", ""))
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.add_theme_font_size_override("font_size", 12)
	description_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.add_child(description_label)

	var ability_label := Label.new()
	ability_label.text = _ability_line(hero.get("abilities", []))
	ability_label.clip_text = true
	ability_label.add_theme_font_size_override("font_size", 11)
	ability_label.add_theme_color_override("font_color", Color(0.86, 0.78, 0.58))
	ability_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.add_child(ability_label)

	return button


func _ability_line(abilities: Array) -> String:
	var names: Array[String] = []
	for ability in abilities:
		names.append(String(ability.get("display_name", "")))

	return "Skills: %s" % ", ".join(names)


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
