class_name ShopController
extends Control

var _shop: ShopSystem
var _economy: EconomySystem
var _rows: VBoxContainer
var _gold_label: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var panel := PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -360.0
	panel.offset_right = -24.0
	panel.offset_top = 68.0
	panel.offset_bottom = -160.0
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	var header := HBoxContainer.new()
	root.add_child(header)

	var title := Label.new()
	title.text = "War Camp"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 22)
	header.add_child(title)

	var close_button := Button.new()
	close_button.text = "X"
	close_button.custom_minimum_size = Vector2(34.0, 30.0)
	close_button.pressed.connect(func() -> void: toggle())
	header.add_child(close_button)

	_gold_label = Label.new()
	_gold_label.text = "Gold: 0"
	_gold_label.add_theme_font_size_override("font_size", 16)
	root.add_child(_gold_label)

	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 8)
	root.add_child(_rows)

	refresh()


func bind(shop: ShopSystem, economy: EconomySystem) -> void:
	_shop = shop
	_economy = economy

	if _economy != null:
		_economy.gold_changed.connect(_on_gold_changed)
		_on_gold_changed(_economy.gold)

	if _shop != null:
		_shop.unit_upgraded.connect(func(_unit_id: String, _level: int) -> void: refresh())

	refresh()


func toggle() -> void:
	visible = not visible
	if visible:
		refresh()


func refresh() -> void:
	if _rows == null:
		return

	for child in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()

	for definition in GameCatalog.create_shop_upgrade_definitions().values():
		if _shop != null and not _shop.is_upgrade_visible(definition):
			continue

		var unit_id := String(definition.get("id", ""))
		var level := _shop.get_upgrade_level(unit_id) if _shop != null else 0
		var cost := _shop.get_next_upgrade_cost(definition) if _shop != null else int(definition.get("upgrade_cost", 0))
		var max_level := int(definition.get("max_level", 0))
		var can_upgrade := _shop.can_upgrade(definition) if _shop != null else true
		var next_level := level + 1

		var button := Button.new()
		button.text = _upgrade_button_text(definition, level, next_level, cost, max_level, can_upgrade)
		button.custom_minimum_size = Vector2(0.0, 78.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.disabled = not can_upgrade or _economy == null or _economy.gold < cost
		button.pressed.connect(_buy_upgrade.bind(unit_id))
		_rows.add_child(button)


func _on_gold_changed(gold: int) -> void:
	if _gold_label != null:
		_gold_label.text = "Gold: %d" % gold

	refresh()


func _buy_upgrade(unit_id: String) -> void:
	if _shop != null:
		_shop.buy_unit_upgrade(unit_id)
	refresh()


func _upgrade_button_text(definition: Dictionary, level: int, next_level: int, cost: int, max_level: int, can_upgrade: bool) -> String:
	var name := String(definition.get("display_name", "Upgrade"))
	if not can_upgrade:
		return "%s  MAX %d\nFully upgraded" % [name, max_level]

	if String(definition.get("shop_upgrade_type", GameCatalog.SHOP_UPGRADE_STAT)) == GameCatalog.SHOP_UPGRADE_WAVE_COUNT:
		var current_count := _wave_count_for_level(definition, level)
		var next_count := _wave_count_for_level(definition, next_level)
		return "%s  %d -> %d  %dg\n%s" % [
			name,
			current_count,
			next_count,
			cost,
			String(definition.get("description", "")),
		]

	var next_health_bonus := roundi(float(next_level) * WaveSpawner.UPGRADE_HEALTH_BONUS_PER_LEVEL * 100.0)
	var next_damage_bonus := roundi(float(next_level) * WaveSpawner.UPGRADE_DAMAGE_BONUS_PER_LEVEL * 100.0)
	var next_speed_bonus := roundi(float(next_level) * WaveSpawner.UPGRADE_MOVE_SPEED_BONUS_PER_LEVEL * 100.0)
	var next_attack_speed_bonus := roundi(float(next_level) * WaveSpawner.UPGRADE_ATTACK_SPEED_BONUS_PER_LEVEL * 100.0)
	return "%s  Lv %d -> %d  %dg\n+%d%% HP  +%d%% DMG\n+%d%% MS  +%d%% AS" % [
		name,
		level,
		next_level,
		cost,
		next_health_bonus,
		next_damage_bonus,
		next_speed_bonus,
		next_attack_speed_bonus,
	]


func _wave_count_for_level(definition: Dictionary, level: int) -> int:
	var count := int(definition.get("base_count", 0)) + level * int(definition.get("count_per_level", 1))
	return mini(count, int(definition.get("max_count", count)))
