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

var _upgrade_levels := {}
var _actor_parent: Node2D
var _lane_unit_scene: PackedScene
var _lane_manager: LaneManager
var _timer := 0.0
var _wave_number := 0
var _running := false


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


func set_unit_upgrade_level(unit_id: String, level: int) -> void:
	_upgrade_levels[unit_id] = level


func _spawn_wave() -> void:
	_wave_number += 1
	wave_started.emit(_wave_number)

	for lane in LANES:
		for formation_slot in range(LANE_WAVE_COMPOSITION.size()):
			_spawn_lane_pair(String(LANE_WAVE_COMPOSITION[formation_slot]), String(lane), formation_slot)


func _spawn_lane_pair(unit_id: String, lane: String, formation_slot: int) -> void:
	_spawn_unit(unit_id, GameCatalog.TEAM_PLAYER, lane, formation_slot)
	_spawn_unit(unit_id, GameCatalog.TEAM_ENEMY, lane, formation_slot)


func _spawn_unit(unit_id: String, team: String, lane: String, formation_slot: int) -> void:
	var definitions := GameCatalog.create_unit_definitions()
	if not definitions.has(unit_id):
		return

	var definition: Dictionary = definitions[unit_id]
	var unit := _lane_unit_scene.instantiate() as LaneUnit
	_actor_parent.add_child(unit)
	var path := _lane_manager.get_lane_path(team, lane)
	if path.size() > 1:
		var lane_direction := path[0].direction_to(path[1])
		path[0] = path[0].move_toward(path[1], _lane_manager.spawn_offset_from_base)
		path[0] += _formation_offset(lane_direction, formation_slot)

	unit.configure_lane_unit(
		unit_id,
		team,
		lane,
		path,
		_create_scaled_stats(definition)
	)
	unit_spawned.emit(unit)


func _formation_offset(lane_direction: Vector2, formation_slot: int) -> Vector2:
	if lane_direction == Vector2.ZERO:
		return Vector2.ZERO

	var lateral := lane_direction.orthogonal()
	match formation_slot:
		0:
			return lateral * -18.0
		1:
			return lateral * 18.0
		2:
			return lane_direction * -24.0
		_:
			return Vector2.ZERO


func _create_scaled_stats(definition: Dictionary) -> Dictionary:
	var unit_stats: Dictionary = definition.get("stats", {}).duplicate(true)
	var level := int(_upgrade_levels.get(String(definition.get("id", "")), 0))
	var multiplier := 1.0 + float(level) * 0.15
	unit_stats["max_health"] = float(unit_stats.get("max_health", 1.0)) * multiplier
	unit_stats["attack_damage"] = float(unit_stats.get("attack_damage", 1.0)) * multiplier
	return unit_stats
