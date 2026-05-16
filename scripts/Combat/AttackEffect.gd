class_name AttackEffect
extends Node2D

const RANGED_DURATION := 0.22
const MELEE_DURATION := 0.16

var _start_position := Vector2.ZERO
var _end_position := Vector2.ZERO
var _effect_color := Color.WHITE
var _duration := RANGED_DURATION
var _timer := RANGED_DURATION
var _is_ranged := true
var _impact_radius := 12.0


func configure_attack(start_position: Vector2, end_position: Vector2, color: Color, is_ranged: bool, impact_radius: float) -> void:
	_start_position = start_position
	_end_position = end_position
	_effect_color = color
	_is_ranged = is_ranged
	_impact_radius = maxf(impact_radius, 8.0)
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
	var projectile_position: Vector2 = _start_position.lerp(_end_position, clampf(progress * 1.25, 0.0, 1.0))
	var trail_position: Vector2 = _start_position.lerp(_end_position, clampf(progress * 1.25 - 0.24, 0.0, 1.0))
	var color := Color(_effect_color.r, _effect_color.g, _effect_color.b, alpha)
	var glow := Color(1.0, 0.92, 0.45, alpha * 0.85)
	var shadow := Color(0.02, 0.015, 0.01, alpha * 0.65)

	draw_line(trail_position, projectile_position, shadow, 7.0)
	draw_line(trail_position, projectile_position, color, 4.0)
	draw_circle(projectile_position, 4.5, glow)

	if progress > 0.72:
		var impact_alpha := clampf((progress - 0.72) / 0.28, 0.0, 1.0)
		draw_arc(_end_position, _impact_radius * impact_alpha, 0.0, TAU, 20, Color(glow.r, glow.g, glow.b, alpha), 2.0)


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
