class_name LaneManager
extends Node2D

@export var player_base_position := Vector2(-1245.0, 1255.0)
@export var enemy_base_position := Vector2(1245.0, -1255.0)
@export var spawn_offset_from_base := 140.0

const BASE_WALL_THICKNESS := 34.0


func _ready() -> void:
	z_index = -120
	queue_redraw()


func get_base_position(team: String) -> Vector2:
	return player_base_position if team == GameCatalog.TEAM_PLAYER else enemy_base_position


func get_hero_spawn(team: String) -> Vector2:
	var base_position := get_base_position(team)
	return base_position + Vector2(145.0, -95.0) if team == GameCatalog.TEAM_PLAYER else base_position + Vector2(-145.0, 95.0)


func get_spawn_position(team: String, lane: String) -> Vector2:
	var path := get_lane_path(team, lane)
	if path.size() < 2:
		return get_base_position(team)

	return path[0].move_toward(path[1], spawn_offset_from_base)


func get_lane_target(team: String, lane: String) -> Vector2:
	var path := get_lane_path(team, lane)
	return path[path.size() - 1] if path.size() > 0 else get_base_position(GameCatalog.TEAM_ENEMY)


func get_lane_path(team: String, lane: String) -> PackedVector2Array:
	var path := _get_player_lane_path(lane)
	if team == GameCatalog.TEAM_ENEMY:
		var reversed := PackedVector2Array()
		for i in range(path.size() - 1, -1, -1):
			reversed.append(path[i])
		return reversed

	return path


func get_lane_tower_layout(team: String) -> Array[Dictionary]:
	var player_layout := _get_player_tower_layout()
	return player_layout if team == GameCatalog.TEAM_PLAYER else _mirror_tower_layout(player_layout)


func get_base_wall_segments(team: String) -> Array[Dictionary]:
	var player_segments := _player_base_wall_segments()
	if team == GameCatalog.TEAM_PLAYER:
		return player_segments

	var mirrored: Array[Dictionary] = []
	for segment in player_segments:
		var start: Vector2 = segment.get("start", Vector2.ZERO)
		var end: Vector2 = segment.get("end", Vector2.ZERO)
		mirrored.append(_wall_segment(-end, -start))

	return mirrored


func get_base_ground_polygon(team: String) -> PackedVector2Array:
	var points := _player_base_ground_points()
	if team == GameCatalog.TEAM_PLAYER:
		return points

	var mirrored := PackedVector2Array()
	for i in range(points.size() - 1, -1, -1):
		mirrored.append(-points[i])

	return mirrored


func get_lane_tower_positions(team: String) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for tower in get_lane_tower_layout(team):
		var tower_position: Vector2 = tower.get("position", Vector2.ZERO)
		positions.append(tower_position)

	return positions


func _tower_entry(lane: String, tier: int, tower_position: Vector2) -> Dictionary:
	return {
		"lane": lane,
		"tier": tier,
		"position": tower_position,
	}


func _get_player_tower_layout() -> Array[Dictionary]:
	return [
		_tower_entry(GameCatalog.LANE_TOP, 3, Vector2(-1310.0, 960.0)),
		_tower_entry(GameCatalog.LANE_TOP, 2, Vector2(-1295.0, -30.0)),
		_tower_entry(GameCatalog.LANE_TOP, 1, Vector2(-1280.0, -1020.0)),
		_tower_entry(GameCatalog.LANE_MIDDLE, 3, Vector2(-1060.0, 1060.0)),
		_tower_entry(GameCatalog.LANE_MIDDLE, 2, Vector2(-640.0, 640.0)),
		_tower_entry(GameCatalog.LANE_MIDDLE, 1, Vector2(-220.0, 220.0)),
		_tower_entry(GameCatalog.LANE_BOTTOM, 3, Vector2(-1010.0, 1310.0)),
		_tower_entry(GameCatalog.LANE_BOTTOM, 2, Vector2(5.0, 1295.0)),
		_tower_entry(GameCatalog.LANE_BOTTOM, 1, Vector2(1020.0, 1280.0)),
	]


func _mirror_tower_layout(layout: Array[Dictionary]) -> Array[Dictionary]:
	var mirrored: Array[Dictionary] = []
	for tower in layout:
		var tower_lane := String(tower.get("lane", GameCatalog.LANE_MIDDLE))
		var tower_tier := int(tower.get("tier", 1))
		var tower_position: Vector2 = tower.get("position", Vector2.ZERO)
		mirrored.append(_tower_entry(tower_lane, tower_tier, -tower_position))

	return mirrored


func _player_base_ground_points() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(-1400.0, 840.0),
		Vector2(-1140.0, 840.0),
		Vector2(-900.0, 1080.0),
		Vector2(-900.0, 1400.0),
		Vector2(-1400.0, 1400.0),
	])


func _player_base_wall_segments() -> Array[Dictionary]:
	var segments: Array[Dictionary] = []

	_add_wall_segment(segments, Vector2(-1400.0, 840.0), Vector2(-1340.0, 840.0))
	_add_wall_segment(segments, Vector2(-1220.0, 840.0), Vector2(-1140.0, 840.0))
	_add_wall_segment(segments, Vector2(-1140.0, 840.0), Vector2(-1070.0, 910.0))
	_add_wall_segment(segments, Vector2(-970.0, 1010.0), Vector2(-900.0, 1080.0))
	_add_wall_segment(segments, Vector2(-900.0, 1080.0), Vector2(-900.0, 1220.0))
	_add_wall_segment(segments, Vector2(-900.0, 1340.0), Vector2(-900.0, 1400.0))
	_add_wall_segment(segments, Vector2(-900.0, 1400.0), Vector2(-1400.0, 1400.0))
	_add_wall_segment(segments, Vector2(-1400.0, 1400.0), Vector2(-1400.0, 840.0))

	return segments


func _add_wall_segment(segments: Array[Dictionary], start: Vector2, end: Vector2) -> void:
	if start.distance_to(end) <= 8.0:
		return

	segments.append(_wall_segment(start, end))


func _wall_segment(start: Vector2, end: Vector2) -> Dictionary:
	var delta := end - start
	return {
		"start": start,
		"end": end,
		"center": start.lerp(end, 0.5),
		"size": Vector2(delta.length(), BASE_WALL_THICKNESS),
		"rotation": delta.angle(),
	}


func _draw() -> void:
	for lane in [GameCatalog.LANE_TOP, GameCatalog.LANE_MIDDLE, GameCatalog.LANE_BOTTOM]:
		_draw_lane(lane)


func _draw_lane(lane: String) -> void:
	var path := get_lane_path(GameCatalog.TEAM_PLAYER, lane)
	draw_polyline(path, Color(0.12, 0.10, 0.08, 0.28), 68.0, true)
	draw_polyline(path, Color(0.65, 0.59, 0.43, 0.62), 46.0, true)
	draw_polyline(path, Color(0.95, 0.82, 0.52, 0.22), 4.0, true)


func _get_player_lane_path(lane: String) -> PackedVector2Array:
	match lane:
		GameCatalog.LANE_TOP:
			return PackedVector2Array([
				Vector2(-1280.0, 960.0),
				Vector2(-1280.0, 840.0),
				Vector2(-1280.0, -1020.0),
				Vector2(-1020.0, -1280.0),
				Vector2(1020.0, -1280.0),
				Vector2(1280.0, -1020.0),
				Vector2(1280.0, -960.0),
			])
		GameCatalog.LANE_BOTTOM:
			return _mirror_top_lane_to_bottom()
		_:
			return PackedVector2Array([
				Vector2(-1120.0, 1120.0),
				Vector2(-1000.0, 1000.0),
				Vector2(-600.0, 600.0),
				Vector2(0.0, 0.0),
				Vector2(600.0, -600.0),
				Vector2(1000.0, -1000.0),
				Vector2(1120.0, -1120.0),
			])


func _mirror_top_lane_to_bottom() -> PackedVector2Array:
	var mirrored := PackedVector2Array()
	for point in _get_player_lane_path(GameCatalog.LANE_TOP):
		mirrored.append(Vector2(-point.y, -point.x))

	return mirrored
