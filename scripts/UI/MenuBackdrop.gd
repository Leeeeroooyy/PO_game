class_name MenuBackdrop
extends Control

@export var accent_color := Color(0.86, 0.58, 0.22)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	if _has_image_background():
		return

	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color(0.035, 0.045, 0.048))
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, size.y * 0.46)), Color(0.065, 0.085, 0.082, 0.92))
	draw_rect(Rect2(Vector2(0.0, size.y * 0.46), Vector2(size.x, size.y * 0.54)), Color(0.028, 0.032, 0.036, 0.98))

	var lane_color := Color(accent_color.r, accent_color.g, accent_color.b, 0.18)
	var shadow_color := Color(0.0, 0.0, 0.0, 0.26)
	for i in range(3):
		var t := float(i + 1) / 4.0
		var start := Vector2(-80.0, size.y * (0.22 + t * 0.34))
		var end := Vector2(size.x + 80.0, size.y * (0.06 + t * 0.62))
		draw_line(start + Vector2(0.0, 7.0), end + Vector2(0.0, 7.0), shadow_color, 12.0, true)
		draw_line(start, end, lane_color, 5.0, true)

	for i in range(9):
		var x := float(i) / 8.0 * size.x
		var height := 72.0 + float((i * 37) % 82)
		var tower_rect := Rect2(Vector2(x - 24.0, size.y - height - 28.0), Vector2(48.0, height))
		draw_rect(tower_rect, Color(0.014, 0.017, 0.018, 0.52))
		draw_rect(Rect2(tower_rect.position + Vector2(8.0, -18.0), Vector2(32.0, 20.0)), Color(0.014, 0.017, 0.018, 0.58))

	draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, 0.18))


func _has_image_background() -> bool:
	for path in MenuImageBackground.BACKGROUND_PATHS:
		if ResourceLoader.exists(path):
			return true

	return false
