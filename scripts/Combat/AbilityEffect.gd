class_name AbilityEffect
extends Node2D

const DURATION := 0.85

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

	match _ability_id:
		"fire_sphere":
			_draw_meteor(progress, alpha)
			return
		"hail_of_arrows":
			_draw_arrow_rain(progress, alpha)
			return
		"whirlwind", "berserkers_call":
			_draw_spin_burst(progress, alpha)
			return
		"healing_melody", "battle_cry", "blood_rage", "water_sphere", "nature_dash":
			_draw_buff_pulse(progress, alpha)
			return
		"thorns", "swamp_ritual":
			_draw_ground_growth(progress, alpha)
			return
		"void_sphere":
			_draw_void_pull(progress, alpha)
			return
		"sticky_tongue", "snake_charmer", "mark_prey":
			_draw_single_target(progress, alpha)
			return

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
	for i in range(4):
		var t := clampf(progress - float(i) * 0.08, 0.0, 1.0)
		var point: Vector2 = _origin.lerp(_target, t)
		draw_rect(Rect2(point - Vector2(3.0, 3.0), Vector2(6.0, 6.0)), Color(1.0, 0.95, 0.62, alpha * (1.0 - float(i) * 0.18)))
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


func _draw_meteor(progress: float, alpha: float) -> void:
	var color: Color = _faded(alpha)
	var start := _target + Vector2(-90.0, -130.0)
	var meteor_position: Vector2 = start.lerp(_target, clampf(progress * 1.35, 0.0, 1.0))
	var impact := clampf((progress - 0.58) / 0.42, 0.0, 1.0)
	draw_line(start, meteor_position, Color(0.20, 0.04, 0.01, alpha * 0.9), 10.0)
	draw_line(start, meteor_position, color, 6.0)
	draw_rect(Rect2(meteor_position - Vector2(7.0, 7.0), Vector2(14.0, 14.0)), Color(1.0, 0.78, 0.24, alpha))
	if impact > 0.0:
		var radius := _radius * impact
		draw_circle(_target, radius, Color(color.r, color.g, color.b, alpha * 0.16))
		draw_arc(_target, radius, 0.0, TAU, 48, color, 5.0)
		for i in range(8):
			var direction := Vector2.RIGHT.rotated(float(i) * TAU / 8.0)
			draw_rect(Rect2(_target + direction * radius * 0.72 - Vector2(3.0, 3.0), Vector2(6.0, 6.0)), Color(1.0, 0.86, 0.28, alpha))


func _draw_arrow_rain(progress: float, alpha: float) -> void:
	var color: Color = _faded(alpha)
	draw_arc(_target, _radius, 0.0, TAU, 52, color, 3.0)
	for i in range(9):
		var lane := float(i - 4) * _radius * 0.18
		var fall := fposmod(progress * 1.6 + float(i) * 0.13, 1.0)
		var start := _target + Vector2(lane, -_radius * 0.9)
		var end := start + Vector2(18.0, _radius * 1.8 * fall)
		draw_line(end - Vector2(10.0, 22.0), end, Color(0.95, 0.82, 0.34, alpha), 3.0)
		draw_rect(Rect2(end - Vector2(2.0, 2.0), Vector2(4.0, 4.0)), color)


func _draw_spin_burst(progress: float, alpha: float) -> void:
	var color: Color = _faded(alpha)
	var radius := _radius * (0.42 + progress * 0.42)
	for i in range(5):
		var start_angle := progress * TAU * 2.0 + float(i) * TAU / 5.0
		draw_arc(_origin, radius + float(i) * 3.0, start_angle, start_angle + PI * 0.72, 18, color, 4.0)
	draw_arc(_origin, radius * 0.55, 0.0, TAU, 36, Color(1.0, 0.92, 0.46, alpha), 2.0)


func _draw_buff_pulse(progress: float, alpha: float) -> void:
	var color: Color = _faded(alpha)
	var radius := _radius * (0.35 + progress * 0.95)
	draw_circle(_origin, radius, Color(color.r, color.g, color.b, alpha * 0.10))
	draw_arc(_origin, radius, 0.0, TAU, 42, color, 4.0)
	for i in range(6):
		var angle := -progress * TAU + float(i) * TAU / 6.0
		var point := _origin + Vector2.RIGHT.rotated(angle) * radius * 0.66
		draw_rect(Rect2(point - Vector2(3.0, 3.0), Vector2(6.0, 6.0)), Color(1.0, 0.95, 0.62, alpha))


func _draw_ground_growth(progress: float, alpha: float) -> void:
	var color: Color = _faded(alpha)
	var radius := _radius * (0.45 + progress * 0.45)
	draw_circle(_target, radius, Color(color.r, color.g, color.b, alpha * 0.12))
	draw_arc(_target, radius, 0.0, TAU, 48, color, 3.5)
	for i in range(10):
		var angle := float(i) * TAU / 10.0 + progress * 0.45
		var base := _target + Vector2.RIGHT.rotated(angle) * radius * (0.35 + float(i % 3) * 0.18)
		var tip := base + Vector2.RIGHT.rotated(angle) * (12.0 + progress * 12.0)
		draw_line(base, tip, Color(0.55, 1.0, 0.36, alpha), 3.0)


func _draw_void_pull(progress: float, alpha: float) -> void:
	var color: Color = _faded(alpha)
	var radius := _radius * (1.0 - progress * 0.55)
	draw_circle(_target, radius, Color(color.r, color.g, color.b, alpha * 0.14))
	draw_arc(_target, radius, progress * TAU * 2.0, progress * TAU * 2.0 + PI * 1.65, 42, color, 5.0)
	for i in range(8):
		var angle := float(i) * TAU / 8.0
		var outer := _target + Vector2.RIGHT.rotated(angle) * _radius
		var inner := _target + Vector2.RIGHT.rotated(angle + progress) * radius * 0.25
		draw_line(outer, inner, Color(color.r, color.g, color.b, alpha * 0.8), 2.0)


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
