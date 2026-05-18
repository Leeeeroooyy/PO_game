class_name WaveSpawner
extends Node

signal wave_started(wave_number: int)
signal unit_spawned(actor: Actor)

@export var spawn_interval := 30.0

const LANES := [
	GameCatalog.LANE_TOP,
	GameCatalog.LANE_MIDDLE,
	GameCatalog.LANE_BOTTOM,
]
const LANE_WAVE_COMPOSITION := [
	"line_melee",
	"line_melee",
	"line_melee",
	"line_mage",
]
const CATAPULT_WAVE_INTERVAL := 3
const UPGRADE_HEALTH_BONUS_PER_LEVEL := 0.22
const UPGRADE_DAMAGE_BONUS_PER_LEVEL := 0.18
const UPGRADE_MOVE_SPEED_BONUS_PER_LEVEL := 0.02
const UPGRADE_ATTACK_SPEED_BONUS_PER_LEVEL := 0.04

var _upgrade_levels := {}
var _actor_parent: Node2D
var _lane_unit_scene: PackedScene
var _lane_manager: LaneManager
var _timer := 0.0
var _wave_number := 0
var _running := false
var _unit_definitions := {}


func _process(delta: float) -> void:
	if not _running or _actor_parent == null or _lane_unit_scene == null or _lane_manager == null:
		return

	_timer -= delta
	if _timer <= 0.0:
		_spawn_wave()
		_timer = spawn_interval


func configure(actor_parent: Node2D, lane_unit_scene: PackedScene, lane_manager: LaneManager) -> void:
	_actor_parent = actor_parent
	_lane_unit_scene = lane_unit_scene
	_lane_manager = lane_manager


func start_spawning() -> void:
	_running = true
	_timer = spawn_interval


func stop_spawning() -> void:
	_running = false


func get_time_until_next_wave() -> float:
	return maxf(0.0, _timer) if _running else 0.0


func get_next_wave_number() -> int:
	return _wave_number + 1


func get_next_wave_has_catapult() -> bool:
	return is_catapult_wave(get_next_wave_number())


func is_catapult_wave(wave_number: int) -> bool:
	return wave_number > 0 and wave_number % CATAPULT_WAVE_INTERVAL == 0


func set_unit_upgrade_level(unit_id: String, level: int) -> void:
	_upgrade_levels[unit_id] = level


func get_unit_upgrade_level(unit_id: String) -> int:
	return int(_upgrade_levels.get(unit_id, 0))


func create_upgraded_stats(unit_id: String, team: String = GameCatalog.TEAM_PLAYER) -> Dictionary:
	var definitions := _get_unit_definitions()
	if not definitions.has(unit_id):
		return {}

	var definition: Dictionary = definitions[unit_id]
	return _create_scaled_stats(definition, _get_effective_upgrade_level(unit_id, team))


func _spawn_wave() -> void:
	_wave_number += 1
	wave_started.emit(_wave_number)

	var composition: Array = LANE_WAVE_COMPOSITION.duplicate()
	if is_catapult_wave(_wave_number):
		composition.append("line_siege")

	for lane in LANES:
		for formation_slot in range(composition.size()):
			_spawn_lane_pair(String(composition[formation_slot]), String(lane), formation_slot)


func _spawn_lane_pair(unit_id: String, lane: String, formation_slot: int) -> void:
	_spawn_unit(unit_id, GameCatalog.TEAM_PLAYER, lane, formation_slot)
	_spawn_unit(unit_id, GameCatalog.TEAM_ENEMY, lane, formation_slot)


func _spawn_unit(unit_id: String, team: String, lane: String, formation_slot: int) -> void:
	var definitions := _get_unit_definitions()
	if not definitions.has(unit_id):
		return

	var definition: Dictionary = definitions[unit_id]
	var upgrade_level := _get_effective_upgrade_level(unit_id, team)
	var unit := _lane_unit_scene.instantiate() as LaneUnit
	_actor_parent.add_child(unit)
	var path := _lane_manager.get_lane_path(team, lane)
	if path.size() > 1:
		path = _build_formation_path(path, formation_slot)

	unit.configure_lane_unit(
		unit_id,
		team,
		lane,
		path,
		_create_scaled_stats(definition, upgrade_level),
		upgrade_level
	)
	unit_spawned.emit(unit)


func _build_formation_path(path: PackedVector2Array, formation_slot: int) -> PackedVector2Array:
	var formation_path := PackedVector2Array()
	var lateral_amount := _formation_lateral_amount(formation_slot)
	var row_spacing := _formation_row_spacing(formation_slot)
	var first_segment_length := path[0].distance_to(path[1])
	var launch_distance := minf(_lane_manager.spawn_offset_from_base, maxf(0.0, first_segment_length - 24.0))

	for i in range(path.size()):
		var direction := _path_direction_at(path, i)
		var point := path[i]
		if i == 0:
			point = point.move_toward(path[1], launch_distance) - direction * row_spacing

		point += direction.orthogonal() * lateral_amount
		formation_path.append(point)

	return formation_path


func _path_direction_at(path: PackedVector2Array, index: int) -> Vector2:
	if path.size() < 2:
		return Vector2.RIGHT
	if index <= 0:
		return path[0].direction_to(path[1])
	if index >= path.size() - 1:
		return path[path.size() - 2].direction_to(path[path.size() - 1])

	var direction := path[index - 1].direction_to(path[index + 1])
	return direction if direction != Vector2.ZERO else path[index].direction_to(path[index + 1])


func _formation_lateral_amount(formation_slot: int) -> float:
	match formation_slot:
		0:
			return -24.0
		1:
			return 0.0
		2:
			return 24.0
		_:
			return 0.0


func _formation_row_spacing(formation_slot: int) -> float:
	match formation_slot:
		3:
			return 48.0
		4:
			return 92.0
		_:
			return 0.0


func _create_scaled_stats(definition: Dictionary, level: int) -> Dictionary:
	var unit_stats: Dictionary = definition.get("stats", {}).duplicate(true)
	var clamped_level := maxi(0, level)
	var level_value := float(clamped_level)
	var health_multiplier := 1.0 + level_value * UPGRADE_HEALTH_BONUS_PER_LEVEL
	var damage_multiplier := 1.0 + level_value * UPGRADE_DAMAGE_BONUS_PER_LEVEL
	var move_multiplier := 1.0 + level_value * UPGRADE_MOVE_SPEED_BONUS_PER_LEVEL
	var cooldown_multiplier := maxf(0.68, 1.0 - level_value * UPGRADE_ATTACK_SPEED_BONUS_PER_LEVEL)
	unit_stats["max_health"] = float(unit_stats.get("max_health", 1.0)) * health_multiplier
	unit_stats["attack_damage"] = float(unit_stats.get("attack_damage", 1.0)) * damage_multiplier
	unit_stats["move_speed"] = float(unit_stats.get("move_speed", 1.0)) * move_multiplier
	unit_stats["attack_cooldown"] = float(unit_stats.get("attack_cooldown", 1.0)) * cooldown_multiplier
	return unit_stats


func _get_unit_definitions() -> Dictionary:
	if _unit_definitions.is_empty():
		_unit_definitions = GameCatalog.create_unit_definitions()

	return _unit_definitions


func _get_effective_upgrade_level(unit_id: String, team: String) -> int:
	if team != GameCatalog.TEAM_PLAYER:
		return 0

	return get_unit_upgrade_level(unit_id)
