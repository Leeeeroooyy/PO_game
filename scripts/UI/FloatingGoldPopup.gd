class_name FloatingGoldPopup
extends Label

const DURATION := 1.05
const RISE_DISTANCE := 44.0
const POP_WIDTH := 92.0
const POP_HEIGHT := 28.0

var _timer := DURATION
var _start_position := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	custom_minimum_size = Vector2(POP_WIDTH, POP_HEIGHT)
	size = custom_minimum_size
	pivot_offset = custom_minimum_size * 0.5
	add_theme_font_size_override("font_size", 19)
	add_theme_color_override("font_color", Color(1.0, 0.82, 0.24))
	add_theme_color_override("font_shadow_color", Color(0.03, 0.02, 0.0, 0.95))
	add_theme_constant_override("shadow_offset_x", 2)
	add_theme_constant_override("shadow_offset_y", 2)


func configure(amount: int, screen_position: Vector2) -> void:
	text = "+%dg" % amount
	_start_position = screen_position - Vector2(POP_WIDTH * 0.5, POP_HEIGHT * 0.5)
	position = _start_position
	_timer = DURATION


func _process(delta: float) -> void:
	_timer = maxf(0.0, _timer - delta)
	var progress := 1.0 - (_timer / DURATION)
	position = _start_position + Vector2(0.0, -RISE_DISTANCE * progress)
	modulate.a = 1.0 - maxf(0.0, progress - 0.55) / 0.45
	scale = Vector2.ONE * (1.0 + sin(progress * PI) * 0.12)

	if _timer <= 0.0:
		queue_free()
