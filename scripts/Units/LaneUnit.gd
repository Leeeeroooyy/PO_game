class_name LaneUnit
extends Actor

const UnitArtRenderer := preload("res://scripts/Visuals/UnitArt.gd")

@export var lane_target := Vector2.ZERO
@export var unit_id := "line_melee"
@export var upgrade_level := 0

const BASE_RADIUS_BY_UNIT := {
	"line_melee": 11.0,
	"line_mage": 10.0,
	"line_siege": 15.0,
}
const MAX_VISIBLE_UPGRADE_PIPS := 5
const UPGRADE_PULSE_DURATION := 0.7
const TARGET_SEARCH_PADDING := 145.0
const TARGET_CHASE_PADDING := 260.0
const LANE_CREEP_FOCUS_RANGE := 560.0
const HERO_RETALIATION_DURATION := 2.8
const HERO_RETALIATION_CHASE_PADDING := 120.0
const SOFT_SEPARATION_FORCE := 88.0
const IDLE_SEPARATION_SPEED_FACTOR := 0.36
const STUCK_RECOVERY_TIME := 0.65
const TARGET_REFRESH_INTERVAL := 0.18
const SEPARATION_REFRESH_INTERVAL := 0.10

var lane_path := PackedVector2Array()
var _waypoint_index := 1
var _upgrade_pulse_timer := 0.0
var _combat_target: Actor
var _retaliation_target: Actor
var _retaliation_timer := 0.0
var _stuck_timer := 0.0
var _target_refresh_timer := 0.0
var _separation_refresh_timer := 0.0
var _cached_separation_push := Vector2.ZERO


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_tick_upgrade_pulse(delta)
	_tick_retaliation(delta)

	if not is_alive():
		velocity = Vector2.ZERO
		return

	var previous_position := global_position
	var enemy := _choose_combat_target(delta)
	if enemy != null:
		if try_attack(enemy):
			velocity = _with_soft_separation(Vector2.ZERO, delta)
		else:
			_move_toward_actor(enemy, delta)
	else:
		_move_along_lane(delta)

	move_and_slide()
	_tick_stuck_recovery(delta, previous_position)


func configure_lane_unit(new_unit_id: String, new_team: String, new_lane: String, path: PackedVector2Array, new_stats: Dictionary, new_upgrade_level := 0) -> void:
	unit_id = new_unit_id
	upgrade_level = maxi(0, new_upgrade_level)
	lane_path = path
	_waypoint_index = 1
	_combat_target = null
	_retaliation_target = null
	_retaliation_timer = 0.0
	_stuck_timer = 0.0
	_target_refresh_timer = float(get_instance_id() % 1000) / 1000.0 * TARGET_REFRESH_INTERVAL
	_separation_refresh_timer = float(int(get_instance_id() / 7) % 1000) / 1000.0 * SEPARATION_REFRESH_INTERVAL
	_cached_separation_push = Vector2.ZERO
	collision_layer = 0
	collision_mask = 0
	global_position = lane_path[0] if lane_path.size() > 0 else Vector2.ZERO
	lane_target = lane_path[lane_path.size() - 1] if lane_path.size() > 0 else Vector2.ZERO
	_apply_upgrade_visuals()
	configure(new_team, new_lane, new_stats)
	queue_redraw()


func take_damage(amount: float, source: Actor) -> void:
	if _is_hero_target(source) or source is SummonedCompanion:
		_retaliation_target = source
		_retaliation_timer = HERO_RETALIATION_DURATION

	super.take_damage(amount, source)


func apply_upgrade_level(new_level: int, upgraded_stats: Dictionary) -> void:
	if not is_alive():
		return

	var old_max_health := maxf(_stat("max_health"), 1.0)
	var old_health := health
	upgrade_level = maxi(0, new_level)
	stats = upgraded_stats.duplicate(true)

	var new_max_health := maxf(_stat("max_health"), 1.0)
	health = minf(new_max_health, old_health + maxf(0.0, new_max_health - old_max_health))
	_attack_cooldown = minf(_attack_cooldown, _stat("attack_cooldown"))
	_upgrade_pulse_timer = UPGRADE_PULSE_DURATION
	_apply_upgrade_visuals()
	health_changed.emit(health, new_max_health)
	queue_redraw()


func _draw() -> void:
	super._draw()
	_draw_upgrade_effects()


func _draw_unit_body(team_color: Color) -> void:
	UnitArtRenderer.draw_lane_creep(self, unit_id, team_color, draw_radius)


func get_hit_radius() -> float:
	if unit_id == "line_siege":
		return draw_radius * 1.55

	return draw_radius * 1.35


func get_pick_radius() -> float:
	if unit_id == "line_siege":
		return draw_radius * 3.0

	return draw_radius * 2.75


func _get_health_bar_offset() -> float:
	return draw_radius * 3.7 + 8.0


func _get_projectile_kind(is_ranged_attack: bool) -> String:
	if not is_ranged_attack:
		return "slash"

	match unit_id:
		"line_mage":
			return "orb"
		"line_siege":
			return "stone"
		_:
			return "bolt"


func _apply_upgrade_visuals() -> void:
	var base_radius := float(BASE_RADIUS_BY_UNIT.get(unit_id, draw_radius))
	draw_radius = base_radius + minf(float(upgrade_level), 8.0) * 0.9
	_sync_hitbox()


func _draw_upgrade_effects() -> void:
	if upgrade_level <= 0:
		return

	var ring_color := Color(1.0, 0.76, 0.26, 0.86)
	var dark_ring := Color(0.03, 0.02, 0.01, 0.74)
	var ring_radius := draw_radius + 5.0
	draw_arc(Vector2.ZERO, ring_radius + 2.0, 0.0, TAU, 48, dark_ring, 3.5)
	draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 48, ring_color, 2.2)

	if upgrade_level >= 3:
		draw_arc(Vector2.ZERO, ring_radius + 4.0, -PI * 0.15, PI * 0.65, 24, Color(0.45, 0.95, 1.0, 0.72), 2.0)
	if upgrade_level >= 6:
		draw_arc(Vector2.ZERO, ring_radius + 7.0, PI * 0.85, PI * 1.55, 24, Color(0.9, 0.48, 1.0, 0.62), 2.0)

	if _upgrade_pulse_timer > 0.0:
		var pulse_ratio := _upgrade_pulse_timer / UPGRADE_PULSE_DURATION
		var pulse_radius := ring_radius + (1.0 - pulse_ratio) * 12.0
		draw_arc(Vector2.ZERO, pulse_radius, 0.0, TAU, 48, Color(1.0, 0.92, 0.42, pulse_ratio * 0.72), 3.0)

	var pip_count := mini(upgrade_level, MAX_VISIBLE_UPGRADE_PIPS)
	var spacing := 5.2
	var first_x := -float(pip_count - 1) * spacing * 0.5
	for pip_index in range(pip_count):
		var pip_position := Vector2(first_x + float(pip_index) * spacing, draw_radius + 7.0)
		draw_circle(pip_position, 2.2, dark_ring)
		draw_circle(pip_position, 1.45, ring_color.lightened(0.18))

	if upgrade_level > MAX_VISIBLE_UPGRADE_PIPS:
		draw_arc(Vector2(0.0, draw_radius + 7.0), 5.0, 0.0, TAU, 18, Color(0.45, 0.95, 1.0, 0.72), 1.4)


func _tick_upgrade_pulse(delta: float) -> void:
	if _upgrade_pulse_timer <= 0.0:
		return

	_upgrade_pulse_timer = maxf(0.0, _upgrade_pulse_timer - delta)
	queue_redraw()


func _tick_retaliation(delta: float) -> void:
	if _retaliation_target != null and not is_instance_valid(_retaliation_target):
		_retaliation_target = null
		_retaliation_timer = 0.0
		return

	if _retaliation_timer <= 0.0:
		return

	_retaliation_timer = maxf(0.0, _retaliation_timer - delta)
	if _retaliation_timer <= 0.0:
		_retaliation_target = null


func _choose_combat_target(delta: float) -> Actor:
	if _is_valid_lane_target(_combat_target) and _can_keep_combat_target(_combat_target):
		return _combat_target

	_target_refresh_timer = maxf(0.0, _target_refresh_timer - delta)
	if _target_refresh_timer > 0.0:
		_combat_target = null
		return null

	_target_refresh_timer = TARGET_REFRESH_INTERVAL

	var lane_creep_target := _find_best_lane_target(LANE_CREEP_FOCUS_RANGE, false, true)
	if lane_creep_target != null:
		_combat_target = lane_creep_target
		return _combat_target

	var non_hero_target := _find_best_lane_target(_target_search_range(), false, false)
	if non_hero_target != null:
		_combat_target = non_hero_target
		return _combat_target

	if _is_valid_lane_target(_retaliation_target) and _retaliation_timer > 0.0 and _edge_distance_to(_retaliation_target) <= _hero_retaliation_chase_range():
		_combat_target = _retaliation_target
		return _combat_target

	_combat_target = null
	return _combat_target


func _find_best_lane_target(search_radius: float, allow_heroes := false, only_lane_creeps := false) -> Actor:
	var best: Actor = null
	var best_score := INF

	for node in _get_lane_target_nodes():
		var actor := node as Actor
		if not _is_valid_lane_target(actor):
			continue
		if only_lane_creeps and not (actor is LaneUnit):
			continue
		if not allow_heroes and _is_hero_target(actor):
			continue

		var edge_distance := _edge_distance_to(actor)
		if edge_distance > search_radius:
			continue

		var score := float(_target_priority(actor)) * 1000.0 + edge_distance
		if score < best_score:
			best = actor
			best_score = score

	return best


func _get_lane_target_nodes() -> Array:
	match team:
		GameCatalog.TEAM_PLAYER:
			return get_tree().get_nodes_in_group("team_enemy")
		GameCatalog.TEAM_ENEMY:
			return get_tree().get_nodes_in_group("team_player")
		_:
			return get_tree().get_nodes_in_group("combat_actor")


func _can_keep_combat_target(candidate) -> bool:
	if not _is_valid_lane_target(candidate):
		return false

	var actor := candidate as Actor
	if _is_hero_target(actor):
		return (
			_retaliation_target != null
			and is_instance_valid(_retaliation_target)
			and actor == _retaliation_target
			and _retaliation_timer > 0.0
			and _edge_distance_to(actor) <= _hero_retaliation_chase_range()
			and _find_best_lane_target(LANE_CREEP_FOCUS_RANGE, false, true) == null
		)

	if actor is LaneUnit or actor is SummonedCompanion:
		return _edge_distance_to(actor) <= _target_chase_range()

	return _edge_distance_to(actor) <= _target_search_range()


func _is_valid_lane_target(candidate) -> bool:
	if candidate == null or not is_instance_valid(candidate):
		return false

	var actor := candidate as Actor
	if actor == null or actor == self or not actor.is_alive() or not can_damage(actor):
		return false
	if actor.team == GameCatalog.TEAM_NEUTRAL:
		return false
	if actor is LaneUnit and (actor as LaneUnit).lane != lane:
		return false

	return true


func _is_hero_target(candidate) -> bool:
	return candidate is HeroController or candidate is EnemyHeroAi


func _target_priority(actor: Actor) -> int:
	if actor is LaneUnit:
		return 0
	if actor is SummonedCompanion:
		return 1
	if actor is HeroController or actor is EnemyHeroAi:
		return 2
	if actor is TowerStructure:
		return 3
	if actor is BaseStructure:
		return 4

	return 5


func _target_search_range() -> float:
	var base_range := maxf(_stat("attack_range") + TARGET_SEARCH_PADDING, 205.0)
	if _waypoint_index >= lane_path.size():
		base_range = maxf(base_range, 330.0)

	return base_range


func _target_chase_range() -> float:
	return maxf(_target_search_range() + 70.0, _stat("attack_range") + TARGET_CHASE_PADDING)


func _hero_retaliation_chase_range() -> float:
	return maxf(_stat("attack_range") + HERO_RETALIATION_CHASE_PADDING, 155.0)


func _edge_distance_to(candidate) -> float:
	if candidate == null or not is_instance_valid(candidate):
		return INF

	var actor := candidate as Actor
	if actor == null:
		return INF

	return maxf(0.0, global_position.distance_to(actor.global_position) - actor.get_hit_radius())


func _move_toward_actor(actor: Actor, delta: float) -> void:
	var direction := global_position.direction_to(actor.global_position)
	velocity = _with_soft_separation(direction * get_move_speed(), delta)


func _move_along_lane(delta: float) -> void:
	if lane_path.is_empty() or _waypoint_index >= lane_path.size():
		velocity = Vector2.ZERO
		return

	var target := lane_path[_waypoint_index]
	var reach_distance := maxf(22.0, get_hit_radius() * 1.18)
	while _waypoint_index < lane_path.size() and global_position.distance_to(target) < reach_distance:
		_waypoint_index += 1
		if _waypoint_index >= lane_path.size():
			velocity = Vector2.ZERO
			return

		target = lane_path[_waypoint_index]

	velocity = _with_soft_separation(global_position.direction_to(target) * get_move_speed(), delta)


func _with_soft_separation(base_velocity: Vector2, delta: float) -> Vector2:
	_separation_refresh_timer = maxf(0.0, _separation_refresh_timer - delta)
	if _separation_refresh_timer <= 0.0:
		_cached_separation_push = _calculate_soft_separation_push()
		_separation_refresh_timer = SEPARATION_REFRESH_INTERVAL

	var separation_velocity := _cached_separation_push * SOFT_SEPARATION_FORCE
	if separation_velocity == Vector2.ZERO:
		return base_velocity

	var base_speed := base_velocity.length()
	if base_speed <= 0.01:
		return separation_velocity.limit_length(get_move_speed() * IDLE_SEPARATION_SPEED_FACTOR)

	var direction := base_velocity / base_speed
	var forward_amount := separation_velocity.dot(direction)
	var adjusted := base_velocity
	if forward_amount < 0.0:
		adjusted += direction * forward_amount

	adjusted += separation_velocity - direction * forward_amount
	if adjusted.length() > base_speed:
		adjusted = adjusted.normalized() * base_speed

	return adjusted


func _calculate_soft_separation_push() -> Vector2:
	var push := Vector2.ZERO
	for node in get_tree().get_nodes_in_group("team_%s" % team):
		var actor := node as Actor
		if actor == null or actor == self or not is_instance_valid(actor) or not actor.is_alive() or actor.team != team:
			continue
		if not (actor is LaneUnit or actor is SummonedCompanion):
			continue

		var delta := global_position - actor.global_position
		var distance := delta.length()
		var spacing := get_hit_radius() + actor.get_hit_radius() + 8.0
		if distance >= spacing:
			continue

		var direction := delta / distance if distance > 0.01 else _fallback_separation_direction(actor)
		push += direction * ((spacing - distance) / spacing)

	return push


func _fallback_separation_direction(actor: Actor) -> Vector2:
	var angle := float(int(get_instance_id() + actor.get_instance_id()) % 360) * TAU / 360.0
	return Vector2.RIGHT.rotated(angle)


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

	if _combat_target != null:
		_combat_target = null
	elif _waypoint_index < lane_path.size() - 1:
		_waypoint_index += 1

	var direction := velocity.normalized()
	var side := -1.0 if int(get_instance_id()) % 2 == 0 else 1.0
	global_position += direction.orthogonal() * side * 8.0
	_stuck_timer = 0.0
