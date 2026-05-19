class_name EnemyHeroAi
extends Actor

const UnitArtRenderer := preload("res://scripts/Visuals/UnitArt.gd")
const STUCK_RECOVERY_TIME := 0.65
const STUCK_NUDGE_DISTANCE := 14.0

@export var objective_position := Vector2.ZERO
@export var aggro_range := 260.0
@export var camp_arrival_distance := 42.0
@export var base_navigation_radius := 440.0
@export var base_exit_arrival_distance := 30.0

var hero_id := GameCatalog.DEFAULT_HERO_ID
var _hero_display_name := "Enemy Hero"
var _hero_body_color := Color(0.88, 0.24, 0.22)
var _farm_positions: Array[Vector2] = []
var _farm_index := 0
var _hero_definition := {}
var _home_base_position := Vector2.ZERO
var _home_base_exit_position := Vector2.ZERO
var _home_base_exit_route: Array[Vector2] = []
var _enemy_base_position := Vector2.ZERO
var _enemy_base_exit_position := Vector2.ZERO
var _enemy_base_exit_route: Array[Vector2] = []
var _has_base_navigation := false
var _last_navigation_point := Vector2.ZERO
var _stuck_timer := 0.0
var _active_route: Array[Vector2] = []
var _active_route_index := 0
var _active_route_key := ""

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if not is_alive():
		velocity = Vector2.ZERO
		return

	var previous_position := global_position
	var target := _find_farm_target()
	if target != null:
		if not try_attack(target):
			_move_toward(target.global_position)
		else:
			velocity = Vector2.ZERO
	else:
		_move_toward(_current_farm_position())

	move_and_slide()
	_tick_stuck_recovery(delta, previous_position)


func configure_enemy_hero(definition: Dictionary, hero_level := 1) -> void:
	if definition.is_empty():
		return

	_hero_definition = definition.duplicate(true)
	hero_id = String(definition.get("id", GameCatalog.DEFAULT_HERO_ID))
	_hero_display_name = String(definition.get("display_name", _format_hero_id(hero_id)))
	_hero_body_color = _color_for_hero(hero_id)
	configure(GameCatalog.TEAM_ENEMY, GameCatalog.LANE_MIDDLE, GameCatalog.create_scaled_hero_stats(_hero_definition, hero_level))
	add_to_group("team_%s_heroes" % team)


func set_farm_positions(positions: Array[Vector2]) -> void:
	_farm_positions = positions.duplicate()
	_farm_positions.sort_custom(
		func(a: Vector2, b: Vector2) -> bool:
			return global_position.distance_squared_to(a) < global_position.distance_squared_to(b)
	)
	_farm_index = 0


func set_base_navigation(home_base_position: Vector2, home_base_exit_position: Vector2, enemy_base_position: Vector2, enemy_base_exit_position: Vector2) -> void:
	_home_base_position = home_base_position
	_home_base_exit_position = home_base_exit_position
	_enemy_base_position = enemy_base_position
	_enemy_base_exit_position = enemy_base_exit_position
	_has_base_navigation = true


func set_base_navigation_routes(home_base_exit_route: Array[Vector2], enemy_base_exit_route: Array[Vector2]) -> void:
	_home_base_exit_route = home_base_exit_route.duplicate()
	_enemy_base_exit_route = enemy_base_exit_route.duplicate()


func get_display_name() -> String:
	return _hero_display_name


func get_hero_color() -> Color:
	return _hero_body_color


func _move_toward(point: Vector2) -> void:
	var next_point := _navigation_point_for(point)
	_last_navigation_point = next_point
	if global_position.distance_to(next_point) < 8.0:
		velocity = Vector2.ZERO
		return

	velocity = global_position.direction_to(next_point) * get_move_speed()


func _draw_unit_body(team_color: Color) -> void:
	UnitArtRenderer.draw_hero(self, hero_id, team_color, draw_radius)


func get_hit_radius() -> float:
	return draw_radius * 1.65


func get_pick_radius() -> float:
	return draw_radius * 3.4


func _get_health_bar_offset() -> float:
	return draw_radius * 4.4 + 8.0


func _get_projectile_kind(is_ranged_attack: bool) -> String:
	if not is_ranged_attack:
		return "slash"

	match hero_id:
		"forest_ranger":
			return "arrow"
		"bard_frog":
			return "note"
		"sorcerer":
			return "orb"
		"ancient_druid":
			return "thorn"
		_:
			return "bolt"


func _get_team_color() -> Color:
	return _hero_body_color


func _find_farm_target() -> Actor:
	var neutral := _find_nearest_neutral(aggro_range)
	if neutral != null:
		return neutral

	var enemy := find_nearest_enemy(aggro_range * 0.55)
	if enemy != null and enemy.team != GameCatalog.TEAM_NEUTRAL:
		return enemy

	return null


func _find_nearest_neutral(radius: float) -> Actor:
	var best: Actor = null
	var best_edge_distance := radius

	for node in get_tree().get_nodes_in_group("team_neutral"):
		var actor := node as Actor
		if actor == null or not is_instance_valid(actor) or not can_damage(actor):
			continue

		var edge_distance := maxf(0.0, global_position.distance_to(actor.global_position) - actor.get_hit_radius())
		if edge_distance <= best_edge_distance:
			best = actor
			best_edge_distance = edge_distance

	return best


func _current_farm_position() -> Vector2:
	if _farm_positions.is_empty():
		return objective_position

	if global_position.distance_to(_farm_positions[_farm_index]) <= camp_arrival_distance:
		_farm_index = (_farm_index + 1) % _farm_positions.size()

	return _farm_positions[_farm_index]


func _navigation_point_for(point: Vector2) -> Vector2:
	if not _has_base_navigation:
		return point

	if not _active_route.is_empty():
		while (
			_active_route_index < _active_route.size() - 1
			and global_position.distance_to(_active_route[_active_route_index]) <= base_exit_arrival_distance
		):
			_active_route_index += 1

		if _active_route_index < _active_route.size() - 1 or global_position.distance_to(_active_route[_active_route_index]) > base_exit_arrival_distance:
			return _active_route[_active_route_index]

		_clear_active_route()

	if _should_route_through_exit(_home_base_position, _home_base_exit_position, point):
		return _route_waypoint_for("home", _home_base_exit_route, _home_base_position, point, _home_base_exit_position)
	if _should_route_through_exit(_enemy_base_position, _enemy_base_exit_position, point):
		return _route_waypoint_for("enemy", _enemy_base_exit_route, _enemy_base_position, point, _enemy_base_exit_position)

	_clear_active_route()
	return point


func _should_route_through_exit(base_position: Vector2, _exit_position: Vector2, point: Vector2) -> bool:
	var current_in_base := _is_inside_base_navigation_area(global_position, base_position)
	var target_in_base := _is_inside_base_navigation_area(point, base_position)
	if current_in_base == target_in_base:
		return false

	return true


func _is_inside_base_navigation_area(point: Vector2, base_position: Vector2) -> bool:
	return point.distance_to(base_position) <= base_navigation_radius


func _route_waypoint_for(route_key: String, route: Array[Vector2], base_position: Vector2, point: Vector2, fallback_exit: Vector2) -> Vector2:
	if route.is_empty():
		_clear_active_route()
		return fallback_exit

	var ordered_route := route.duplicate()
	var entering_base := not _is_inside_base_navigation_area(global_position, base_position) and _is_inside_base_navigation_area(point, base_position)
	if entering_base:
		ordered_route.reverse()

	var new_route_key := "%s:%s" % [route_key, "enter" if entering_base else "exit"]
	if _active_route_key != new_route_key or _active_route.is_empty():
		_active_route = ordered_route
		_active_route_index = _nearest_route_index_ahead(_active_route)
		_active_route_key = new_route_key

	while (
		_active_route_index < _active_route.size() - 1
		and global_position.distance_to(_active_route[_active_route_index]) <= base_exit_arrival_distance
	):
		_active_route_index += 1

	return _active_route[_active_route_index]


func _nearest_route_index_ahead(route: Array[Vector2]) -> int:
	var nearest_index := 0
	var nearest_distance := INF
	for i in range(route.size()):
		var route_point: Vector2 = route[i]
		var distance := global_position.distance_to(route_point)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_index = i

	return mini(nearest_index, route.size() - 1)


func _clear_active_route() -> void:
	_active_route.clear()
	_active_route_index = 0
	_active_route_key = ""


func _tick_stuck_recovery(delta: float, previous_position: Vector2) -> void:
	if velocity.length() <= 8.0:
		_stuck_timer = 0.0
		return

	if previous_position.distance_to(global_position) > 0.45:
		_stuck_timer = 0.0
		return

	_stuck_timer += delta
	if _stuck_timer < STUCK_RECOVERY_TIME:
		return

	if not _active_route.is_empty() and _active_route_index < _active_route.size():
		var route_point := _active_route[_active_route_index]
		if global_position.distance_to(route_point) <= base_exit_arrival_distance * 1.8 and _active_route_index < _active_route.size() - 1:
			_active_route_index += 1
			route_point = _active_route[_active_route_index]

		global_position = global_position.move_toward(route_point, STUCK_NUDGE_DISTANCE * 2.4)
		_stuck_timer = 0.0
		return

	var direction := global_position.direction_to(_last_navigation_point)
	if direction == Vector2.ZERO:
		direction = velocity.normalized()

	var side := -1.0 if int(get_instance_id()) % 2 == 0 else 1.0
	global_position += direction.orthogonal() * side * STUCK_NUDGE_DISTANCE
	global_position += direction * (STUCK_NUDGE_DISTANCE * 0.35)
	_stuck_timer = 0.0


func _color_for_hero(id: String) -> Color:
	match id:
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


func _format_hero_id(id: String) -> String:
	var words := id.split("_")
	var parts := []
	for word in words:
		if not word.is_empty():
			parts.append(word.capitalize())

	return " ".join(parts) if not parts.is_empty() else "Enemy Hero"
