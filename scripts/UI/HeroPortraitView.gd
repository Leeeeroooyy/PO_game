class_name HeroPortraitView
extends Control

const SPRITE_ATLAS: Texture2D = preload("res://assets/sprites/generated/moba_units_atlas_pixel.png")
const STRUCTURE_ATLAS: Texture2D = preload("res://assets/sprites/generated/moba_towers_atlas_pixel.png")
const ATLAS_COLUMNS := 4.0
const ATLAS_ROWS := 3.0
const STRUCTURE_SOURCE_RECTS := [
	[
		Rect2(86.0, 173.0, 232.0, 301.0),
		Rect2(387.0, 136.0, 235.0, 342.0),
		Rect2(714.0, 122.0, 258.0, 357.0),
		Rect2(1029.0, 140.0, 346.0, 343.0),
	],
	[
		Rect2(71.0, 594.0, 237.0, 319.0),
		Rect2(377.0, 556.0, 255.0, 362.0),
		Rect2(704.0, 542.0, 275.0, 381.0),
		Rect2(1008.0, 567.0, 377.0, 363.0),
	],
]

var hero_id := GameCatalog.DEFAULT_HERO_ID
var hero_color := Color(0.34, 0.78, 0.36)
var portrait_kind := "hero"
var portrait_id := GameCatalog.DEFAULT_HERO_ID


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(88.0, 88.0)


func set_hero(new_hero_id: String, new_hero_color: Color) -> void:
	hero_id = new_hero_id
	hero_color = new_hero_color
	portrait_kind = "hero"
	portrait_id = new_hero_id
	queue_redraw()


func set_actor_portrait(kind: String, id: String, color: Color) -> void:
	portrait_kind = kind
	portrait_id = id
	hero_id = id
	hero_color = color
	queue_redraw()


func _draw() -> void:
	var side := minf(size.x, size.y)
	var origin := (size - Vector2(side, side)) * 0.5
	var cell := side / 16.0
	var background := hero_color.darkened(0.56)

	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.025, 0.025, 0.96))
	draw_rect(Rect2(Vector2(size.x * 0.04, size.y * 0.04), size * 0.92), background)
	draw_rect(Rect2(origin, Vector2(side, side)), Color(0.02, 0.025, 0.025, 0.96))
	_px(origin, cell, 1, 1, 14, 14, background)
	_px(origin, cell, 2, 2, 12, 12, hero_color.darkened(0.28))
	_px(origin, cell, 1, 1, 14, 2, Color(0.92, 0.76, 0.36, 0.72))
	_px(origin, cell, 1, 13, 14, 2, Color(0.04, 0.03, 0.02, 0.75))

	if portrait_kind == "structure":
		if _draw_structure_atlas_portrait(origin, side):
			draw_rect(Rect2(origin, Vector2(side, side)), Color(0.04, 0.035, 0.025), false, maxf(2.0, cell * 0.52))
			return
		_draw_structure_portrait(origin, cell)
		draw_rect(Rect2(origin, Vector2(side, side)), Color(0.04, 0.035, 0.025), false, maxf(2.0, cell * 0.52))
		return

	if _draw_atlas_portrait(origin, side):
		draw_rect(Rect2(origin, Vector2(side, side)), Color(0.04, 0.035, 0.025), false, maxf(2.0, cell * 0.52))
		return

	match hero_id:
		"bard_frog":
			_draw_bard_frog(origin, cell)
		"axe_barbarian":
			_draw_axe_barbarian(origin, cell)
		"sorcerer":
			_draw_sorcerer(origin, cell)
		"ancient_druid":
			_draw_ancient_druid(origin, cell)
		_:
			_draw_forest_ranger(origin, cell)

	draw_rect(Rect2(origin, Vector2(side, side)), Color(0.04, 0.035, 0.025), false, maxf(2.0, cell * 0.52))


func _draw_atlas_portrait(origin: Vector2, side: float) -> bool:
	if SPRITE_ATLAS == null:
		return false

	var cell := _atlas_cell()
	var cell_size := Vector2(float(SPRITE_ATLAS.get_width()) / ATLAS_COLUMNS, float(SPRITE_ATLAS.get_height()) / ATLAS_ROWS)
	var source := Rect2(Vector2(float(cell.x) * cell_size.x, float(cell.y) * cell_size.y), cell_size)
	var destination := Rect2(origin + Vector2(side * 0.02, side * 0.02), Vector2(side * 0.96, side * 0.96))
	draw_texture_rect_region(SPRITE_ATLAS, destination, source)
	_draw_portrait_accent(origin, side)
	return true


func _draw_structure_atlas_portrait(origin: Vector2, side: float) -> bool:
	if STRUCTURE_ATLAS == null:
		return false

	var atlas_cell := _structure_atlas_cell()
	var source := _structure_source_rect(atlas_cell)
	var fit_size := Vector2(side * 0.86, side * 0.86)
	var scale := minf(fit_size.x / source.size.x, fit_size.y / source.size.y)
	var draw_size := source.size * scale
	var destination := Rect2(origin + Vector2((side - draw_size.x) * 0.5, side * 0.92 - draw_size.y), draw_size)
	draw_texture_rect_region(STRUCTURE_ATLAS, destination, source)
	_draw_portrait_accent(origin, side)
	return true


func _structure_source_rect(cell: Vector2i) -> Rect2:
	var row := clampi(cell.y, 0, STRUCTURE_SOURCE_RECTS.size() - 1)
	var column := clampi(cell.x, 0, STRUCTURE_SOURCE_RECTS[row].size() - 1)
	return STRUCTURE_SOURCE_RECTS[row][column]


func _structure_atlas_cell() -> Vector2i:
	var row := 1 if hero_color.r > hero_color.g else 0
	if portrait_id.begins_with("tower_t"):
		var tier := clampi(int(portrait_id.substr(7)), 1, 3)
		return Vector2i(tier - 1, row)

	return Vector2i(3, row)


func _atlas_cell() -> Vector2i:
	match portrait_kind:
		"lane_unit":
			match portrait_id:
				"line_mage":
					return Vector2i(3, 1)
				"line_siege":
					return Vector2i(0, 2)
				_:
					return Vector2i(2, 1)
		"neutral":
			match portrait_id:
				"neutral_spitter":
					return Vector2i(2, 2)
				"neutral_claw":
					return Vector2i(3, 2)
				_:
					return Vector2i(1, 2)
		"enemy_hero":
			return Vector2i(1, 1)
		"summon":
			match portrait_id:
				"treant":
					return Vector2i(0, 1)
				"snake":
					return Vector2i(3, 2)
				_:
					return Vector2i(2, 1)
		_:
			match portrait_id:
				"bard_frog":
					return Vector2i(1, 0)
				"axe_barbarian":
					return Vector2i(2, 0)
				"sorcerer":
					return Vector2i(3, 0)
				"ancient_druid":
					return Vector2i(0, 1)
				_:
					return Vector2i(0, 0)


func _draw_portrait_accent(origin: Vector2, side: float) -> void:
	var accent := hero_color.lightened(0.22)
	draw_rect(Rect2(origin + Vector2(side * 0.10, side * 0.09), Vector2(side * 0.80, side * 0.06)), Color(accent.r, accent.g, accent.b, 0.75))
	draw_rect(Rect2(origin + Vector2(side * 0.10, side * 0.84), Vector2(side * 0.80, side * 0.07)), Color(0.02, 0.02, 0.015, 0.62))


func _draw_forest_ranger(origin: Vector2, cell: float) -> void:
	var skin := Color(0.76, 0.54, 0.34)
	var hood := Color(0.14, 0.42, 0.18)
	var leather := Color(0.30, 0.18, 0.09)
	_px(origin, cell, 5, 3, 6, 3, hood.lightened(0.10))
	_px(origin, cell, 4, 5, 8, 5, hood)
	_px(origin, cell, 6, 6, 4, 4, skin)
	_px(origin, cell, 5, 10, 6, 3, leather)
	_px(origin, cell, 3, 7, 2, 5, hood.darkened(0.20))
	_px(origin, cell, 11, 7, 2, 5, hood.darkened(0.20))
	_px(origin, cell, 6, 7, 1, 1, Color(0.02, 0.02, 0.01))
	_px(origin, cell, 9, 7, 1, 1, Color(0.02, 0.02, 0.01))
	_px(origin, cell, 12, 4, 1, 8, Color(0.72, 0.56, 0.24))
	_px(origin, cell, 11, 4, 1, 1, Color(0.95, 0.88, 0.58))


func _draw_bard_frog(origin: Vector2, cell: float) -> void:
	var skin := Color(0.35, 0.78, 0.92)
	var vest := Color(0.23, 0.15, 0.32)
	var gold := Color(0.95, 0.78, 0.28)
	_px(origin, cell, 4, 5, 8, 6, skin.darkened(0.05))
	_px(origin, cell, 5, 3, 2, 3, skin.lightened(0.12))
	_px(origin, cell, 9, 3, 2, 3, skin.lightened(0.12))
	_px(origin, cell, 5, 10, 6, 3, vest)
	_px(origin, cell, 6, 4, 1, 1, Color(0.02, 0.02, 0.02))
	_px(origin, cell, 10, 4, 1, 1, Color(0.02, 0.02, 0.02))
	_px(origin, cell, 6, 8, 4, 1, Color(0.04, 0.02, 0.02))
	_px(origin, cell, 11, 8, 2, 2, Color(0.45, 0.28, 0.12))
	_px(origin, cell, 12, 6, 1, 5, gold)


func _draw_axe_barbarian(origin: Vector2, cell: float) -> void:
	var skin := Color(0.70, 0.42, 0.26)
	var armor := Color(0.78, 0.28, 0.16)
	var steel := Color(0.78, 0.76, 0.68)
	_px(origin, cell, 5, 4, 6, 5, skin)
	_px(origin, cell, 4, 9, 8, 4, armor.darkened(0.15))
	_px(origin, cell, 3, 6, 2, 5, armor)
	_px(origin, cell, 11, 6, 2, 5, armor)
	_px(origin, cell, 5, 3, 6, 1, Color(0.24, 0.12, 0.06))
	_px(origin, cell, 6, 6, 1, 1, Color(0.02, 0.02, 0.01))
	_px(origin, cell, 9, 6, 1, 1, Color(0.02, 0.02, 0.01))
	_px(origin, cell, 2, 2, 2, 5, steel)
	_px(origin, cell, 12, 2, 2, 5, steel)
	_px(origin, cell, 3, 1, 1, 1, Color(0.96, 0.94, 0.80))
	_px(origin, cell, 12, 1, 1, 1, Color(0.96, 0.94, 0.80))


func _draw_sorcerer(origin: Vector2, cell: float) -> void:
	var robe := Color(0.52, 0.30, 0.92)
	var skin := Color(0.64, 0.48, 0.68)
	var glow := Color(0.45, 0.92, 1.0)
	_px(origin, cell, 5, 4, 6, 5, skin)
	_px(origin, cell, 4, 3, 8, 2, robe.darkened(0.10))
	_px(origin, cell, 5, 9, 6, 4, robe)
	_px(origin, cell, 4, 11, 8, 2, robe.darkened(0.18))
	_px(origin, cell, 7, 2, 2, 2, robe.lightened(0.22))
	_px(origin, cell, 6, 6, 1, 1, Color(0.02, 0.02, 0.04))
	_px(origin, cell, 9, 6, 1, 1, Color(0.02, 0.02, 0.04))
	_px(origin, cell, 3, 7, 2, 2, Color(1.0, 0.36, 0.18))
	_px(origin, cell, 11, 7, 2, 2, glow)
	_px(origin, cell, 8, 10, 1, 1, Color(0.95, 0.95, 1.0))


func _draw_ancient_druid(origin: Vector2, cell: float) -> void:
	var bark := Color(0.35, 0.21, 0.10)
	var leaf := Color(0.20, 0.58, 0.22)
	var rune := Color(0.58, 1.0, 0.42)
	_px(origin, cell, 5, 4, 6, 5, bark.lightened(0.10))
	_px(origin, cell, 4, 3, 8, 3, leaf.darkened(0.04))
	_px(origin, cell, 5, 9, 6, 4, bark)
	_px(origin, cell, 4, 10, 8, 2, leaf.darkened(0.10))
	_px(origin, cell, 4, 2, 1, 3, bark.lightened(0.18))
	_px(origin, cell, 11, 2, 1, 3, bark.lightened(0.18))
	_px(origin, cell, 6, 6, 1, 1, Color(0.02, 0.02, 0.01))
	_px(origin, cell, 9, 6, 1, 1, Color(0.02, 0.02, 0.01))
	_px(origin, cell, 8, 8, 1, 1, rune)
	_px(origin, cell, 7, 11, 2, 1, rune.darkened(0.05))


func _draw_structure_portrait(origin: Vector2, cell: float) -> void:
	var stone := hero_color.darkened(0.18)
	var trim := hero_color.lightened(0.16)
	if portrait_id == "base" or portrait_id == "shrine":
		_px(origin, cell, 4, 4, 8, 8, stone)
		_px(origin, cell, 3, 8, 10, 4, stone.darkened(0.16))
		_px(origin, cell, 5, 2, 6, 3, trim)
		_px(origin, cell, 7, 6, 2, 4, Color(1.0, 0.86, 0.36))
	else:
		_px(origin, cell, 6, 3, 4, 10, stone)
		_px(origin, cell, 4, 10, 8, 3, stone.darkened(0.16))
		_px(origin, cell, 5, 2, 6, 3, trim)
		_px(origin, cell, 7, 5, 2, 2, Color(1.0, 0.86, 0.36))


func _px(origin: Vector2, cell: float, x: int, y: int, w: int, h: int, color: Color) -> void:
	draw_rect(Rect2(origin + Vector2(float(x), float(y)) * cell, Vector2(float(w), float(h)) * cell), color)
