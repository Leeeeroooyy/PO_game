class_name SummonedCompanion
extends Actor

const UnitArtRenderer := preload("res://scripts/Visuals/UnitArt.gd")

@export var companion_kind := "wolf"
@export var lifetime := 18.0
@export var aggro_range := 180.0

const SOFT_SEPARATION_FORCE := 74.0
const IDLE_SEPARATION_SPEED_FACTOR := 0.35

var owner_actor: Actor
var target_actor: Actor
var objective_position := Vector2.ZERO


func _ready() -> void:
	super._ready()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return

	if not is_alive():
		velocity = Vector2.ZERO
		return

	var target := _choose_target()
	if target != null:
		if not try_attack(target):
			velocity = _with_soft_separation(global_position.direction_to(target.global_position) * get_move_speed())
		else:
			velocity = _with_soft_separation(Vector2.ZERO)
	elif objective_position != Vector2.ZERO and global_position.distance_to(objective_position) > 12.0:
		velocity = _with_soft_separation(global_position.direction_to(objective_position) * get_move_speed())
	else:
		velocity = Vector2.ZERO

	move_and_slide()


func configure_companion(kind: String, owner: Actor, position: Vector2, new_stats: Dictionary, target: Actor = null, objective: Vector2 = Vector2.ZERO) -> void:
	companion_kind = kind
	owner_actor = owner
	target_actor = target
	objective_position = objective
	global_position = position
	collision_layer = 0
	collision_mask = 0
	configure(owner.team if owner != null else GameCatalog.TEAM_PLAYER, GameCatalog.LANE_MIDDLE, new_stats)
	add_to_group("team_%s_summons" % team)

	match companion_kind:
		"treant":
			draw_radius = 15.0
			lifetime = 30.0
			aggro_range = 150.0
		"snake":
			draw_radius = 7.0
			lifetime = 60.0
			aggro_range = 260.0
		_:
			draw_radius = 10.0
			lifetime = 22.0
			aggro_range = 170.0

	_sync_hitbox()
	queue_redraw()


func _choose_target() -> Actor:
	if target_actor != null and is_instance_valid(target_actor) and can_damage(target_actor):
		return target_actor

	if companion_kind == "snake" and target_actor != null:
		queue_free()
		return null

	return find_nearest_enemy(aggro_range)


func _draw_unit_body(team_color: Color) -> void:
	UnitArtRenderer.draw_companion(self, companion_kind, team_color, draw_radius)


func get_hit_radius() -> float:
	return draw_radius * 1.35


func get_pick_radius() -> float:
	return draw_radius * 2.6


func _get_health_bar_offset() -> float:
	return draw_radius * 3.2 + 8.0


func _with_soft_separation(base_velocity: Vector2) -> Vector2:
	var push := Vector2.ZERO
	for node in get_tree().get_nodes_in_group("combat_actor"):
		var actor := node as Actor
		if actor == null or actor == self or not is_instance_valid(actor) or not actor.is_alive() or actor.team != team:
			continue
		if not (actor is LaneUnit or actor is SummonedCompanion):
			continue

		var delta := global_position - actor.global_position
		var distance := delta.length()
		var spacing := get_hit_radius() + actor.get_hit_radius() + 6.0
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
