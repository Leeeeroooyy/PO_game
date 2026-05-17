class_name NeutralCampSpawner
extends Node

signal unit_spawned(actor: Actor)

var _actor_parent: Node2D
var _neutral_unit_scene: PackedScene
var _camps: Array[Dictionary] = []

const CAMP_UNIT_OFFSETS := [
	Vector2(-30.0, -18.0),
	Vector2(30.0, -18.0),
	Vector2(0.0, 30.0),
]


func configure(actor_parent: Node2D, neutral_unit_scene: PackedScene) -> void:
	_actor_parent = actor_parent
	_neutral_unit_scene = neutral_unit_scene


func spawn_initial_camps() -> void:
	if _actor_parent == null or _neutral_unit_scene == null:
		return

	_camps.clear()
	_register_camp(Vector2(1000.0, -220.0), ["neutral_bruiser", "neutral_spitter"])
	_register_camp(Vector2(650.0, 220.0), ["neutral_thrower", "neutral_bruiser"])
	_register_camp(Vector2(1030.0, 650.0), ["neutral_claw", "neutral_spitter"])
	_register_camp(Vector2(500.0, 1000.0), ["neutral_bruiser", "neutral_thrower", "neutral_spitter"])
	_register_camp(Vector2(-580.0, 1010.0), ["neutral_claw", "neutral_bruiser"])
	_register_camp(Vector2(-205.0, 785.0), ["neutral_spitter", "neutral_thrower"])
	_register_camp(Vector2(170.0, 470.0), ["neutral_bruiser", "neutral_thrower"])
	_register_camp(Vector2(675.0, 505.0), ["neutral_claw", "neutral_spitter"])

	_register_camp(Vector2(-1000.0, 220.0), ["neutral_bruiser", "neutral_spitter"])
	_register_camp(Vector2(-650.0, -220.0), ["neutral_thrower", "neutral_bruiser"])
	_register_camp(Vector2(-1030.0, -650.0), ["neutral_claw", "neutral_spitter"])
	_register_camp(Vector2(-500.0, -1000.0), ["neutral_bruiser", "neutral_thrower", "neutral_spitter"])
	_register_camp(Vector2(580.0, -1010.0), ["neutral_claw", "neutral_bruiser"])
	_register_camp(Vector2(205.0, -785.0), ["neutral_spitter", "neutral_thrower"])
	_register_camp(Vector2(-170.0, -470.0), ["neutral_bruiser", "neutral_thrower"])
	_register_camp(Vector2(-675.0, -505.0), ["neutral_claw", "neutral_spitter"])

	for i in range(_camps.size()):
		_spawn_camp(i)


func respawn_empty_camps() -> void:
	if _actor_parent == null or _neutral_unit_scene == null:
		return

	for i in range(_camps.size()):
		if _is_camp_empty(_camps[i]):
			_spawn_camp(i)


func _register_camp(center: Vector2, unit_ids: Array[String]) -> void:
	_camps.append({
		"center": center,
		"unit_ids": unit_ids.duplicate(),
		"units": [],
	})


func _spawn_camp(camp_index: int) -> void:
	var camp := _camps[camp_index]
	var center: Vector2 = camp.get("center", Vector2.ZERO)
	var unit_ids: Array = camp.get("unit_ids", [])
	var units: Array[NeutralUnit] = []

	for i in range(unit_ids.size()):
		var unit := _spawn_neutral(String(unit_ids[i]), center + CAMP_UNIT_OFFSETS[i % CAMP_UNIT_OFFSETS.size()])
		if unit != null:
			units.append(unit)

	camp["units"] = units
	_camps[camp_index] = camp


func _spawn_neutral(unit_id: String, position: Vector2) -> NeutralUnit:
	var definitions := GameCatalog.create_unit_definitions()
	if not definitions.has(unit_id):
		return null

	var definition: Dictionary = definitions[unit_id]
	var unit := _neutral_unit_scene.instantiate() as NeutralUnit
	_actor_parent.add_child(unit)
	unit.configure_neutral(unit_id, position, definition.get("stats", {}).duplicate(true))
	unit_spawned.emit(unit)
	return unit


func _is_camp_empty(camp: Dictionary) -> bool:
	var units: Array = camp.get("units", [])
	for unit in units:
		if not is_instance_valid(unit):
			continue

		var actor := unit as NeutralUnit
		if actor != null and actor.is_alive():
			return false

	return true
