class_name NeutralUnit
extends Actor

const UnitArtRenderer := preload("res://scripts/Visuals/UnitArt.gd")

@export var leash_radius := 180.0
@export var unit_id := "neutral_bruiser"

const AGGRO_RANGE := 125.0
const SOFT_SEPARATION_FORCE := 70.0
const IDLE_SEPARATION_SPEED_FACTOR := 0.34
const RETURN_REGEN_PER_SECOND := 18.0

var _home_position := Vector2.ZERO
var _aggro_target: Actor


func _ready() -> void:
	super._ready()
	_home_position = global_position


func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if not is_alive():
		velocity = Vector2.ZERO
		return

	var target := _choose_aggro_target()

	if target != null:
		if try_attack(target):
			velocity = _with_soft_separation(Vector2.ZERO)
		else:
			velocity = _with_soft_separation(global_position.direction_to(target.global_position) * get_move_speed())
	else:
		_return_home()

	move_and_slide()


func take_damage(amount: float, source: Actor) -> void:
	if source != null:
		_aggro_target = source

	super.take_damage(amount, source)


func configure_neutral(new_unit_id: String, position: Vector2, new_stats: Dictionary) -> void:
	unit_id = new_unit_id
	global_position = position
	_home_position = position
	_aggro_target = null
	collision_layer = 0
	collision_mask = 0
	configure(GameCatalog.TEAM_NEUTRAL, GameCatalog.LANE_MIDDLE, new_stats)
	queue_redraw()


func _draw_unit_body(_team_color: Color) -> void:
	UnitArtRenderer.draw_neutral(self, unit_id, draw_radius)


func get_hit_radius() -> float:
	if unit_id == "neutral_claw":
		return draw_radius * 1.75

	return draw_radius * 1.55


func get_pick_radius() -> float:
	return draw_radius * 3.0


func _get_health_bar_offset() -> float:
	return draw_radius * 4.0 + 8.0


func _get_projectile_kind(is_ranged_attack: bool) -> String:
	if not is_ranged_attack:
		return "slash"

	match unit_id:
		"neutral_spitter":
			return "spit"
		"neutral_thrower":
			return "stone"
		_:
			return "bolt"


func _choose_aggro_target() -> Actor:
	if _is_valid_aggro_target(_aggro_target):
		return _aggro_target

	_aggro_target = _find_aggro_target()
	return _aggro_target


func _find_aggro_target() -> Actor:
	if _is_outside_leash():
		return null

	var best: Actor = null
	var best_distance := AGGRO_RANGE

	for node in get_tree().get_nodes_in_group("combat_actor"):
		var actor := node as Actor
		if actor == null or actor == self or not is_instance_valid(actor) or not actor.is_alive() or not can_damage(actor):
			continue
		if actor.team == GameCatalog.TEAM_NEUTRAL:
			continue

		var edge_distance := maxf(0.0, global_position.distance_to(actor.global_position) - actor.get_hit_radius())
		if edge_distance <= best_distance:
			best = actor
			best_distance = edge_distance

	return best


func _is_valid_aggro_target(candidate) -> bool:
	if candidate == null or not is_instance_valid(candidate):
		return false

	var actor := candidate as Actor
	if actor == null:
		return false

	return (
		actor.is_alive()
		and can_damage(actor)
		and actor.team != GameCatalog.TEAM_NEUTRAL
		and not _is_outside_leash()
	)


func _is_outside_leash() -> bool:
	return _home_position.distance_to(global_position) > leash_radius


func _with_soft_separation(base_velocity: Vector2) -> Vector2:
	var push := Vector2.ZERO
	for node in get_tree().get_nodes_in_group("combat_actor"):
		var actor := node as Actor
		if actor == null or actor == self or not is_instance_valid(actor) or not actor.is_alive() or actor.team != team:
			continue
		if not (actor is NeutralUnit):
			continue

		var delta := global_position - actor.global_position
		var distance := delta.length()
		var spacing := get_hit_radius() + actor.get_hit_radius() + 8.0
		if distance >= spacing:
			continue

		var direction := delta / distance if distance > 0.01 else _fallback_separation_direction(actor)
		push += direction * ((spacing - distance) / spacing)

	var separation_velocity := push * SOFT_SEPARATION_FORCE
	if separation_velocity == Vector2.ZERO:
		return base_velocity

	var base_speed := base_velocity.length()
	if base_speed <= 0.01:
		return separation_velocity.limit_length(get_move_speed() * IDLE_SEPARATION_SPEED_FACTOR)

	var direction := base_velocity / base_speed
	var forward_amount := separation_velocity.dot(direction)
	var adjusted := base_velocity
	if forward_amount < 0.0:
		adjusted += direction * forward_amount

	adjusted += separation_velocity - direction * forward_amount
	if adjusted.length() > base_speed:
		adjusted = adjusted.normalized() * base_speed

	return adjusted


func _fallback_separation_direction(actor: Actor) -> Vector2:
	var angle := float(int(get_instance_id() + actor.get_instance_id()) % 360) * TAU / 360.0
	return Vector2.RIGHT.rotated(angle)


func _return_home() -> void:
	if global_position.distance_to(_home_position) < 6.0:
		velocity = Vector2.ZERO
		_aggro_target = null
		if health < _stat("max_health"):
			heal(RETURN_REGEN_PER_SECOND * get_physics_process_delta_time())
		return

	_aggro_target = null
	velocity = _with_soft_separation(global_position.direction_to(_home_position) * get_move_speed())
