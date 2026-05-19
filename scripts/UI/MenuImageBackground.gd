class_name MenuImageBackground
extends Control

const BACKGROUND_PATHS := [
	"res://assets/ui/menu_background.png",
	"res://assets/ui/menu_background.jpg",
	"res://assets/ui/menu_background.jpeg",
	"res://assets/ui/menu_background.webp",
]

var _texture: Texture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_texture = _load_background_texture()
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	if _texture == null:
		return

	var texture_size := _texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return

	var scale := maxf(size.x / texture_size.x, size.y / texture_size.y)
	var draw_size := texture_size * scale
	var draw_position := (size - draw_size) * 0.5
	draw_texture_rect(_texture, Rect2(draw_position, draw_size), false)


func _load_background_texture() -> Texture2D:
	for path in BACKGROUND_PATHS:
		if ResourceLoader.exists(path):
			return load(path) as Texture2D

	return null
