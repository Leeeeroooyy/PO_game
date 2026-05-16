class_name AbilityEffect
extends Node2D

const DURATION := 0.55

var _origin := Vector2.ZERO
var _target := Vector2.ZERO
var _radius := 48.0
var _effect_color := Color.WHITE
var _targeting := "area"
var _ability_id := ""
var _timer := DURATION


func configure_ability(origin: Vector2, target: Vector2, radius: float, color: Color, targeting: String, ability_id: String) -> void:
	_origin = origin
	_target = target
	_radius = maxf(radius, 34.0)
	_effect_color = color
	_targeting = targeting
	_ability_id = ability_id
	_timer = DURATION
	z_index = 260
	queue_redraw()


func _process(delta: float) -> void:
	_timer = maxf(0.0, _timer - delta)
	queue_redraw()

	if _timer <= 0.0:
		queue_free()


func _draw() -> void:
	var progress := 1.0 - (_timer / DURATION)
	var alpha := 1.0 - progress

	match _targeting:
		"direction":
			_draw_direction(progress, alpha)
		"self":
			_draw_self(progress, alpha)
		"point":
			_draw_point(progress, alpha)
		"single_target":
			_draw_single_target(progress, alpha)
		_:
			_draw_area(progress, alpha)


func _draw_direction(progress: float, alpha: float) -> void:
	var color: Color = _faded(alpha)
	var end: Vector2 = _origin.lerp(_target, clampf(progress * 1.35, 0.0, 1.0))
	var width := 8.0 if _ability_id == "piercing_arrow" else 12.0
	draw_line(_origin, end, Color(0.02, 0.02, 0.02, alpha * 0.6), width + 4.0)
	draw_line(_origin, end, color, width)
	draw_circle(end, width * 0.55, Color(1.0, 0.95, 0.62, alpha))


func _draw_self(progress: float, alpha: float) -> void:
	var color: Color = _faded(alpha)
	var radius := _radius * (0.45 + progress * 0.95)
	draw_arc(_origin, radius, 0.0, TAU, 42, color, 4.0)
	draw_arc(_origin, radius * 0.62, progress * TAU, progress * TAU + PI * 1.35, 24, Color(1.0, 0.95, 0.65, alpha), 3.0)


func _draw_area(progress: float, alpha: float) -> void:
	var color: Color = _faded(alpha)
	var radius := _radius * (0.35 + progress * 0.75)
	draw_circle(_target, radius, Color(color.r, color.g, color.b, alpha * 0.12))
	draw_arc(_target, radius, 0.0, TAU, 48, color, 4.0)
	for i in range(6):
		var angle := progress * TAU + float(i) * TAU / 6.0
		var outer: Vector2 = _target + Vector2.RIGHT.rotated(angle) * (radius + 10.0)
		var inner: Vector2 = _target + Vector2.RIGHT.rotated(angle) * (radius - 8.0)
		draw_line(inner, outer, Color(1.0, 0.95, 0.62, alpha * 0.85), 2.0)


func _draw_point(progress: float, alpha: float) -> void:
	var color: Color = _faded(alpha)
	var marker_size := 12.0 + progress * 16.0
	draw_line(_origin, _target, Color(color.r, color.g, color.b, alpha * 0.42), 3.0)
	draw_arc(_target, marker_size, 0.0, TAU, 28, color, 3.0)
	draw_line(_target + Vector2(-marker_size, 0.0), _target + Vector2(marker_size, 0.0), color, 2.0)
	draw_line(_target + Vector2(0.0, -marker_size), _target + Vector2(0.0, marker_size), color, 2.0)


func _draw_single_target(progress: float, alpha: float) -> void:
	var color: Color = _faded(alpha)
	var pulse := 10.0 + sin(progress * PI) * 10.0
	draw_line(_origin, _target, Color(color.r, color.g, color.b, alpha * 0.72), 4.0)
	draw_arc(_target, _radius * 0.42 + pulse, 0.0, TAU, 32, color, 3.0)
	draw_colored_polygon(PackedVector2Array([
		_target + Vector2(0.0, -12.0 - pulse * 0.35),
		_target + Vector2(12.0 + pulse * 0.35, 0.0),
		_target + Vector2(0.0, 12.0 + pulse * 0.35),
		_target + Vector2(-12.0 - pulse * 0.35, 0.0),
	]), Color(color.r, color.g, color.b, alpha * 0.22))


func _faded(alpha: float) -> Color:
	return Color(_effect_color.r, _effect_color.g, _effect_color.b, alpha)
