class_name UnitArt
extends RefCounted

const SPRITE_ATLAS: Texture2D = preload("res://assets/sprites/generated/moba_units_atlas_pixel.png")
const STRUCTURE_ATLAS: Texture2D = preload("res://assets/sprites/generated/moba_towers_atlas_pixel.png")
const ATLAS_COLUMNS := 4.0
const ATLAS_ROWS := 3.0
const USE_SPRITE_ATLAS := true
const USE_STRUCTURE_ATLAS := true
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
const WALK_CYCLE_SPEED := 2.6
const IDLE_CYCLE_SPEED := 0.85


static func draw_lane_creep(canvas: CanvasItem, unit_id: String, team_color: Color, radius: float) -> void:
	var tint := _lane_tint(team_color)
	match unit_id:
		"line_mage":
			if _draw_atlas_sprite(canvas, Vector2i(3, 1), radius, 4.95, 1.05, tint):
				_draw_team_plate(canvas, team_color, radius)
				return
			_draw_lane_mage(canvas, team_color, radius)
		"line_siege":
			if _draw_atlas_sprite(canvas, Vector2i(0, 2), radius, 4.60, 1.16, tint, "siege"):
				_draw_team_plate(canvas, team_color, radius)
				return
			_draw_lane_siege(canvas, team_color, radius)
		_:
			if _draw_atlas_sprite(canvas, Vector2i(2, 1), radius, 4.95, 1.05, tint):
				_draw_team_plate(canvas, team_color, radius)
				return
			_draw_lane_swordsman(canvas, team_color, radius)


static func draw_hero(canvas: CanvasItem, hero_id: String, hero_color: Color, radius: float) -> void:
	match hero_id:
		"bard_frog":
			if _draw_atlas_sprite(canvas, Vector2i(1, 0), radius, 5.65, 1.05):
				return
			_draw_bard_frog(canvas, hero_color, radius)
		"axe_barbarian":
			if _draw_atlas_sprite(canvas, Vector2i(2, 0), radius, 5.75, 1.05):
				return
			_draw_axe_barbarian(canvas, hero_color, radius)
		"sorcerer":
			if _draw_atlas_sprite(canvas, Vector2i(3, 0), radius, 5.85, 1.05):
				return
			_draw_sorcerer(canvas, hero_color, radius)
		"ancient_druid":
			if _draw_atlas_sprite(canvas, Vector2i(0, 1), radius, 5.85, 1.08):
				return
			_draw_ancient_druid(canvas, hero_color, radius)
		_:
			if _draw_atlas_sprite(canvas, Vector2i(0, 0), radius, 5.75, 1.05):
				return
			_draw_forest_ranger(canvas, hero_color, radius)


static func draw_enemy_hero(canvas: CanvasItem, team_color: Color, radius: float) -> void:
	if _draw_atlas_sprite(canvas, Vector2i(1, 1), radius, 5.95, 1.06):
		return

	var armor := team_color.darkened(0.42)
	var trim := Color(0.12, 0.03, 0.02)
	var metal := Color(0.45, 0.43, 0.38)
	_draw_boots(canvas, radius, trim)
	_draw_cape(canvas, Color(0.17, 0.02, 0.02), radius, 1.08)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, -radius * 1.28),
		Vector2(radius * 0.94, -radius * 0.38),
		Vector2(radius * 0.70, radius * 0.78),
		Vector2(0.0, radius * 1.04),
		Vector2(-radius * 0.70, radius * 0.78),
		Vector2(-radius * 0.94, -radius * 0.38),
	]), armor)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, -radius * 1.08),
		Vector2(radius * 0.52, -radius * 0.34),
		Vector2(radius * 0.42, radius * 0.48),
		Vector2(0.0, radius * 0.70),
		Vector2(-radius * 0.42, radius * 0.48),
		Vector2(-radius * 0.52, -radius * 0.34),
	]), team_color.darkened(0.08))
	canvas.draw_line(Vector2(-radius * 1.12, -radius * 0.34), Vector2(-radius * 1.62, -radius * 1.0), metal, 3.0)
	canvas.draw_line(Vector2(radius * 1.12, -radius * 0.34), Vector2(radius * 1.62, -radius * 1.0), metal, 3.0)
	canvas.draw_circle(Vector2(0.0, -radius * 0.86), radius * 0.46, armor.lightened(0.16))
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(-radius * 0.62, -radius * 1.02),
		Vector2(0.0, -radius * 1.42),
		Vector2(radius * 0.62, -radius * 1.02),
		Vector2(radius * 0.38, -radius * 0.80),
		Vector2(-radius * 0.38, -radius * 0.80),
	]), trim)
	canvas.draw_circle(Vector2(-radius * 0.18, -radius * 0.88), radius * 0.07, Color(1.0, 0.58, 0.35))
	canvas.draw_circle(Vector2(radius * 0.18, -radius * 0.88), radius * 0.07, Color(1.0, 0.58, 0.35))
	canvas.draw_arc(Vector2.ZERO, radius + 1.5, 0.0, TAU, 24, Color(0.02, 0.015, 0.01), 1.6)


static func draw_neutral(canvas: CanvasItem, unit_id: String, radius: float) -> void:
	match unit_id:
		"neutral_spitter":
			if _draw_atlas_sprite(canvas, Vector2i(2, 2), radius, 5.10, 1.10, Color.WHITE, "neutral"):
				return
			_draw_neutral_spitter(canvas, radius)
		"neutral_thrower":
			if _draw_atlas_sprite(canvas, Vector2i(1, 2), radius, 5.20, 1.08, Color.WHITE, "neutral"):
				return
			_draw_neutral_thrower(canvas, radius)
		"neutral_claw":
			if _draw_atlas_sprite(canvas, Vector2i(3, 2), radius, 5.00, 1.18, Color.WHITE, "neutral"):
				return
			_draw_neutral_claw(canvas, radius)
		_:
			if _draw_atlas_sprite(canvas, Vector2i(1, 2), radius, 5.20, 1.08, Color.WHITE, "neutral"):
				return
			_draw_neutral_bruiser(canvas, radius)


static func draw_companion(canvas: CanvasItem, companion_kind: String, team_color: Color, radius: float) -> void:
	match companion_kind:
		"treant":
			_draw_companion_treant(canvas, radius)
		"snake":
			_draw_companion_snake(canvas, team_color, radius)
		_:
			_draw_companion_wolf(canvas, team_color, radius)


static func draw_tower(canvas: CanvasItem, team: String, tier: int, size: Vector2) -> bool:
	if not USE_STRUCTURE_ATLAS or STRUCTURE_ATLAS == null:
		return false

	var cell := Vector2i(clampi(tier, 1, 3) - 1, _structure_atlas_row(team))
	var source := _structure_source_rect(cell)
	var height := size.y * 1.95
	return _draw_structure_atlas_sprite(canvas, source, height, size.y * 0.64)


static func draw_shrine(canvas: CanvasItem, team: String, size: Vector2) -> bool:
	if not USE_STRUCTURE_ATLAS or STRUCTURE_ATLAS == null:
		return false

	var cell := Vector2i(3, _structure_atlas_row(team))
	var source := _structure_source_rect(cell)
	var height := size.y * 1.54
	return _draw_structure_atlas_sprite(canvas, source, height, size.y * 0.58)


static func _structure_source_rect(cell: Vector2i) -> Rect2:
	var row := clampi(cell.y, 0, STRUCTURE_SOURCE_RECTS.size() - 1)
	var column := clampi(cell.x, 0, STRUCTURE_SOURCE_RECTS[row].size() - 1)
	return STRUCTURE_SOURCE_RECTS[row][column]


static func _draw_atlas_sprite(canvas: CanvasItem, cell: Vector2i, radius: float, height_multiplier: float, width_multiplier: float, tint: Color = Color.WHITE, profile := "default") -> bool:
	if not USE_SPRITE_ATLAS or SPRITE_ATLAS == null:
		return false

	var cell_size := Vector2(float(SPRITE_ATLAS.get_width()) / ATLAS_COLUMNS, float(SPRITE_ATLAS.get_height()) / ATLAS_ROWS)
	var source := Rect2(Vector2(float(cell.x) * cell_size.x, float(cell.y) * cell_size.y), cell_size)
	var animation := _get_sprite_animation(canvas, radius, cell, profile)
	var height := radius * height_multiplier * float(animation.get("scale_y", 1.0))
	var width := height * width_multiplier * float(animation.get("scale_x", 1.0))
	var center := Vector2(float(animation.get("offset_x", 0.0)), float(animation.get("offset_y", 0.0)))
	var destination := Rect2(Vector2(-width * 0.5, -height * 0.78), Vector2(width, height))
	destination = _snap_rect(destination)
	canvas.draw_set_transform(center, float(animation.get("rotation", 0.0)), Vector2(float(animation.get("facing", 1.0)), 1.0))
	canvas.draw_texture_rect_region(SPRITE_ATLAS, destination, source, tint)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return true


static func _draw_structure_atlas_sprite(canvas: CanvasItem, source: Rect2, height: float, bottom_y: float) -> bool:
	if not USE_STRUCTURE_ATLAS or STRUCTURE_ATLAS == null:
		return false

	if source.size.x <= 0.0 or source.size.y <= 0.0:
		return false

	var draw_size := Vector2(height * source.size.x / source.size.y, height)
	var destination := Rect2(Vector2(-draw_size.x * 0.5, bottom_y - draw_size.y), draw_size)
	canvas.draw_texture_rect_region(STRUCTURE_ATLAS, _snap_rect(destination), source)
	return true


static func _structure_atlas_row(team: String) -> int:
	return 1 if team == GameCatalog.TEAM_ENEMY else 0


static func _get_sprite_animation(canvas: CanvasItem, radius: float, cell: Vector2i, profile: String) -> Dictionary:
	var visual_time := _call_float(canvas, "get_visual_time", 0.0)
	var move_amount := _call_float(canvas, "get_visual_move_amount", 0.0)
	var attack_amount := _call_float(canvas, "get_visual_attack_amount", 0.0)
	var attack_direction := _call_vector2(canvas, "get_visual_attack_direction", Vector2.RIGHT)
	var facing_sign := _call_float(canvas, "get_visual_facing_sign", 1.0)
	var phase := float((int(canvas.get_instance_id()) + cell.x * 13 + cell.y * 31) % 97) * 0.07
	var walk_wave := sin((visual_time + phase) * TAU * WALK_CYCLE_SPEED)
	var walk_lift := absf(walk_wave)
	var idle_wave := sin((visual_time + phase) * TAU * IDLE_CYCLE_SPEED)
	var attack_progress := 1.0 - attack_amount
	var attack_peak := sin(clampf(attack_progress, 0.0, 1.0) * PI) if attack_amount > 0.0 else 0.0
	var attack_sign := (1.0 if attack_direction.x > 0.0 else -1.0) if absf(attack_direction.x) > 0.05 else facing_sign

	var walk_x_strength := 0.10
	var walk_y_strength := 0.28
	var idle_strength := 0.10
	var attack_strength := 0.72
	var attack_y_strength := 0.36
	var attack_lift_strength := 0.12
	var rotate_strength := 0.055
	var squash_strength := 0.075
	var use_facing := facing_sign
	if profile == "neutral":
		walk_x_strength = 0.035
		walk_y_strength = 0.12
		idle_strength = 0.045
		attack_strength = 0.28
		attack_y_strength = 0.12
		attack_lift_strength = 0.05
		rotate_strength = 0.012
		squash_strength = 0.035
		use_facing = 1.0
	elif profile == "siege":
		walk_x_strength = 0.035
		walk_y_strength = 0.09
		idle_strength = 0.025
		attack_strength = 0.32
		attack_y_strength = 0.10
		attack_lift_strength = 0.04
		rotate_strength = 0.008
		squash_strength = 0.025

	var bob := -walk_lift * radius * walk_y_strength * move_amount
	bob += idle_wave * radius * idle_strength * (1.0 - move_amount)
	bob += attack_peak * radius * attack_y_strength * attack_direction.y
	bob -= attack_peak * radius * attack_lift_strength

	return {
		"offset_x": walk_wave * radius * walk_x_strength * move_amount + attack_peak * radius * attack_strength * attack_sign,
		"offset_y": bob,
		"scale_x": 1.0 + walk_lift * squash_strength * move_amount + attack_peak * squash_strength * 2.1,
		"scale_y": 1.0 - walk_lift * squash_strength * 0.78 * move_amount - attack_peak * squash_strength,
		"rotation": walk_wave * rotate_strength * move_amount + idle_wave * rotate_strength * 0.45 * (1.0 - move_amount) + attack_peak * rotate_strength * 2.0 * attack_sign,
		"facing": use_facing,
	}


static func _call_float(canvas: CanvasItem, method_name: String, fallback: float) -> float:
	if canvas.has_method(method_name):
		return float(canvas.call(method_name))

	return fallback


static func _call_vector2(canvas: CanvasItem, method_name: String, fallback: Vector2) -> Vector2:
	if canvas.has_method(method_name):
		var value = canvas.call(method_name)
		if value is Vector2:
			return value

	return fallback


static func _snap_rect(rect: Rect2) -> Rect2:
	return Rect2(
		Vector2(roundf(rect.position.x), roundf(rect.position.y)),
		Vector2(maxf(1.0, roundf(rect.size.x)), maxf(1.0, roundf(rect.size.y)))
	)


static func _lane_tint(team_color: Color) -> Color:
	if team_color.r > team_color.g:
		return Color(1.22, 0.62, 0.58, 1.0)

	return Color(0.94, 1.05, 0.94, 1.0)


static func _draw_team_plate(canvas: CanvasItem, team_color: Color, radius: float) -> void:
	var center := Vector2(0.0, radius * 0.86)
	canvas.draw_arc(center, radius * 1.08, 0.0, TAU, 28, Color(0.02, 0.015, 0.01, 0.82), 3.0)
	canvas.draw_arc(center, radius * 0.94, 0.0, TAU, 28, team_color.lightened(0.18), 2.0)


static func _draw_lane_swordsman(canvas: CanvasItem, team_color: Color, radius: float) -> void:
	var armor := Color(0.36, 0.37, 0.32)
	var leather := Color(0.28, 0.17, 0.09)
	var metal := Color(0.78, 0.76, 0.64)
	_draw_boots(canvas, radius, leather)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, -radius * 1.10),
		Vector2(radius * 0.82, -radius * 0.24),
		Vector2(radius * 0.58, radius * 0.72),
		Vector2(0.0, radius * 0.98),
		Vector2(-radius * 0.58, radius * 0.72),
		Vector2(-radius * 0.82, -radius * 0.24),
	]), armor)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, -radius * 0.92),
		Vector2(radius * 0.46, -radius * 0.18),
		Vector2(radius * 0.30, radius * 0.44),
		Vector2(0.0, radius * 0.62),
		Vector2(-radius * 0.30, radius * 0.44),
		Vector2(-radius * 0.46, -radius * 0.18),
	]), team_color)
	canvas.draw_circle(Vector2(0.0, -radius * 0.66), radius * 0.36, armor.lightened(0.18))
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(-radius * 0.76, -radius * 0.28),
		Vector2(-radius * 1.18, radius * 0.05),
		Vector2(-radius * 0.90, radius * 0.48),
		Vector2(-radius * 0.42, radius * 0.28),
	]), team_color.darkened(0.12))
	canvas.draw_line(Vector2(radius * 0.48, -radius * 0.22), Vector2(radius * 1.34, -radius * 1.12), metal, 3.0)
	canvas.draw_line(Vector2(radius * 1.34, -radius * 1.12), Vector2(radius * 1.50, -radius * 1.28), Color(0.94, 0.90, 0.68), 2.0)
	canvas.draw_arc(Vector2.ZERO, radius + 1.0, 0.0, TAU, 24, Color(0.02, 0.015, 0.01), 1.4)


static func _draw_lane_mage(canvas: CanvasItem, team_color: Color, radius: float) -> void:
	var robe := team_color.darkened(0.16)
	var trim := Color(0.96, 0.82, 0.38)
	var staff := Color(0.36, 0.22, 0.11)
	_draw_boots(canvas, radius, Color(0.15, 0.10, 0.08))
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, -radius * 1.24),
		Vector2(radius * 0.82, -radius * 0.10),
		Vector2(radius * 0.58, radius * 0.96),
		Vector2(0.0, radius * 1.16),
		Vector2(-radius * 0.58, radius * 0.96),
		Vector2(-radius * 0.82, -radius * 0.10),
	]), robe.darkened(0.12))
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, -radius * 1.02),
		Vector2(radius * 0.42, -radius * 0.06),
		Vector2(radius * 0.28, radius * 0.70),
		Vector2(0.0, radius * 0.90),
		Vector2(-radius * 0.28, radius * 0.70),
		Vector2(-radius * 0.42, -radius * 0.06),
	]), robe.lightened(0.08))
	canvas.draw_line(Vector2(radius * 0.72, radius * 0.04), Vector2(radius * 1.32, -radius * 1.34), staff, 3.0)
	canvas.draw_circle(Vector2(radius * 1.34, -radius * 1.40), radius * 0.22, Color(0.58, 0.90, 1.0))
	canvas.draw_circle(Vector2(radius * 1.34, -radius * 1.40), radius * 0.10, Color(0.92, 1.0, 1.0))
	canvas.draw_circle(Vector2(0.0, -radius * 0.70), radius * 0.34, robe.lightened(0.22))
	canvas.draw_line(Vector2(-radius * 0.26, radius * 0.12), Vector2(radius * 0.26, radius * 0.12), trim, 2.0)
	canvas.draw_arc(Vector2.ZERO, radius + 1.0, 0.0, TAU, 24, Color(0.02, 0.015, 0.01), 1.4)


static func _draw_lane_siege(canvas: CanvasItem, team_color: Color, radius: float) -> void:
	var wood := Color(0.33, 0.20, 0.10)
	var dark := Color(0.08, 0.06, 0.04)
	var metal := Color(0.54, 0.52, 0.44)
	canvas.draw_rect(Rect2(Vector2(-radius * 1.32, -radius * 0.34), Vector2(radius * 2.64, radius * 1.12)), wood)
	canvas.draw_rect(Rect2(Vector2(-radius * 1.04, -radius * 0.16), Vector2(radius * 2.08, radius * 0.34)), team_color.darkened(0.12))
	canvas.draw_line(Vector2(-radius * 0.86, -radius * 0.50), Vector2(radius * 0.96, -radius * 1.26), wood.lightened(0.14), 5.0)
	canvas.draw_line(Vector2(radius * 0.42, -radius * 0.98), Vector2(radius * 1.18, -radius * 1.34), metal, 3.0)
	canvas.draw_circle(Vector2(-radius * 0.90, radius * 0.72), radius * 0.28, dark)
	canvas.draw_circle(Vector2(radius * 0.90, radius * 0.72), radius * 0.28, dark)
	canvas.draw_circle(Vector2(-radius * 0.90, radius * 0.72), radius * 0.13, metal)
	canvas.draw_circle(Vector2(radius * 0.90, radius * 0.72), radius * 0.13, metal)
	canvas.draw_arc(Vector2.ZERO, radius * 1.38, 0.0, TAU, 24, Color(0.02, 0.015, 0.01), 1.4)


static func _draw_forest_ranger(canvas: CanvasItem, hero_color: Color, radius: float) -> void:
	var leather := Color(0.28, 0.17, 0.09)
	var cloak := hero_color.darkened(0.18)
	var trim := Color(0.74, 0.58, 0.30)
	_draw_boots(canvas, radius, leather)
	_draw_cape(canvas, cloak.darkened(0.18), radius, 1.18)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, -radius * 1.16),
		Vector2(radius * 0.62, -radius * 0.24),
		Vector2(radius * 0.46, radius * 0.72),
		Vector2(0.0, radius * 0.96),
		Vector2(-radius * 0.46, radius * 0.72),
		Vector2(-radius * 0.62, -radius * 0.24),
	]), leather)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, -radius * 1.22),
		Vector2(radius * 0.72, -radius * 0.44),
		Vector2(radius * 0.40, -radius * 0.04),
		Vector2(0.0, -radius * 0.34),
		Vector2(-radius * 0.40, -radius * 0.04),
		Vector2(-radius * 0.72, -radius * 0.44),
	]), cloak.lightened(0.06))
	canvas.draw_circle(Vector2(0.0, -radius * 0.70), radius * 0.30, Color(0.78, 0.58, 0.38))
	canvas.draw_arc(Vector2(radius * 0.76, -radius * 0.30), radius * 0.78, -1.25, 1.35, 24, trim, 2.6)
	canvas.draw_line(Vector2(radius * 0.28, -radius * 0.96), Vector2(radius * 1.10, radius * 0.34), Color(0.93, 0.86, 0.62), 1.3)
	canvas.draw_line(Vector2(-radius * 0.44, radius * 0.28), Vector2(radius * 0.52, -radius * 0.54), trim, 2.0)
	canvas.draw_arc(Vector2.ZERO, radius + 1.0, 0.0, TAU, 28, Color(0.02, 0.015, 0.01), 1.5)


static func _draw_bard_frog(canvas: CanvasItem, hero_color: Color, radius: float) -> void:
	var skin := hero_color.lightened(0.08)
	var vest := Color(0.26, 0.18, 0.35)
	var gold := Color(0.95, 0.76, 0.28)
	_draw_boots(canvas, radius, Color(0.16, 0.10, 0.08))
	canvas.draw_circle(Vector2(0.0, radius * 0.02), radius * 0.78, skin.darkened(0.10))
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, -radius * 0.84),
		Vector2(radius * 0.52, -radius * 0.18),
		Vector2(radius * 0.42, radius * 0.56),
		Vector2(0.0, radius * 0.80),
		Vector2(-radius * 0.42, radius * 0.56),
		Vector2(-radius * 0.52, -radius * 0.18),
	]), vest)
	canvas.draw_circle(Vector2(-radius * 0.32, -radius * 0.84), radius * 0.24, skin)
	canvas.draw_circle(Vector2(radius * 0.32, -radius * 0.84), radius * 0.24, skin)
	canvas.draw_circle(Vector2(-radius * 0.32, -radius * 0.88), radius * 0.08, Color(0.03, 0.02, 0.02))
	canvas.draw_circle(Vector2(radius * 0.32, -radius * 0.88), radius * 0.08, Color(0.03, 0.02, 0.02))
	canvas.draw_arc(Vector2(0.0, -radius * 0.62), radius * 0.28, 0.18, PI - 0.18, 16, Color(0.04, 0.02, 0.02), 2.0)
	canvas.draw_circle(Vector2(radius * 0.68, -radius * 0.08), radius * 0.28, Color(0.48, 0.30, 0.14))
	canvas.draw_line(Vector2(radius * 0.48, radius * 0.12), Vector2(radius * 1.10, -radius * 0.42), gold, 2.0)
	canvas.draw_arc(Vector2.ZERO, radius + 1.0, 0.0, TAU, 28, Color(0.02, 0.015, 0.01), 1.5)


static func _draw_axe_barbarian(canvas: CanvasItem, hero_color: Color, radius: float) -> void:
	var skin := Color(0.70, 0.42, 0.26)
	var leather := Color(0.24, 0.13, 0.07)
	var metal := Color(0.72, 0.72, 0.66)
	_draw_boots(canvas, radius, leather.darkened(0.2))
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, -radius * 1.05),
		Vector2(radius * 0.92, -radius * 0.18),
		Vector2(radius * 0.62, radius * 0.76),
		Vector2(0.0, radius * 1.0),
		Vector2(-radius * 0.62, radius * 0.76),
		Vector2(-radius * 0.92, -radius * 0.18),
	]), hero_color.darkened(0.18))
	canvas.draw_circle(Vector2(0.0, -radius * 0.70), radius * 0.34, skin)
	canvas.draw_line(Vector2(-radius * 0.70, -radius * 0.18), Vector2(-radius * 1.36, -radius * 1.05), leather, 4.0)
	canvas.draw_line(Vector2(radius * 0.70, -radius * 0.18), Vector2(radius * 1.36, -radius * 1.05), leather, 4.0)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(-radius * 1.48, -radius * 1.18),
		Vector2(-radius * 1.06, -radius * 1.06),
		Vector2(-radius * 1.36, -radius * 0.70),
	]), metal)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(radius * 1.48, -radius * 1.18),
		Vector2(radius * 1.06, -radius * 1.06),
		Vector2(radius * 1.36, -radius * 0.70),
	]), metal)
	canvas.draw_line(Vector2(-radius * 0.32, -radius * 0.32), Vector2(radius * 0.32, -radius * 0.32), metal, 2.0)
	canvas.draw_arc(Vector2.ZERO, radius + 1.0, 0.0, TAU, 28, Color(0.02, 0.015, 0.01), 1.5)


static func _draw_sorcerer(canvas: CanvasItem, hero_color: Color, radius: float) -> void:
	var robe := hero_color.darkened(0.12)
	var trim := Color(0.88, 0.72, 1.0)
	_draw_boots(canvas, radius, Color(0.10, 0.06, 0.16))
	_draw_cape(canvas, robe.darkened(0.20), radius, 1.12)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, -radius * 1.32),
		Vector2(radius * 0.78, -radius * 0.10),
		Vector2(radius * 0.62, radius * 1.06),
		Vector2(0.0, radius * 1.20),
		Vector2(-radius * 0.62, radius * 1.06),
		Vector2(-radius * 0.78, -radius * 0.10),
	]), robe)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, -radius * 1.48),
		Vector2(radius * 0.42, -radius * 0.76),
		Vector2(0.0, -radius * 0.96),
		Vector2(-radius * 0.42, -radius * 0.76),
	]), robe.lightened(0.16))
	canvas.draw_circle(Vector2(0.0, -radius * 0.70), radius * 0.30, Color(0.68, 0.50, 0.70))
	canvas.draw_circle(Vector2(-radius * 0.78, -radius * 0.12), radius * 0.16, Color(1.0, 0.36, 0.18))
	canvas.draw_circle(Vector2(radius * 0.82, -radius * 0.24), radius * 0.16, Color(0.30, 0.70, 1.0))
	canvas.draw_circle(Vector2(radius * 0.14, radius * 0.20), radius * 0.14, Color(0.92, 0.92, 1.0))
	canvas.draw_line(Vector2(-radius * 0.28, radius * 0.08), Vector2(radius * 0.28, radius * 0.08), trim, 2.0)
	canvas.draw_arc(Vector2.ZERO, radius + 1.0, 0.0, TAU, 28, Color(0.02, 0.015, 0.01), 1.5)


static func _draw_ancient_druid(canvas: CanvasItem, hero_color: Color, radius: float) -> void:
	var bark := Color(0.29, 0.18, 0.09)
	var leaf := hero_color.lightened(0.04)
	var rune := Color(0.58, 0.95, 0.42)
	_draw_boots(canvas, radius, bark)
	_draw_cape(canvas, Color(0.12, 0.30, 0.12), radius, 1.12)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, -radius * 1.20),
		Vector2(radius * 0.70, -radius * 0.20),
		Vector2(radius * 0.48, radius * 0.86),
		Vector2(0.0, radius * 1.10),
		Vector2(-radius * 0.48, radius * 0.86),
		Vector2(-radius * 0.70, -radius * 0.20),
	]), bark)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, -radius * 1.00),
		Vector2(radius * 0.46, -radius * 0.20),
		Vector2(radius * 0.24, radius * 0.48),
		Vector2(0.0, radius * 0.70),
		Vector2(-radius * 0.24, radius * 0.48),
		Vector2(-radius * 0.46, -radius * 0.20),
	]), leaf)
	canvas.draw_circle(Vector2(0.0, -radius * 0.72), radius * 0.32, Color(0.54, 0.38, 0.22))
	canvas.draw_line(Vector2(-radius * 0.30, -radius * 0.98), Vector2(-radius * 0.72, -radius * 1.42), bark.lightened(0.16), 2.0)
	canvas.draw_line(Vector2(radius * 0.30, -radius * 0.98), Vector2(radius * 0.72, -radius * 1.42), bark.lightened(0.16), 2.0)
	canvas.draw_line(Vector2(radius * 0.70, radius * 0.22), Vector2(radius * 1.20, -radius * 1.26), bark.lightened(0.12), 3.0)
	canvas.draw_circle(Vector2(radius * 1.20, -radius * 1.30), radius * 0.13, rune)
	canvas.draw_circle(Vector2(0.0, radius * 0.12), radius * 0.10, rune)
	canvas.draw_arc(Vector2.ZERO, radius + 1.0, 0.0, TAU, 28, Color(0.02, 0.015, 0.01), 1.5)


static func _draw_neutral_bruiser(canvas: CanvasItem, radius: float) -> void:
	var hide := Color(0.46, 0.34, 0.20)
	var horn := Color(0.82, 0.76, 0.58)
	canvas.draw_circle(Vector2(0.0, 0.0), radius * 0.86, hide.darkened(0.08))
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, -radius * 1.04),
		Vector2(radius * 0.74, -radius * 0.26),
		Vector2(radius * 0.46, radius * 0.58),
		Vector2(0.0, radius * 0.82),
		Vector2(-radius * 0.46, radius * 0.58),
		Vector2(-radius * 0.74, -radius * 0.26),
	]), hide)
	canvas.draw_line(Vector2(-radius * 0.44, -radius * 0.70), Vector2(-radius * 1.06, -radius * 1.02), horn, 3.0)
	canvas.draw_line(Vector2(radius * 0.44, -radius * 0.70), Vector2(radius * 1.06, -radius * 1.02), horn, 3.0)
	canvas.draw_circle(Vector2(-radius * 0.20, -radius * 0.50), radius * 0.06, Color(0.04, 0.02, 0.0))
	canvas.draw_circle(Vector2(radius * 0.20, -radius * 0.50), radius * 0.06, Color(0.04, 0.02, 0.0))
	canvas.draw_arc(Vector2.ZERO, radius + 1.0, 0.0, TAU, 24, Color(0.02, 0.015, 0.01), 1.4)


static func _draw_neutral_spitter(canvas: CanvasItem, radius: float) -> void:
	var skin := Color(0.36, 0.58, 0.30)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, -radius * 1.02),
		Vector2(radius * 0.96, -radius * 0.20),
		Vector2(radius * 0.60, radius * 0.70),
		Vector2(0.0, radius * 0.94),
		Vector2(-radius * 0.60, radius * 0.70),
		Vector2(-radius * 0.96, -radius * 0.20),
	]), skin.darkened(0.08))
	canvas.draw_circle(Vector2(radius * 0.54, -radius * 0.54), radius * 0.22, Color(0.58, 0.88, 0.40))
	canvas.draw_circle(Vector2(radius * 0.94, -radius * 0.76), radius * 0.13, Color(0.72, 1.0, 0.46))
	canvas.draw_line(Vector2(-radius * 0.46, -radius * 0.18), Vector2(-radius * 1.04, radius * 0.08), skin.darkened(0.24), 3.0)
	canvas.draw_arc(Vector2.ZERO, radius + 1.0, 0.0, TAU, 24, Color(0.02, 0.015, 0.01), 1.4)


static func _draw_neutral_thrower(canvas: CanvasItem, radius: float) -> void:
	var cloth := Color(0.36, 0.30, 0.22)
	var stone := Color(0.35, 0.34, 0.30)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, -radius * 1.12),
		Vector2(radius * 0.70, -radius * 0.22),
		Vector2(radius * 0.42, radius * 0.74),
		Vector2(0.0, radius * 0.96),
		Vector2(-radius * 0.42, radius * 0.74),
		Vector2(-radius * 0.70, -radius * 0.22),
	]), cloth)
	canvas.draw_circle(Vector2(0.0, -radius * 0.62), radius * 0.28, Color(0.48, 0.36, 0.22))
	canvas.draw_line(Vector2(-radius * 0.82, -radius * 0.64), Vector2(radius * 0.90, -radius * 1.16), Color(0.33, 0.20, 0.10), 3.0)
	canvas.draw_circle(Vector2(radius * 1.04, -radius * 1.20), radius * 0.22, stone)
	canvas.draw_arc(Vector2.ZERO, radius + 1.0, 0.0, TAU, 24, Color(0.02, 0.015, 0.01), 1.4)


static func _draw_neutral_claw(canvas: CanvasItem, radius: float) -> void:
	var hide := Color(0.38, 0.26, 0.16)
	var claw := Color(0.94, 0.88, 0.66)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, -radius * 1.12),
		Vector2(radius * 0.94, -radius * 0.26),
		Vector2(radius * 0.64, radius * 0.78),
		Vector2(0.0, radius * 1.06),
		Vector2(-radius * 0.64, radius * 0.78),
		Vector2(-radius * 0.94, -radius * 0.26),
	]), hide)
	canvas.draw_circle(Vector2(0.0, -radius * 0.68), radius * 0.34, hide.lightened(0.16))
	for side in [-1.0, 1.0]:
		canvas.draw_line(Vector2(radius * side * 0.58, -radius * 0.12), Vector2(radius * side * 1.34, -radius * 0.70), claw, 2.0)
		canvas.draw_line(Vector2(radius * side * 0.66, radius * 0.10), Vector2(radius * side * 1.42, -radius * 0.28), claw, 2.0)
	canvas.draw_arc(Vector2.ZERO, radius + 1.0, 0.0, TAU, 24, Color(0.02, 0.015, 0.01), 1.4)


static func _draw_companion_treant(canvas: CanvasItem, radius: float) -> void:
	var bark := Color(0.30, 0.17, 0.08)
	var leaves := Color(0.13, 0.38, 0.14)
	canvas.draw_rect(Rect2(Vector2(-radius * 0.36, -radius * 1.22), Vector2(radius * 0.72, radius * 2.02)), bark)
	canvas.draw_circle(Vector2(0.0, -radius * 1.22), radius * 0.76, leaves)
	canvas.draw_circle(Vector2(-radius * 0.44, -radius * 0.82), radius * 0.42, leaves.darkened(0.06))
	canvas.draw_circle(Vector2(radius * 0.44, -radius * 0.82), radius * 0.42, leaves.lightened(0.04))
	canvas.draw_line(Vector2(-radius * 0.28, -radius * 0.10), Vector2(radius * 0.28, -radius * 0.10), Color(0.08, 0.04, 0.02), 2.0)


static func _draw_companion_snake(canvas: CanvasItem, team_color: Color, radius: float) -> void:
	var body := team_color.lightened(0.08)
	canvas.draw_arc(Vector2(-radius * 0.15, radius * 0.12), radius * 0.86, -0.35, PI * 1.18, 24, body.darkened(0.18), 6.0)
	canvas.draw_arc(Vector2(-radius * 0.15, radius * 0.12), radius * 0.86, -0.35, PI * 1.18, 24, body, 3.2)
	canvas.draw_circle(Vector2(radius * 0.86, -radius * 0.16), radius * 0.28, body)
	canvas.draw_circle(Vector2(radius * 0.96, -radius * 0.24), radius * 0.05, Color(0.02, 0.02, 0.01))


static func _draw_companion_wolf(canvas: CanvasItem, team_color: Color, radius: float) -> void:
	var fur := Color(0.38, 0.40, 0.34)
	var light := fur.lightened(0.18)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(-radius * 0.90, radius * 0.26),
		Vector2(-radius * 0.38, -radius * 0.58),
		Vector2(radius * 0.70, -radius * 0.50),
		Vector2(radius * 1.06, radius * 0.08),
		Vector2(radius * 0.46, radius * 0.60),
		Vector2(-radius * 0.62, radius * 0.62),
	]), fur)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(radius * 0.34, -radius * 0.76),
		Vector2(radius * 0.76, -radius * 1.20),
		Vector2(radius * 0.82, -radius * 0.58),
	]), fur.darkened(0.14))
	canvas.draw_circle(Vector2(radius * 0.66, -radius * 0.36), radius * 0.22, light)
	canvas.draw_circle(Vector2(radius * 0.78, -radius * 0.42), radius * 0.05, Color(0.02, 0.02, 0.01))
	canvas.draw_line(Vector2(-radius * 0.20, -radius * 0.04), Vector2(radius * 0.34, radius * 0.30), team_color, 2.0)


static func _draw_boots(canvas: CanvasItem, radius: float, color: Color) -> void:
	canvas.draw_line(Vector2(-radius * 0.34, radius * 0.68), Vector2(-radius * 0.58, radius * 1.04), color, 3.0)
	canvas.draw_line(Vector2(radius * 0.34, radius * 0.68), Vector2(radius * 0.58, radius * 1.04), color, 3.0)


static func _draw_cape(canvas: CanvasItem, color: Color, radius: float, scale_y: float) -> void:
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, -radius * 1.06),
		Vector2(radius * 0.86, radius * 0.10),
		Vector2(radius * 0.36, radius * scale_y),
		Vector2(0.0, radius * (scale_y + 0.14)),
		Vector2(-radius * 0.36, radius * scale_y),
		Vector2(-radius * 0.86, radius * 0.10),
	]), color)
