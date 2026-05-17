class_name AttackEffect
extends Node2D

const RANGED_DURATION := 0.34
const MELEE_DURATION := 0.22

var _start_position := Vector2.ZERO
var _end_position := Vector2.ZERO
var _effect_color := Color.WHITE
var _duration := RANGED_DURATION
var _timer := RANGED_DURATION
var _is_ranged := true
var _impact_radius := 12.0
var _projectile_kind := "bolt"


func configure_attack(start_position: Vector2, end_position: Vector2, color: Color, is_ranged: bool, impact_radius: float, projectile_kind := "bolt") -> void:
	_start_position = start_position
	_end_position = end_position
	_effect_color = color
	_is_ranged = is_ranged
	_impact_radius = maxf(impact_radius, 8.0)
	_projectile_kind = projectile_kind
	_duration = RANGED_DURATION if _is_ranged else MELEE_DURATION
	_timer = _duration
	z_index = 300
	queue_redraw()


func _process(delta: float) -> void:
	_timer = maxf(0.0, _timer - delta)
	queue_redraw()

	if _timer <= 0.0:
		queue_free()


func _draw() -> void:
	var progress := 1.0 - (_timer / _duration)
	var alpha := 1.0 - progress

	if _is_ranged:
		_draw_projectile(progress, alpha)
	else:
		_draw_melee_swing(progress, alpha)


func _draw_projectile(progress: float, alpha: float) -> void:
	var t := clampf(progress * 1.18, 0.0, 1.0)
	var eased_t := t * t * (3.0 - 2.0 * t)
	var direction := _start_position.direction_to(_end_position)
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	var projectile_position: Vector2 = _start_position.lerp(_end_position, eased_t)
	var trail_position: Vector2 = _start_position.lerp(_end_position, clampf(eased_t - 0.18, 0.0, 1.0))
	var color := Color(_effect_color.r, _effect_color.g, _effect_color.b, alpha)
	var glow := Color(1.0, 0.92, 0.45, alpha * 0.85)
	var shadow := Color(0.02, 0.015, 0.01, alpha * 0.65)

	draw_line(trail_position, projectile_position, shadow, 7.0)
	draw_line(trail_position, projectile_position, Color(color.r, color.g, color.b, alpha * 0.78), 3.0)
	_draw_projectile_body(projectile_position, direction, color, glow, shadow, alpha)

	if progress > 0.72:
		var impact_alpha := clampf((progress - 0.72) / 0.28, 0.0, 1.0)
		draw_arc(_end_position, _impact_radius * impact_alpha, 0.0, TAU, 20, Color(glow.r, glow.g, glow.b, alpha), 2.4)
		for i in range(4):
			var shard := Vector2.RIGHT.rotated(float(i) * PI * 0.5) * _impact_radius * impact_alpha * 0.62
			draw_rect(Rect2(_end_position + shard - Vector2(2.0, 2.0), Vector2(4.0, 4.0)), Color(glow.r, glow.g, glow.b, alpha * 0.8))


func _draw_projectile_body(position: Vector2, direction: Vector2, color: Color, glow: Color, shadow: Color, alpha: float) -> void:
	var side := direction.orthogonal()
	match _projectile_kind:
		"arrow":
			var points := PackedVector2Array([
				position + direction * 10.0,
				position - direction * 8.0 + side * 3.0,
				position - direction * 3.0,
				position - direction * 8.0 - side * 3.0,
			])
			draw_colored_polygon(_offset_points(points, Vector2(2.0, 2.0)), shadow)
			draw_colored_polygon(points, glow)
			draw_line(position - direction * 11.0, position - direction * 2.0, Color(0.45, 0.28, 0.12, alpha), 2.0)
			draw_line(position - direction * 13.0 - side * 3.0, position - direction * 8.0, Color(0.86, 0.76, 0.46, alpha), 1.4)
			draw_line(position - direction * 13.0 + side * 3.0, position - direction * 8.0, Color(0.86, 0.76, 0.46, alpha), 1.4)
		"orb":
			draw_circle(position + Vector2(2.0, 2.0), 8.0, shadow)
			draw_circle(position, 7.5, Color(color.r, color.g, color.b, alpha))
			draw_circle(position, 4.0, Color(0.82, 0.95, 1.0, alpha))
			draw_rect(Rect2(position - direction * 8.0 - side * 2.0 - Vector2(2.0, 2.0), Vector2(4.0, 4.0)), Color(0.96, 1.0, 1.0, alpha * 0.76))
		"stone":
			draw_rect(Rect2(position - Vector2(5.0, 5.0) + Vector2(2.0, 2.0), Vector2(10.0, 10.0)), shadow)
			draw_rect(Rect2(position - Vector2(5.0, 5.0), Vector2(10.0, 10.0)), Color(0.45, 0.42, 0.34, alpha))
			draw_rect(Rect2(position - Vector2(2.0, 4.0), Vector2(4.0, 3.0)), Color(0.72, 0.68, 0.54, alpha))
		"spit":
			draw_circle(position + Vector2(2.0, 2.0), 6.0, shadow)
			draw_circle(position, 6.0, Color(0.58, 1.0, 0.24, alpha))
			draw_circle(position - direction * 5.0, 3.0, Color(0.82, 1.0, 0.46, alpha * 0.8))
		"cannon":
			draw_circle(position + Vector2(2.0, 2.0), 7.0, shadow)
			draw_circle(position, 7.0, Color(0.18, 0.16, 0.13, alpha))
			draw_circle(position - direction * 3.0 - side * 2.0, 2.0, Color(0.84, 0.52, 0.22, alpha))
		"note":
			draw_circle(position + Vector2(2.0, 2.0), 6.0, shadow)
			draw_circle(position - side * 2.0, 4.8, Color(0.44, 0.88, 1.0, alpha))
			draw_line(position + side * 2.0, position + side * 2.0 - direction * 11.0, Color(0.95, 0.92, 1.0, alpha), 2.0)
			draw_line(position + side * 2.0 - direction * 11.0, position + side * 8.0 - direction * 8.0, Color(0.95, 0.92, 1.0, alpha), 2.0)
		"thorn":
			var thorn_points := PackedVector2Array([
				position + direction * 11.0,
				position - direction * 6.0 + side * 4.0,
				position - direction * 2.0,
				position - direction * 6.0 - side * 4.0,
			])
			draw_colored_polygon(_offset_points(thorn_points, Vector2(2.0, 2.0)), shadow)
			draw_colored_polygon(thorn_points, Color(0.35, 0.92, 0.28, alpha))
			draw_line(position - direction * 7.0, position + direction * 8.0, Color(0.86, 1.0, 0.50, alpha), 1.6)
		_:
			draw_rect(Rect2(position - Vector2(4.0, 4.0) + Vector2(2.0, 2.0), Vector2(8.0, 8.0)), shadow)
			draw_rect(Rect2(position - Vector2(4.0, 4.0), Vector2(8.0, 8.0)), color)
			draw_rect(Rect2(position - Vector2(2.0, 2.0), Vector2(4.0, 4.0)), glow)


func _offset_points(points: PackedVector2Array, offset: Vector2) -> PackedVector2Array:
	var shifted := PackedVector2Array()
	for point in points:
		shifted.append(point + offset)
	return shifted


func _draw_melee_swing(progress: float, alpha: float) -> void:
	var direction: Vector2 = _start_position.direction_to(_end_position)
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT

	var swing_angle := direction.angle()
	var radius := _impact_radius + progress * 10.0
	var color := Color(_effect_color.r, _effect_color.g, _effect_color.b, alpha)
	var bright := Color(1.0, 0.88, 0.36, alpha)
	var shadow := Color(0.02, 0.015, 0.01, alpha * 0.7)

	draw_arc(_end_position, radius + 2.0, swing_angle - 1.05, swing_angle + 1.05, 22, shadow, 6.0)
	draw_arc(_end_position, radius, swing_angle - 1.05, swing_angle + 1.05, 22, color, 4.0)
	draw_line(_end_position - direction.orthogonal() * 7.0, _end_position + direction.orthogonal() * 7.0, bright, 2.0)
