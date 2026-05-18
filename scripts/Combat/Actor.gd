class_name Actor
extends CharacterBody2D

signal died(victim: Actor, killer: Actor)
signal health_changed(current: float, maximum: float)

const ATTACK_VISUAL_DURATION := 0.34
const CAST_VISUAL_DURATION := 0.46
const VISUAL_REDRAW_INTERVAL := 1.0 / 30.0

@export var team := "neutral"
@export var lane := "middle"
@export var stats := {
	"max_health": 100.0,
	"move_speed": 120.0,
	"attack_damage": 10.0,
	"attack_range": 42.0,
	"attack_cooldown": 1.0,
	"health_regen": 0.0,
	"gold_reward": 5,
	"experience_reward": 4,
}
@export var draw_radius := 12.0

var health := 0.0
var is_selected := false
var _attack_cooldown := 0.0
var _move_speed_multiplier := 1.0
var _move_speed_timer := 0.0
var _incoming_damage_multiplier := 1.0
var _incoming_damage_timer := 0.0
var _damage_taken_multiplier := 1.0
var _damage_taken_timer := 0.0
var _attack_damage_multiplier := 1.0
var _attack_damage_timer := 0.0
var _forced_target: Actor
var _forced_target_timer := 0.0
var _visual_time := 0.0
var _attack_visual_timer := 0.0
var _attack_visual_direction := Vector2.RIGHT
var _cast_visual_timer := 0.0
var _cast_visual_color := Color.WHITE
var _cast_visual_id := ""
var _visual_facing_sign := 1.0
var _visual_redraw_timer := 0.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if health <= 0.0:
		health = _stat("max_health")
	_sync_hitbox()
	refresh_groups()
	health_changed.emit(health, _stat("max_health"))


func _physics_process(delta: float) -> void:
	_visual_time += delta
	if _attack_visual_timer > 0.0:
		_attack_visual_timer = maxf(0.0, _attack_visual_timer - delta)
	if _cast_visual_timer > 0.0:
		_cast_visual_timer = maxf(0.0, _cast_visual_timer - delta)
	if velocity.x > 4.0:
		_visual_facing_sign = 1.0
	elif velocity.x < -4.0:
		_visual_facing_sign = -1.0

	if _attack_cooldown > 0.0:
		_attack_cooldown = maxf(0.0, _attack_cooldown - delta)

	_tick_health_regen(delta)
	_tick_statuses(delta)
	_visual_redraw_timer += delta
	if is_alive() and _visual_redraw_timer >= VISUAL_REDRAW_INTERVAL:
		_visual_redraw_timer = 0.0
		queue_redraw()


func configure(new_team: String, new_lane: String, new_stats: Dictionary) -> void:
	team = new_team
	lane = new_lane
	stats = new_stats.duplicate(true)
	health = _stat("max_health")
	_attack_cooldown = 0.0
	_clear_statuses()
	_sync_hitbox()
	refresh_groups()
	health_changed.emit(health, _stat("max_health"))
	queue_redraw()


func take_damage(amount: float, source: Actor) -> void:
	if not is_alive() or amount <= 0.0:
		return

	var effective_amount := amount * _incoming_damage_multiplier * _damage_taken_multiplier
	health = maxf(0.0, health - effective_amount)
	health_changed.emit(health, _stat("max_health"))
	queue_redraw()

	if health <= 0.0:
		_die(source)


func heal(amount: float) -> void:
	if not is_alive() or amount <= 0.0:
		return

	health = minf(_stat("max_health"), health + amount)
	health_changed.emit(health, _stat("max_health"))
	queue_redraw()


func is_alive() -> bool:
	return health > 0.0


func can_damage(other: Actor) -> bool:
	if other == null or other == self or not other.is_alive() or team == other.team:
		return false

	return team != GameCatalog.TEAM_NEUTRAL or other.team != GameCatalog.TEAM_NEUTRAL


func try_attack(target: Actor) -> bool:
	if _attack_cooldown > 0.0 or not can_damage(target):
		return false

	if global_position.distance_to(target.global_position) > _stat("attack_range") + target.get_hit_radius():
		return false

	trigger_attack_visual(target.global_position)
	_spawn_attack_effect(target)
	target.take_damage(_stat("attack_damage") * _attack_damage_multiplier, self)
	_attack_cooldown = _stat("attack_cooldown")
	return true


func find_nearest_enemy(radius: float) -> Actor:
	if _forced_target != null and is_instance_valid(_forced_target) and can_damage(_forced_target):
		return _forced_target

	var best: Actor = null
	var best_edge_distance := radius

	for group_name in _get_enemy_search_groups():
		for node in get_tree().get_nodes_in_group(group_name):
			var actor := node as Actor
			if actor == null or not can_damage(actor):
				continue

			var edge_distance := maxf(0.0, global_position.distance_to(actor.global_position) - actor.get_hit_radius())
			if edge_distance <= radius and edge_distance < best_edge_distance:
				best = actor
				best_edge_distance = edge_distance

	return best


func _get_enemy_search_groups() -> Array:
	match team:
		GameCatalog.TEAM_PLAYER:
			return ["team_enemy", "team_neutral"]
		GameCatalog.TEAM_ENEMY:
			return ["team_player", "team_neutral"]
		GameCatalog.TEAM_NEUTRAL:
			return ["team_player", "team_enemy"]
		_:
			return ["combat_actor"]


func apply_move_speed_multiplier(multiplier: float, duration: float) -> void:
	_move_speed_multiplier = multiplier
	_move_speed_timer = maxf(_move_speed_timer, duration)
	queue_redraw()


func apply_damage_reduction(multiplier: float, duration: float) -> void:
	_incoming_damage_multiplier = multiplier
	_incoming_damage_timer = maxf(_incoming_damage_timer, duration)
	queue_redraw()


func apply_vulnerability(multiplier: float, duration: float) -> void:
	_damage_taken_multiplier = multiplier
	_damage_taken_timer = maxf(_damage_taken_timer, duration)
	queue_redraw()


func apply_attack_damage_multiplier(multiplier: float, duration: float) -> void:
	_attack_damage_multiplier = multiplier
	_attack_damage_timer = maxf(_attack_damage_timer, duration)
	queue_redraw()


func force_target(target: Actor, duration: float) -> void:
	if target == null or not is_instance_valid(target):
		return

	_forced_target = target
	_forced_target_timer = maxf(_forced_target_timer, duration)
	queue_redraw()


func pull_toward(point: Vector2, distance: float) -> void:
	global_position = global_position.move_toward(point, distance)


func get_move_speed() -> float:
	return _stat("move_speed") * _move_speed_multiplier


func trigger_attack_visual(target_position: Vector2) -> void:
	var direction := global_position.direction_to(target_position)
	if direction != Vector2.ZERO:
		_attack_visual_direction = direction
		if absf(direction.x) > 0.05:
			_visual_facing_sign = 1.0 if direction.x > 0.0 else -1.0

	_attack_visual_timer = ATTACK_VISUAL_DURATION
	queue_redraw()


func trigger_cast_visual(color: Color, ability_id: String = "") -> void:
	_cast_visual_color = color
	_cast_visual_id = ability_id
	_cast_visual_timer = CAST_VISUAL_DURATION
	queue_redraw()


func get_visual_time() -> float:
	return _visual_time


func get_visual_move_amount() -> float:
	var maximum_speed := maxf(_stat("move_speed"), 1.0)
	return clampf(velocity.length() / maximum_speed, 0.0, 1.0)


func get_visual_attack_amount() -> float:
	if ATTACK_VISUAL_DURATION <= 0.0:
		return 0.0

	return clampf(_attack_visual_timer / ATTACK_VISUAL_DURATION, 0.0, 1.0)


func get_visual_attack_direction() -> Vector2:
	return _attack_visual_direction


func get_visual_cast_amount() -> float:
	if CAST_VISUAL_DURATION <= 0.0:
		return 0.0

	return clampf(_cast_visual_timer / CAST_VISUAL_DURATION, 0.0, 1.0)


func get_visual_facing_sign() -> float:
	return _visual_facing_sign


func get_hit_radius() -> float:
	return maxf(draw_radius, 8.0)


func get_pick_radius() -> float:
	return maxf(get_hit_radius() * 2.2, draw_radius + 16.0)


func set_selected(selected: bool) -> void:
	if is_selected == selected:
		return

	is_selected = selected
	queue_redraw()


func _spawn_attack_effect(target: Actor) -> void:
	var effect_parent: Node = get_tree().current_scene
	if effect_parent == null:
		effect_parent = get_parent()
	if effect_parent == null:
		return

	var start_position: Vector2 = global_position
	var end_position: Vector2 = target.global_position
	var is_ranged_attack := _stat("attack_range") > maxf(get_hit_radius() + target.get_hit_radius() + 44.0, 82.0)
	var effect: AttackEffect = AttackEffect.new()
	effect_parent.add_child(effect)
	effect.configure_attack(start_position, end_position, _get_attack_effect_color(), is_ranged_attack, target.get_hit_radius() + 8.0, _get_projectile_kind(is_ranged_attack))


func _get_attack_effect_color() -> Color:
	if is_in_group("tower"):
		return Color(1.0, 0.72, 0.24)
	if _stat("attack_range") > 90.0:
		return Color(0.56, 0.82, 1.0) if team == GameCatalog.TEAM_PLAYER else Color(1.0, 0.42, 0.32)

	return Color(1.0, 0.88, 0.42)


func _get_projectile_kind(is_ranged_attack: bool) -> String:
	if not is_ranged_attack:
		return "slash"
	if is_in_group("tower"):
		return "cannon"

	return "bolt"


func _draw() -> void:
	var team_color := _get_team_color()
	_draw_selection_ring()
	_draw_shadow()
	_draw_unit_body(team_color)
	_draw_cast_visual()
	_draw_health_bar()


func _get_team_color() -> Color:
	match team:
		GameCatalog.TEAM_PLAYER:
			return Color(0.25, 0.78, 0.38)
		GameCatalog.TEAM_ENEMY:
			return Color(0.88, 0.24, 0.22)
		_:
			return Color(0.85, 0.72, 0.32)


func _draw_shadow() -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(-draw_radius * 1.35, draw_radius * 0.72),
		Vector2(-draw_radius * 0.55, draw_radius * 0.38),
		Vector2(draw_radius * 0.65, draw_radius * 0.38),
		Vector2(draw_radius * 1.35, draw_radius * 0.72),
		Vector2(draw_radius * 0.55, draw_radius * 1.02),
		Vector2(-draw_radius * 0.65, draw_radius * 1.02),
	]), Color(0.02, 0.025, 0.02, 0.42))


func _draw_selection_ring() -> void:
	if not is_selected:
		return

	draw_arc(Vector2.ZERO, draw_radius + 10.0, 0.0, TAU, 40, Color(1.0, 0.92, 0.42, 0.92), 3.0)
	draw_arc(Vector2.ZERO, draw_radius + 13.0, 0.0, TAU, 40, Color(0.12, 0.08, 0.03, 0.55), 1.0)


func _draw_unit_body(team_color: Color) -> void:
	var armor := team_color.darkened(0.28)
	var highlight := team_color.lightened(0.18)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, -draw_radius * 1.15),
		Vector2(draw_radius * 0.95, -draw_radius * 0.25),
		Vector2(draw_radius * 0.70, draw_radius * 0.78),
		Vector2(0.0, draw_radius * 1.08),
		Vector2(-draw_radius * 0.70, draw_radius * 0.78),
		Vector2(-draw_radius * 0.95, -draw_radius * 0.25),
	]), armor)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, -draw_radius * 1.0),
		Vector2(draw_radius * 0.62, -draw_radius * 0.18),
		Vector2(draw_radius * 0.42, draw_radius * 0.52),
		Vector2(0.0, draw_radius * 0.76),
		Vector2(-draw_radius * 0.42, draw_radius * 0.52),
		Vector2(-draw_radius * 0.62, -draw_radius * 0.18),
	]), team_color)
	draw_circle(Vector2(0.0, -draw_radius * 0.66), draw_radius * 0.42, highlight)
	draw_arc(Vector2.ZERO, draw_radius + 1.0, 0.0, TAU, 24, Color(0.02, 0.015, 0.01), 1.5)


func _draw_health_bar() -> void:
	var maximum := maxf(_stat("max_health"), 1.0)
	var percentage := clampf(health / maximum, 0.0, 1.0)
	var width := maxf(draw_radius * 2.5, 30.0)
	var y := -_get_health_bar_offset()
	draw_rect(Rect2(Vector2(-width * 0.5, y), Vector2(width, 5.0)), Color(0.03, 0.025, 0.02, 0.85))
	draw_rect(Rect2(Vector2(-width * 0.5 + 1.0, y + 1.0), Vector2((width - 2.0) * percentage, 3.0)), _get_team_color().lightened(0.2))

	if _damage_taken_multiplier > 1.0:
		draw_arc(Vector2.ZERO, draw_radius + 6.0, 0.0, TAU, 24, Color(1.0, 0.85, 0.20, 0.8), 2.0)
	if _move_speed_multiplier <= 0.05:
		draw_arc(Vector2.ZERO, draw_radius + 9.0, 0.0, TAU, 24, Color(0.55, 0.85, 1.0, 0.9), 2.0)
	elif _move_speed_multiplier < 1.0:
		draw_arc(Vector2.ZERO, draw_radius + 8.0, 0.0, TAU, 24, Color(0.32, 0.58, 1.0, 0.7), 2.0)
	elif _move_speed_multiplier > 1.0:
		draw_arc(Vector2.ZERO, draw_radius + 8.0, 0.0, TAU, 24, Color(0.36, 1.0, 0.45, 0.7), 2.0)


func _get_health_bar_offset() -> float:
	return draw_radius + 16.0


func _draw_cast_visual() -> void:
	var cast_amount := get_visual_cast_amount()
	if cast_amount <= 0.0:
		return

	var progress := 1.0 - cast_amount
	var alpha := cast_amount
	var pulse_radius := get_hit_radius() * (1.0 + progress * 1.65)
	var color := Color(_cast_visual_color.r, _cast_visual_color.g, _cast_visual_color.b, alpha)
	draw_arc(Vector2.ZERO, pulse_radius, 0.0, TAU, 32, color, 3.0)
	draw_arc(Vector2.ZERO, pulse_radius * 0.62, progress * TAU, progress * TAU + PI * 1.2, 18, Color(1.0, 0.95, 0.65, alpha), 2.0)

	for i in range(4):
		var angle := progress * TAU + float(i) * PI * 0.5
		var p := Vector2.RIGHT.rotated(angle) * (pulse_radius * 0.72)
		draw_rect(Rect2(p - Vector2(2.0, 2.0), Vector2(4.0, 4.0)), color)


func _sync_hitbox() -> void:
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision == null:
		collision = CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		add_child(collision)

	if collision.shape != null and not (collision.shape is CircleShape2D):
		return

	if collision.shape == null:
		collision.shape = CircleShape2D.new()

	if not collision.has_meta("local_circle_shape"):
		collision.shape = collision.shape.duplicate()
		collision.set_meta("local_circle_shape", true)

	var circle := collision.shape as CircleShape2D
	circle.radius = get_hit_radius()


func _die(killer: Actor) -> void:
	set_physics_process(false)
	died.emit(self, killer)
	queue_free()


func _tick_health_regen(delta: float) -> void:
	if not is_alive() or delta <= 0.0:
		return

	var regen := _stat("health_regen")
	if regen <= 0.0 or health >= _stat("max_health"):
		return

	heal(regen * delta)


func _tick_statuses(delta: float) -> void:
	if _move_speed_timer > 0.0:
		_move_speed_timer = maxf(0.0, _move_speed_timer - delta)
		if _move_speed_timer <= 0.0:
			_move_speed_multiplier = 1.0
			queue_redraw()

	if _incoming_damage_timer > 0.0:
		_incoming_damage_timer = maxf(0.0, _incoming_damage_timer - delta)
		if _incoming_damage_timer <= 0.0:
			_incoming_damage_multiplier = 1.0
			queue_redraw()

	if _damage_taken_timer > 0.0:
		_damage_taken_timer = maxf(0.0, _damage_taken_timer - delta)
		if _damage_taken_timer <= 0.0:
			_damage_taken_multiplier = 1.0
			queue_redraw()

	if _attack_damage_timer > 0.0:
		_attack_damage_timer = maxf(0.0, _attack_damage_timer - delta)
		if _attack_damage_timer <= 0.0:
			_attack_damage_multiplier = 1.0
			queue_redraw()

	if _forced_target_timer > 0.0:
		_forced_target_timer = maxf(0.0, _forced_target_timer - delta)
		if _forced_target_timer <= 0.0:
			_forced_target = null
			queue_redraw()


func _clear_statuses() -> void:
	_move_speed_multiplier = 1.0
	_move_speed_timer = 0.0
	_incoming_damage_multiplier = 1.0
	_incoming_damage_timer = 0.0
	_damage_taken_multiplier = 1.0
	_damage_taken_timer = 0.0
	_attack_damage_multiplier = 1.0
	_attack_damage_timer = 0.0
	_forced_target = null
	_forced_target_timer = 0.0


func refresh_groups() -> void:
	add_to_group("combat_actor")

	for group_name in ["team_neutral", "team_player", "team_enemy"]:
		if is_in_group(group_name):
			remove_from_group(group_name)

	add_to_group("team_%s" % team)


func _stat(key: String) -> float:
	return float(stats.get(key, 0.0))
