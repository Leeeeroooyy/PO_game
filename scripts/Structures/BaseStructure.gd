class_name BaseStructure
extends Actor

@export var size := Vector2(115.0, 125.0)


func configure_base(new_team: String, position: Vector2) -> void:
	global_position = position
	configure(new_team, GameCatalog.LANE_MIDDLE, GameCatalog.stats(2600.0, 0.0, 0.0, 0.0, 1.0))


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	velocity = Vector2.ZERO


func get_hit_radius() -> float:
	return maxf(size.x, size.y) * 0.5


func get_pick_radius() -> float:
	return maxf(size.x, size.y) * 0.62


func _draw() -> void:
	var rect := Rect2(-size / 2.0, size)
	var team_color := _get_team_color()
	if is_selected:
		draw_rect(rect.grow(9.0), Color(1.0, 0.92, 0.42, 0.92), false, 3.0)

	draw_colored_polygon(PackedVector2Array([
		Vector2(-size.x * 0.62, size.y * 0.45),
		Vector2(0.0, size.y * 0.68),
		Vector2(size.x * 0.62, size.y * 0.45),
		Vector2(size.x * 0.46, -size.y * 0.28),
		Vector2(0.0, -size.y * 0.68),
		Vector2(-size.x * 0.46, -size.y * 0.28),
	]), Color(0.16, 0.14, 0.11))
	draw_rect(rect, Color(0.38, 0.34, 0.27))
	draw_rect(rect.grow(-8.0), team_color.darkened(0.18))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-size.x * 0.35, -size.y * 0.1),
		Vector2(0.0, -size.y * 0.50),
		Vector2(size.x * 0.35, -size.y * 0.1),
		Vector2(size.x * 0.24, size.y * 0.34),
		Vector2(-size.x * 0.24, size.y * 0.34),
	]), team_color.lightened(0.12))
	draw_rect(rect, Color.BLACK, false, 2.5)
	_draw_health_bar()
