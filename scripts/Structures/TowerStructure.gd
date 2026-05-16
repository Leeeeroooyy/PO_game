class_name TowerStructure
extends Actor

@export var size := Vector2(42.0, 58.0)

var tower_tier := 1


func configure_tower(new_team: String, new_lane: String, tower_position: Vector2, tier: int) -> void:
	tower_tier = clampi(tier, 1, 3)
	lane = new_lane
	global_position = tower_position
	size = Vector2(38.0 + float(tower_tier) * 5.0, 54.0 + float(tower_tier) * 8.0)
	draw_radius = maxf(size.x, size.y) * 0.34
	add_to_group("tower")
	configure(new_team, new_lane, GameCatalog.create_tower_stats(tower_tier))


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	velocity = Vector2.ZERO

	var target := _find_tower_target()
	if target != null:
		try_attack(target)


func _draw() -> void:
	var rect := Rect2(-size / 2.0, size)
	var team_color := _get_team_color()

	if is_selected:
		draw_rect(rect.grow(8.0), Color(1.0, 0.92, 0.42, 0.92), false, 3.0)

	_draw_attack_radius(team_color)

	draw_rect(rect, Color(0.32, 0.29, 0.24))
	draw_rect(rect.grow(-6.0), team_color.darkened(0.2))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-size.x * 0.65, -size.y * 0.45),
		Vector2(size.x * 0.65, -size.y * 0.45),
		Vector2(0.0, -size.y * 0.86),
	]), team_color.lightened(0.14))
	draw_circle(Vector2(0.0, -size.y * 0.15), 6.0, Color(1.0, 0.86, 0.38))
	draw_line(Vector2.ZERO, Vector2(size.x * 0.58, -size.y * 0.62), Color(0.12, 0.08, 0.05), 4.0)
	for i in range(tower_tier):
		var pip_x := (float(i) - float(tower_tier - 1) * 0.5) * 8.0
		draw_circle(Vector2(pip_x, size.y * 0.25), 2.5, Color(1.0, 0.88, 0.34))

	draw_rect(rect, Color.BLACK, false, 2.0)
	_draw_health_bar()


func _draw_attack_radius(team_color: Color) -> void:
	var radius := _stat("attack_range")
	var fill_alpha := 0.028 if not is_selected else 0.065
	var line_alpha := 0.16 if not is_selected else 0.36
	var line_width := 1.5 if not is_selected else 3.0
	draw_circle(Vector2.ZERO, radius, Color(team_color.r, team_color.g, team_color.b, fill_alpha))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 80, Color(team_color.r, team_color.g, team_color.b, line_alpha), line_width)


func _find_tower_target() -> Actor:
	var attack_range := _stat("attack_range")
	var best_creep := _find_nearest_tower_target(attack_range, true)
	if best_creep != null:
		return best_creep

	return _find_nearest_tower_target(attack_range, false)


func _find_nearest_tower_target(attack_range: float, creeps_only: bool) -> Actor:
	var best: Actor = null
	var best_distance_squared := attack_range * attack_range

	for node in get_tree().get_nodes_in_group("combat_actor"):
		var actor := node as Actor
		if actor == null or actor.team == GameCatalog.TEAM_NEUTRAL or actor is BaseStructure or actor is TowerStructure or not can_damage(actor):
			continue
		if creeps_only and not (actor is LaneUnit):
			continue
		if not creeps_only and not (actor is HeroController) and not (actor is EnemyHeroAi):
			continue

		var distance_squared := global_position.distance_squared_to(actor.global_position)
		if distance_squared < best_distance_squared:
			best = actor
			best_distance_squared = distance_squared

	return best
