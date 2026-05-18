class_name ShopSystem
extends Node

signal unit_upgraded(unit_id: String, level: int)

var _upgrade_levels := {}
var _economy: EconomySystem


func bind(economy: EconomySystem) -> void:
	_economy = economy


func get_upgrade_level(unit_id: String) -> int:
	return int(_upgrade_levels.get(unit_id, 0))


func get_next_upgrade_cost(definition: Dictionary) -> int:
	var next_level := get_upgrade_level(String(definition.get("id", ""))) + 1
	return int(definition.get("upgrade_cost", 0)) * next_level


func can_upgrade(definition: Dictionary) -> bool:
	var max_level := int(definition.get("max_level", 0))
	return max_level <= 0 or get_upgrade_level(String(definition.get("id", ""))) < max_level


func is_upgrade_visible(definition: Dictionary) -> bool:
	var required_upgrade_id := String(definition.get("required_upgrade_id", ""))
	if required_upgrade_id.is_empty():
		return true

	var required_level := int(definition.get("required_upgrade_level", 1))
	return get_upgrade_level(required_upgrade_id) >= required_level


func buy_unit_upgrade(unit_id: String) -> bool:
	var definitions := GameCatalog.create_shop_upgrade_definitions()
	if not definitions.has(unit_id):
		return false

	var definition: Dictionary = definitions[unit_id]
	if not is_upgrade_visible(definition):
		return false
	if not can_upgrade(definition):
		return false

	var cost := get_next_upgrade_cost(definition)
	if _economy == null or not _economy.try_spend(cost):
		return false

	var level := get_upgrade_level(unit_id) + 1
	_upgrade_levels[unit_id] = level
	unit_upgraded.emit(unit_id, level)
	return true
