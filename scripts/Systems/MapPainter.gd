class_name MapPainter
extends Node2D

const MAP_RECT := Rect2(Vector2(-1400.0, -1400.0), Vector2(2800.0, 2800.0))
const CAMERA_RECT := Rect2(Vector2(-1580.0, -1500.0), Vector2(3160.0, 3260.0))

var _lane_manager: LaneManager

const NEUTRAL_CAMP_UNIT_OFFSETS := [
	Vector2(-30.0, -18.0),
	Vector2(30.0, -18.0),
	Vector2(0.0, 30.0),
]


func _ready() -> void:
	_lane_manager = get_parent().get_node_or_null("LaneManager") as LaneManager
	z_index = -100
	queue_redraw()


func _draw() -> void:
	_draw_ground()
	_draw_terrain_noise()
	_draw_river()
	_draw_lane_roads()
	_draw_cliffs_and_walls()
	_draw_jungle()
	_draw_bases()
	_draw_neutral_camps()
	_draw_lane_markers()


func _draw_ground() -> void:
	draw_rect(CAMERA_RECT, Color(0.25, 0.31, 0.22))
	draw_rect(MAP_RECT, Color(0.34, 0.38, 0.26))
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-1400.0, 1400.0),
			Vector2(-1400.0, 300.0),
			Vector2(-970.0, 570.0),
			Vector2(-470.0, 520.0),
			Vector2(-155.0, 760.0),
			Vector2(230.0, 1400.0),
		]),
		Color(0.28, 0.48, 0.22)
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(1400.0, -1400.0),
			Vector2(1400.0, -300.0),
			Vector2(970.0, -570.0),
			Vector2(470.0, -520.0),
			Vector2(155.0, -760.0),
			Vector2(-230.0, -1400.0),
		]),
		Color(0.42, 0.36, 0.24)
	)
	draw_rect(CAMERA_RECT, Color(0.02, 0.025, 0.025, 0.20), false, 6.0)
	draw_rect(MAP_RECT, Color(0.02, 0.025, 0.025, 0.18), false, 8.0)


func _draw_terrain_noise() -> void:
	for i in range(330):
		var x := MAP_RECT.position.x + 40.0 + float((i * 97) % int(MAP_RECT.size.x - 80.0))
		var y := MAP_RECT.position.y + 40.0 + float((i * 53) % int(MAP_RECT.size.y - 80.0))
		var size := 3.0 + float((i * 7) % 9)
		var color := Color(0.45, 0.42, 0.29, 0.22) if i % 2 == 0 else Color(0.20, 0.31, 0.18, 0.22)
		draw_rect(Rect2(Vector2(x, y), Vector2(size, 2.0)), color)

	for i in range(108):
		var x := MAP_RECT.position.x + 70.0 + float((i * 181) % int(MAP_RECT.size.x - 140.0))
		var y := MAP_RECT.position.y + 70.0 + float((i * 113) % int(MAP_RECT.size.y - 140.0))
		_draw_rock(Vector2(x, y), 0.65 + float(i % 3) * 0.18)


func _draw_river() -> void:
	var river := PackedVector2Array([
		Vector2(-1380.0, -310.0),
		Vector2(-980.0, -200.0),
		Vector2(-560.0, -120.0),
		Vector2(-230.0, -46.0),
		Vector2(0.0, 0.0),
		Vector2(230.0, 46.0),
		Vector2(560.0, 120.0),
		Vector2(980.0, 200.0),
		Vector2(1380.0, 310.0),
	])
	draw_polyline(river, Color(0.17, 0.23, 0.24), 92.0, true)
	draw_polyline(river, Color(0.27, 0.39, 0.39), 68.0, true)
	draw_polyline(river, Color(0.39, 0.52, 0.49, 0.45), 10.0, true)

	for bridge in [Vector2(-1120.0, -235.0), Vector2(0.0, 0.0), Vector2(1120.0, 235.0)]:
		_draw_bridge(bridge)


func _draw_lane_roads() -> void:
	if _lane_manager == null:
		return

	for lane in [GameCatalog.LANE_TOP, GameCatalog.LANE_MIDDLE, GameCatalog.LANE_BOTTOM]:
		var path := _lane_manager.get_lane_path(GameCatalog.TEAM_PLAYER, lane)
		draw_polyline(path, Color(0.15, 0.13, 0.10, 0.35), 86.0, true)
		draw_polyline(path, Color(0.62, 0.55, 0.39), 62.0, true)
		draw_polyline(path, Color(0.79, 0.72, 0.52, 0.24), 6.0, true)


func _draw_cliffs_and_walls() -> void:
	for pos in [
		Vector2(-1100.0, -900.0), Vector2(-1050.0, -900.0), Vector2(-1000.0, -900.0),
		Vector2(-830.0, -470.0), Vector2(-780.0, -470.0), Vector2(-730.0, -470.0),
		Vector2(-635.0, 175.0), Vector2(-585.0, 175.0), Vector2(-535.0, 175.0),
		Vector2(-350.0, 420.0), Vector2(-300.0, 420.0), Vector2(-250.0, 420.0),
		Vector2(350.0, -420.0), Vector2(300.0, -420.0), Vector2(250.0, -420.0),
		Vector2(635.0, -175.0), Vector2(585.0, -175.0), Vector2(535.0, -175.0),
		Vector2(830.0, 470.0), Vector2(780.0, 470.0), Vector2(730.0, 470.0),
		Vector2(1100.0, 900.0), Vector2(1050.0, 900.0), Vector2(1000.0, 900.0),
		Vector2(-110.0, -285.0), Vector2(-60.0, -285.0), Vector2(60.0, 285.0), Vector2(110.0, 285.0),
	]:
		_draw_wall_piece(pos)


func _draw_jungle() -> void:
	_draw_tree_cluster(Vector2(-1120.0, -760.0), 32, 230.0, 170.0)
	_draw_tree_cluster(Vector2(-810.0, 40.0), 42, 240.0, 170.0)
	_draw_tree_cluster(Vector2(-620.0, -300.0), 34, 230.0, 155.0)
	_draw_tree_cluster(Vector2(-500.0, -820.0), 28, 210.0, 150.0)
	_draw_tree_cluster(Vector2(-405.0, 345.0), 30, 205.0, 150.0)
	_draw_tree_cluster(Vector2(-80.0, 470.0), 24, 180.0, 130.0)
	_draw_tree_cluster(Vector2(-115.0, -430.0), 26, 185.0, 130.0)
	_draw_tree_cluster(Vector2(-280.0, 910.0), 28, 220.0, 155.0)
	_draw_tree_cluster(Vector2(1120.0, 760.0), 32, 230.0, 170.0)
	_draw_tree_cluster(Vector2(810.0, -40.0), 42, 240.0, 170.0)
	_draw_tree_cluster(Vector2(620.0, 300.0), 34, 230.0, 155.0)
	_draw_tree_cluster(Vector2(500.0, 820.0), 28, 210.0, 150.0)
	_draw_tree_cluster(Vector2(405.0, -345.0), 30, 205.0, 150.0)
	_draw_tree_cluster(Vector2(80.0, -470.0), 24, 180.0, 130.0)
	_draw_tree_cluster(Vector2(115.0, 430.0), 26, 185.0, 130.0)
	_draw_tree_cluster(Vector2(280.0, -910.0), 28, 220.0, 155.0)


func _draw_bases() -> void:
	if _lane_manager != null:
		_draw_base_ground(_lane_manager.get_base_position(GameCatalog.TEAM_PLAYER), true)
		_draw_base_ground(_lane_manager.get_base_position(GameCatalog.TEAM_ENEMY), false)
		_draw_base_walls(GameCatalog.TEAM_PLAYER, true)
		_draw_base_walls(GameCatalog.TEAM_ENEMY, false)
		return

	_draw_base_ground(Vector2(-1245.0, 1255.0), true)
	_draw_base_ground(Vector2(1245.0, -1255.0), false)


func _draw_neutral_camps() -> void:
	for camp in _neutral_camp_positions():
		_draw_neutral_camp(camp)


func _draw_neutral_camp(center: Vector2) -> void:
	draw_circle(center + Vector2(5.0, 8.0), 82.0, Color(0.03, 0.025, 0.02, 0.28))
	draw_circle(center, 78.0, Color(0.19, 0.15, 0.09, 0.58))
	draw_circle(center, 64.0, Color(0.31, 0.25, 0.15, 0.52))
	draw_arc(center, 80.0, 0.0, TAU, 40, Color(0.08, 0.06, 0.035, 0.70), 5.0)
	draw_arc(center, 74.0, 0.0, TAU, 40, Color(0.72, 0.58, 0.31, 0.62), 2.4)

	for i in range(NEUTRAL_CAMP_UNIT_OFFSETS.size()):
		var slot: Vector2 = center + NEUTRAL_CAMP_UNIT_OFFSETS[i]
		draw_circle(slot, 22.0, Color(0.08, 0.06, 0.04, 0.46))
		draw_circle(slot, 17.0, Color(0.38, 0.31, 0.18, 0.58))
		draw_arc(slot, 22.0, 0.0, TAU, 28, Color(0.74, 0.62, 0.38, 0.46), 1.8)

	draw_circle(center, 13.0, Color(0.08, 0.045, 0.02, 0.78))
	draw_circle(center, 8.0, Color(0.86, 0.42, 0.12, 0.72))
	draw_circle(center + Vector2(2.0, -2.0), 4.0, Color(1.0, 0.78, 0.24, 0.82))
	draw_line(center + Vector2(-18.0, 10.0), center + Vector2(18.0, 10.0), Color(0.45, 0.28, 0.12, 0.74), 4.0)
	draw_line(center + Vector2(-17.0, -3.0), center + Vector2(15.0, 18.0), Color(0.34, 0.20, 0.10, 0.68), 3.0)

	for i in range(9):
		var angle := float(i) * TAU / 9.0 + 0.22
		var radius := 72.0 + float(i % 2) * 7.0
		_draw_camp_stone(center + Vector2.RIGHT.rotated(angle) * radius, 0.85 + float(i % 3) * 0.12)


func _draw_camp_stone(position: Vector2, scale: float) -> void:
	draw_colored_polygon(PackedVector2Array([
		position + Vector2(-8.0, 5.0) * scale,
		position + Vector2(-3.0, -7.0) * scale,
		position + Vector2(8.0, -4.0) * scale,
		position + Vector2(10.0, 6.0) * scale,
		position + Vector2(1.0, 9.0) * scale,
	]), Color(0.18, 0.17, 0.13, 0.68))


func _neutral_camp_positions() -> Array[Vector2]:
	return [
		Vector2(1000.0, -220.0),
		Vector2(650.0, 220.0),
		Vector2(1030.0, 650.0),
		Vector2(500.0, 1000.0),
		Vector2(-580.0, 1010.0),
		Vector2(-205.0, 785.0),
		Vector2(170.0, 470.0),
		Vector2(675.0, 505.0),
		Vector2(-1000.0, 220.0),
		Vector2(-650.0, -220.0),
		Vector2(-1030.0, -650.0),
		Vector2(-500.0, -1000.0),
		Vector2(580.0, -1010.0),
		Vector2(205.0, -785.0),
		Vector2(-170.0, -470.0),
		Vector2(-675.0, -505.0),
	]


func _draw_lane_markers() -> void:
	if _lane_manager == null:
		return

	for lane in [GameCatalog.LANE_TOP, GameCatalog.LANE_MIDDLE, GameCatalog.LANE_BOTTOM]:
		var path := _lane_manager.get_lane_path(GameCatalog.TEAM_PLAYER, lane)
		for i in range(1, path.size() - 1):
			_draw_banner(path[i], i % 2 == 0)


func _draw_base_ground(center: Vector2, player_side: bool) -> void:
	var color := Color(0.34, 0.44, 0.27) if player_side else Color(0.43, 0.31, 0.25)
	var team := GameCatalog.TEAM_PLAYER if player_side else GameCatalog.TEAM_ENEMY
	var base_polygon := _lane_manager.get_base_ground_polygon(team) if _lane_manager != null else _fallback_base_ground_polygon(center)
	var shadow_polygon := PackedVector2Array()
	for point in base_polygon:
		shadow_polygon.append(point + Vector2(5.0, 5.0))

	draw_colored_polygon(shadow_polygon, Color(0.13, 0.12, 0.10, 0.32))
	draw_colored_polygon(base_polygon, color)
	draw_polyline(_closed_points(base_polygon), Color(0.70, 0.68, 0.57, 0.70), 5.0, true)


func _draw_base_walls(team: String, player_side: bool) -> void:
	var stone := Color(0.36, 0.34, 0.30) if player_side else Color(0.38, 0.30, 0.28)
	var inner := Color(0.52, 0.50, 0.43) if player_side else Color(0.52, 0.42, 0.38)
	var trim := Color(0.18, 0.16, 0.13)

	for wall_segment in _lane_manager.get_base_wall_segments(team):
		var center: Vector2 = wall_segment.get("center", Vector2.ZERO)
		var size: Vector2 = wall_segment.get("size", Vector2.ZERO)
		var rotation := float(wall_segment.get("rotation", 0.0))
		_draw_rotated_rect(center + Vector2(5.0, 5.0), size + Vector2(10.0, 10.0), rotation, Color(0.04, 0.035, 0.03, 0.35))
		_draw_rotated_rect(center, size, rotation, trim)
		_draw_rotated_rect(center, size - Vector2(8.0, 8.0), rotation, stone)
		_draw_rotated_rect(center, size - Vector2(20.0, 20.0), rotation, inner)
		_draw_wall_crenels(center, size, rotation, trim.lightened(0.2))


func _draw_wall_crenels(center: Vector2, size: Vector2, rotation: float, color: Color) -> void:
	var length := size.x
	var count := maxi(1, int(length / 36.0))
	var direction := Vector2.RIGHT.rotated(rotation)

	for i in range(count):
		var progress := (float(i) + 0.5) / float(count)
		var offset := -length * 0.5 + length * progress
		_draw_rotated_rect(center + direction * offset, Vector2(12.0, 12.0), rotation, color)


func _fallback_base_ground_polygon(center: Vector2) -> PackedVector2Array:
	var half := Vector2(380.0, 380.0)
	return PackedVector2Array([
		center + Vector2(-half.x, -half.y),
		center + Vector2(half.x * 0.16, -half.y),
		center + Vector2(half.x, -half.y * 0.16),
		center + Vector2(half.x, half.y),
		center + Vector2(-half.x, half.y),
	])


func _closed_points(points: PackedVector2Array) -> PackedVector2Array:
	var closed := PackedVector2Array(points)
	if closed.size() > 0:
		closed.append(closed[0])
	return closed


func _draw_rotated_rect(center: Vector2, size: Vector2, rotation: float, color: Color) -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return

	var half := size * 0.5
	var corners := PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])
	for i in range(corners.size()):
		corners[i] = center + corners[i].rotated(rotation)

	draw_colored_polygon(corners, color)


func _draw_tower(position: Vector2, player_side: bool) -> void:
	var roof := Color(0.24, 0.78, 0.25) if player_side else Color(0.86, 0.23, 0.19)
	draw_rect(Rect2(position - Vector2(15.0, 18.0), Vector2(30.0, 36.0)), Color(0.42, 0.38, 0.29))
	draw_colored_polygon(PackedVector2Array([position + Vector2(-20.0, -17.0), position + Vector2(20.0, -17.0), position + Vector2(0.0, -38.0)]), roof)
	draw_rect(Rect2(position - Vector2(15.0, 18.0), Vector2(30.0, 36.0)), Color.BLACK, false, 2.0)


func _draw_tree_cluster(center: Vector2, count: int, width: float, height: float) -> void:
	for i in range(count):
		var x := center.x - width * 0.5 + float((i * 47) % int(width))
		var y := center.y - height * 0.5 + float((i * 31) % int(height))
		var scale := 0.75 + float(i % 4) * 0.12
		_draw_tree(Vector2(x, y), scale, i % 3 == 0)


func _draw_tree(position: Vector2, scale: float, dark: bool) -> void:
	var trunk := Color(0.25, 0.16, 0.09)
	var leaf := Color(0.12, 0.28, 0.14) if dark else Color(0.18, 0.37, 0.16)
	draw_rect(Rect2(position + Vector2(-3.0, 7.0) * scale, Vector2(6.0, 10.0) * scale), trunk)
	draw_colored_polygon(PackedVector2Array([
		position + Vector2(-16.0, 7.0) * scale,
		position + Vector2(16.0, 7.0) * scale,
		position + Vector2(0.0, -22.0) * scale,
	]), leaf)
	draw_colored_polygon(PackedVector2Array([
		position + Vector2(-12.0, -4.0) * scale,
		position + Vector2(12.0, -4.0) * scale,
		position + Vector2(0.0, -28.0) * scale,
	]), leaf.lightened(0.08))


func _draw_wall_piece(position: Vector2) -> void:
	draw_rect(Rect2(position - Vector2(23.0, 10.0), Vector2(46.0, 20.0)), Color(0.32, 0.31, 0.27))
	draw_rect(Rect2(position - Vector2(23.0, 10.0), Vector2(46.0, 20.0)), Color(0.13, 0.12, 0.10), false, 2.0)
	draw_line(position + Vector2(-18.0, -2.0), position + Vector2(18.0, -2.0), Color(0.46, 0.44, 0.38), 2.0)


func _draw_bridge(position: Vector2) -> void:
	draw_rect(Rect2(position - Vector2(45.0, 13.0), Vector2(90.0, 26.0)), Color(0.38, 0.25, 0.14))
	for i in range(6):
		var x := position.x - 36.0 + float(i) * 14.0
		draw_line(Vector2(x, position.y - 12.0), Vector2(x, position.y + 12.0), Color(0.20, 0.13, 0.08), 2.0)
	draw_rect(Rect2(position - Vector2(45.0, 13.0), Vector2(90.0, 26.0)), Color(0.08, 0.06, 0.04), false, 2.0)


func _draw_rock(position: Vector2, scale: float) -> void:
	draw_colored_polygon(PackedVector2Array([
		position + Vector2(-9.0, 7.0) * scale,
		position + Vector2(-2.0, -8.0) * scale,
		position + Vector2(9.0, -3.0) * scale,
		position + Vector2(12.0, 8.0) * scale,
	]), Color(0.23, 0.23, 0.20, 0.65))


func _draw_banner(position: Vector2, player_side: bool) -> void:
	var flag_color := Color(0.20, 0.76, 0.22) if player_side else Color(0.83, 0.22, 0.18)
	draw_line(position + Vector2(0.0, -22.0), position + Vector2(0.0, 8.0), Color(0.12, 0.08, 0.05), 2.0)
	draw_colored_polygon(PackedVector2Array([
		position + Vector2(0.0, -22.0),
		position + Vector2(18.0, -16.0),
		position + Vector2(0.0, -10.0),
	]), flag_color)
