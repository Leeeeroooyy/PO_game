class_name MinimapView
extends Control

const MAP_RECT := Rect2(Vector2(-1400.0, -1400.0), Vector2(2800.0, 2800.0))
const REDRAW_INTERVAL := 0.16

var _redraw_timer := 0.0


func _ready() -> void:
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(150.0, 150.0)
	queue_redraw()


func _process(delta: float) -> void:
	if not visible:
		return

	_redraw_timer = maxf(0.0, _redraw_timer - delta)
	if _redraw_timer > 0.0:
		return

	_redraw_timer = REDRAW_INTERVAL
	queue_redraw()


func _draw() -> void:
	var side := minf(size.x, size.y)
	var draw_origin := (size - Vector2(side, side)) * 0.5
	var draw_scale := Vector2(side / maxf(size.x, 1.0), side / maxf(size.y, 1.0))
	draw_set_transform(draw_origin, 0.0, draw_scale)

	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color(0.08, 0.10, 0.08))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, size.y),
		Vector2(0.0, size.y * 0.63),
		Vector2(size.x * 0.35, size.y * 0.74),
		Vector2(size.x * 0.58, size.y),
	]), Color(0.18, 0.42, 0.16))
	draw_colored_polygon(PackedVector2Array([
		Vector2(size.x, 0.0),
		Vector2(size.x, size.y * 0.37),
		Vector2(size.x * 0.65, size.y * 0.26),
		Vector2(size.x * 0.42, 0.0),
	]), Color(0.40, 0.28, 0.20))

	var river := PackedVector2Array([
		Vector2(0.0, size.y * 0.39),
		Vector2(size.x * 0.34, size.y * 0.45),
		Vector2(size.x * 0.51, size.y * 0.50),
		Vector2(size.x * 0.72, size.y * 0.56),
		Vector2(size.x, size.y * 0.61),
	])
	draw_polyline(river, Color(0.26, 0.44, 0.45), 9.0, true)

	_draw_mini_lane(PackedVector2Array([
		_to_mini(Vector2(-1280.0, 960.0)),
		_to_mini(Vector2(-1280.0, 840.0)),
		_to_mini(Vector2(-1280.0, -1020.0)),
		_to_mini(Vector2(-1020.0, -1280.0)),
		_to_mini(Vector2(1020.0, -1280.0)),
		_to_mini(Vector2(1280.0, -1020.0)),
		_to_mini(Vector2(1280.0, -960.0)),
	]))
	_draw_mini_lane(PackedVector2Array([
		_to_mini(Vector2(-1120.0, 1120.0)),
		_to_mini(Vector2(-1000.0, 1000.0)),
		_to_mini(Vector2(-600.0, 600.0)),
		_to_mini(Vector2(0.0, 0.0)),
		_to_mini(Vector2(600.0, -600.0)),
		_to_mini(Vector2(1000.0, -1000.0)),
		_to_mini(Vector2(1120.0, -1120.0)),
	]))
	_draw_mini_lane(PackedVector2Array([
		_to_mini(Vector2(-960.0, 1280.0)),
		_to_mini(Vector2(-840.0, 1280.0)),
		_to_mini(Vector2(1020.0, 1280.0)),
		_to_mini(Vector2(1280.0, 1020.0)),
		_to_mini(Vector2(1280.0, -1020.0)),
		_to_mini(Vector2(1020.0, -1280.0)),
		_to_mini(Vector2(960.0, -1280.0)),
	]))

	for camp in [
		Vector2(1000.0, -220.0), Vector2(650.0, 220.0),
		Vector2(1030.0, 650.0), Vector2(500.0, 1000.0),
		Vector2(-580.0, 1010.0), Vector2(-205.0, 785.0),
		Vector2(170.0, 470.0), Vector2(675.0, 505.0),
		Vector2(-1000.0, 220.0), Vector2(-650.0, -220.0),
		Vector2(-1030.0, -650.0), Vector2(-500.0, -1000.0),
		Vector2(580.0, -1010.0), Vector2(205.0, -785.0),
		Vector2(-170.0, -470.0), Vector2(-675.0, -505.0),
	]:
		draw_circle(_to_mini(camp), 1.8, Color(0.78, 0.64, 0.34))

	draw_circle(_to_mini(Vector2(-1245.0, 1255.0)), 5.0, Color(0.20, 0.85, 0.25))
	draw_circle(_to_mini(Vector2(1245.0, -1255.0)), 5.0, Color(0.90, 0.20, 0.18))
	_draw_actor_markers()
	draw_rect(rect, Color(0.72, 0.65, 0.48), false, 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_mini_lane(points: PackedVector2Array) -> void:
	draw_polyline(points, Color(0.73, 0.64, 0.42), 2.0, true)


func _to_mini(world: Vector2) -> Vector2:
	var clamped := Vector2(
		clampf(world.x, MAP_RECT.position.x, MAP_RECT.end.x),
		clampf(world.y, MAP_RECT.position.y, MAP_RECT.end.y)
	)
	return Vector2(
		(clamped.x - MAP_RECT.position.x) / MAP_RECT.size.x * size.x,
		(clamped.y - MAP_RECT.position.y) / MAP_RECT.size.y * size.y
	)


func _draw_actor_markers() -> void:
	var towers: Array[Actor] = []
	var creeps: Array[Actor] = []
	var heroes: Array[Actor] = []

	for node in get_tree().get_nodes_in_group("combat_actor"):
		var actor := node as Actor
		if actor == null or not is_instance_valid(actor) or not actor.is_alive():
			continue

		if actor is TowerStructure:
			towers.append(actor)
		elif actor is LaneUnit:
			creeps.append(actor)
		elif (actor is HeroController) or (actor is EnemyHeroAi):
			heroes.append(actor)

	for tower in towers:
		_draw_tower_marker(tower)

	for creep in creeps:
		_draw_creep_marker(creep)

	for hero in heroes:
		_draw_hero_marker(hero)


func _draw_tower_marker(tower: Actor) -> void:
	var point := _to_mini(tower.global_position)
	var color := _team_marker_color(tower.team)
	var marker_rect := Rect2(point - Vector2(2.6, 2.6), Vector2(5.2, 5.2))
	draw_rect(marker_rect.grow(1.0), Color(0.02, 0.025, 0.02, 0.92))
	draw_rect(marker_rect, color)


func _draw_creep_marker(creep: Actor) -> void:
	var point := _to_mini(creep.global_position)
	draw_circle(point, 2.0, Color(0.02, 0.025, 0.02, 0.82))
	draw_circle(point, 1.35, _team_marker_color(creep.team))


func _draw_hero_marker(hero: Actor) -> void:
	var point := _to_mini(hero.global_position)
	var color := _team_marker_color(hero.team).lightened(0.18)
	var diamond := PackedVector2Array([
		point + Vector2(0.0, -5.5),
		point + Vector2(5.5, 0.0),
		point + Vector2(0.0, 5.5),
		point + Vector2(-5.5, 0.0),
	])
	draw_colored_polygon(diamond, Color(0.02, 0.025, 0.02, 0.90))
	draw_colored_polygon(PackedVector2Array([
		point + Vector2(0.0, -4.1),
		point + Vector2(4.1, 0.0),
		point + Vector2(0.0, 4.1),
		point + Vector2(-4.1, 0.0),
	]), color)

	if hero.is_selected:
		draw_arc(point, 7.0, 0.0, TAU, 20, Color(1.0, 0.90, 0.28), 1.6)


func _team_marker_color(team: String) -> Color:
	match team:
		GameCatalog.TEAM_PLAYER:
			return Color(0.20, 0.92, 0.32)
		GameCatalog.TEAM_ENEMY:
			return Color(1.0, 0.22, 0.18)
		_:
			return Color(0.88, 0.70, 0.28)
