class_name AbilityCaster
extends Node

signal ability_build_changed(points: int, levels: Array)

@export var owner_actor_path: NodePath = NodePath("..")
@export var abilities: Array = []

const PLAYABLE_RECT := Rect2(Vector2(-1400.0, -1400.0), Vector2(2800.0, 2800.0))
const MAX_ABILITY_LEVEL := 4

var _owner: Actor
var _cooldowns: Array[float] = []
var _ability_levels: Array[int] = []
var _unspent_ability_points := 0


func _ready() -> void:
	_owner = get_node_or_null(owner_actor_path) as Actor
	_reset_cooldowns()


func _process(delta: float) -> void:
	for i in range(_cooldowns.size()):
		if _cooldowns[i] > 0.0:
			_cooldowns[i] = maxf(0.0, _cooldowns[i] - delta)


func set_abilities(new_abilities: Array) -> void:
	abilities = new_abilities
	_reset_cooldowns()
	_reset_ability_levels()


func cast(slot: int, target_position: Vector2) -> bool:
	if _owner == null or slot < 0 or slot >= abilities.size() or slot >= _cooldowns.size():
		return false
	if not _owner.is_alive():
		return false
	if get_ability_level(slot) <= 0:
		return false

	var ability_definition: Dictionary = abilities[slot]
	var ability := _ability_for_level(ability_definition, get_ability_level(slot))
	if ability.is_empty() or _cooldowns[slot] > 0.0:
		return false

	_execute_ability(ability, target_position)
	_cooldowns[slot] = float(ability.get("cooldown", 1.0))
	return true


func get_cooldown(slot: int) -> float:
	if slot < 0 or slot >= _cooldowns.size():
		return 0.0

	return _cooldowns[slot]


func get_ability_level(slot: int) -> int:
	if slot < 0 or slot >= _ability_levels.size():
		return 0

	return _ability_levels[slot]


func get_ability_levels() -> Array:
	return _ability_levels.duplicate()


func get_unspent_ability_points() -> int:
	return _unspent_ability_points


func grant_ability_points(amount: int) -> void:
	if amount <= 0:
		return

	_unspent_ability_points += amount
	_emit_ability_build_changed()


func try_upgrade_ability(slot: int) -> bool:
	if _unspent_ability_points <= 0 or slot < 0 or slot >= _ability_levels.size():
		return false
	if _ability_levels[slot] >= MAX_ABILITY_LEVEL:
		return false

	_ability_levels[slot] += 1
	_unspent_ability_points -= 1
	_emit_ability_build_changed()
	return true


func apply_ability_build(points: int, levels: Array) -> void:
	_unspent_ability_points = maxi(0, points)
	_ability_levels.clear()
	_ability_levels.resize(abilities.size())
	for i in range(_ability_levels.size()):
		var stored_level := int(levels[i]) if i < levels.size() else 0
		_ability_levels[i] = clampi(stored_level, 0, MAX_ABILITY_LEVEL)

	_emit_ability_build_changed()


func _execute_ability(ability: Dictionary, target_position: Vector2) -> void:
	_spawn_ability_effect(ability, target_position)

	match String(ability.get("id", "")):
		"piercing_arrow":
			_damage_enemies_along_line(_owner.global_position, _limited_target(target_position, float(ability.get("range", 0.0))), float(ability.get("radius", 0.0)), float(ability.get("power", 0.0)))
		"mark_prey":
			_mark_prey(target_position, ability)
		"nature_dash":
			_owner.apply_move_speed_multiplier(1.85, 2.4)
		"hail_of_arrows":
			_hail_of_arrows(target_position, ability)
		"healing_melody":
			_heal_allies_in_radius(_owner.global_position, float(ability.get("radius", 0.0)), float(ability.get("power", 0.0)))
		"swamp_ritual":
			_swamp_ritual(target_position, ability)
		"frog_jump":
			_dash_toward(target_position, float(ability.get("range", 0.0)))
			_damage_enemies_in_radius(_owner.global_position, float(ability.get("radius", 0.0)), float(ability.get("power", 0.0)))
		"sticky_tongue":
			_sticky_tongue(target_position, ability)
		"whirlwind":
			_damage_enemies_in_radius(_owner.global_position, float(ability.get("radius", 0.0)), float(ability.get("power", 0.0)))
		"blood_rage":
			_owner.apply_move_speed_multiplier(1.45, 4.0)
			_owner.apply_attack_damage_multiplier(1.35, 4.0)
			_owner.heal(float(ability.get("power", 0.0)) * 0.75)
		"battle_cry":
			_battle_cry(ability)
		"berserkers_call":
			_berserkers_call(ability)
		"fire_sphere":
			_damage_enemies_in_radius(_limited_target(target_position, float(ability.get("range", 0.0))), float(ability.get("radius", 0.0)), float(ability.get("power", 0.0)))
		"ice_sphere":
			_ice_sphere(target_position, ability)
		"water_sphere":
			_owner.heal(float(ability.get("power", 0.0)))
		"void_sphere":
			_void_sphere(target_position, ability)
		"alpha_wolf":
			_spawn_companion("wolf", _owner.global_position + Vector2(28.0, -16.0), null, Vector2.ZERO)
		"thorns":
			_thorns(target_position, ability)
		"summon_treant":
			_spawn_companion("treant", _limited_target(target_position, float(ability.get("range", 0.0))), null, _get_enemy_base_position())
		"snake_charmer":
			_snake_charmer(target_position, ability)
		_:
			_damage_enemies_in_radius(target_position, maxf(float(ability.get("radius", 0.0)), 32.0), float(ability.get("power", 0.0)))

	print("%s cast %s" % [_owner.name, String(ability.get("display_name", "Ability"))])


func _spawn_ability_effect(ability: Dictionary, target_position: Vector2) -> void:
	var effect_parent: Node = get_tree().current_scene
	if effect_parent == null:
		effect_parent = _owner.get_parent()
	if effect_parent == null:
		return

	var targeting := String(ability.get("targeting", "area"))
	var effect_target: Vector2 = _ability_effect_target(ability, target_position, targeting)
	var effect: AbilityEffect = AbilityEffect.new()
	effect_parent.add_child(effect)
	effect.configure_ability(
		_owner.global_position,
		effect_target,
		float(ability.get("radius", 0.0)),
		_ability_effect_color(String(ability.get("id", ""))),
		targeting,
		String(ability.get("id", ""))
	)


func _ability_effect_target(ability: Dictionary, target_position: Vector2, targeting: String) -> Vector2:
	match targeting:
		"self":
			return _owner.global_position
		"direction", "area", "point":
			return _limited_target(target_position, float(ability.get("range", 0.0)))
		"single_target":
			var target: Actor = _find_nearest_enemy_to_point(target_position, float(ability.get("range", 0.0)))
			if target != null:
				return target.global_position
			return _limited_target(target_position, float(ability.get("range", 0.0)))
		_:
			return target_position


func _ability_effect_color(ability_id: String) -> Color:
	match ability_id:
		"piercing_arrow", "mark_prey", "nature_dash", "hail_of_arrows":
			return Color(0.58, 1.0, 0.42)
		"healing_melody", "swamp_ritual", "frog_jump", "sticky_tongue":
			return Color(0.36, 0.88, 1.0)
		"whirlwind", "blood_rage", "battle_cry", "berserkers_call":
			return Color(1.0, 0.38, 0.22)
		"fire_sphere":
			return Color(1.0, 0.34, 0.18)
		"ice_sphere", "water_sphere":
			return Color(0.48, 0.82, 1.0)
		"void_sphere":
			return Color(0.72, 0.42, 1.0)
		"alpha_wolf", "thorns", "summon_treant", "snake_charmer":
			return Color(0.38, 0.86, 0.32)
		_:
			return Color(1.0, 0.88, 0.36)


func _dash_toward(target_position: Vector2, max_distance: float) -> void:
	var dash_target := _limited_target(target_position, max_distance)
	_owner.global_position = _clamp_to_playable_rect(_owner.global_position.move_toward(dash_target, max_distance))


func _heal_allies_in_radius(center: Vector2, radius: float, amount: float) -> void:
	for node in get_tree().get_nodes_in_group("combat_actor"):
		var actor := node as Actor
		if actor != null and actor.team == _owner.team and actor.global_position.distance_to(center) <= radius:
			actor.heal(amount)


func _damage_enemies_in_radius(center: Vector2, radius: float, damage: float) -> void:
	for node in get_tree().get_nodes_in_group("combat_actor"):
		var actor := node as Actor
		if actor != null and _owner.can_damage(actor) and actor.global_position.distance_to(center) <= radius:
			actor.take_damage(damage, _owner)


func _apply_to_enemies_in_radius(center: Vector2, radius: float, callback: Callable) -> void:
	for node in get_tree().get_nodes_in_group("combat_actor"):
		var actor := node as Actor
		if actor != null and _owner.can_damage(actor) and actor.global_position.distance_to(center) <= radius:
			callback.call(actor)


func _apply_to_allies_in_radius(center: Vector2, radius: float, callback: Callable) -> void:
	for node in get_tree().get_nodes_in_group("combat_actor"):
		var actor := node as Actor
		if actor != null and actor.team == _owner.team and actor.global_position.distance_to(center) <= radius:
			callback.call(actor)


func _damage_enemies_along_line(origin: Vector2, target_position: Vector2, width: float, damage: float) -> void:
	var end := origin.move_toward(target_position, maxf(origin.distance_to(target_position), 1.0))

	for node in get_tree().get_nodes_in_group("combat_actor"):
		var actor := node as Actor
		if actor == null or not _owner.can_damage(actor):
			continue

		if _distance_point_to_segment(actor.global_position, origin, end) <= maxf(width, 18.0):
			actor.take_damage(damage, _owner)


func _damage_nearest_enemy_to_point(point: Vector2, search_radius: float, damage: float) -> void:
	var best := _find_nearest_enemy_to_point(point, search_radius)

	if best != null:
		best.take_damage(damage, _owner)


func _find_nearest_enemy_to_point(point: Vector2, search_radius: float) -> Actor:
	var best: Actor = null
	var best_distance_squared := search_radius * search_radius

	for node in get_tree().get_nodes_in_group("combat_actor"):
		var actor := node as Actor
		if actor == null or not _owner.can_damage(actor):
			continue

		var distance_squared := point.distance_squared_to(actor.global_position)
		if distance_squared < best_distance_squared:
			best = actor
			best_distance_squared = distance_squared

	return best


func _mark_prey(target_position: Vector2, ability: Dictionary) -> void:
	var target := _find_nearest_enemy_to_point(target_position, float(ability.get("range", 0.0)))
	if target == null:
		return

	target.apply_vulnerability(1.45, 5.0)
	target.take_damage(float(ability.get("power", 0.0)) * 0.55, _owner)


func _hail_of_arrows(target_position: Vector2, ability: Dictionary) -> void:
	var center := _limited_target(target_position, float(ability.get("range", 0.0)))
	var radius := float(ability.get("radius", 0.0))
	var damage := float(ability.get("power", 0.0)) / 3.0
	_apply_to_enemies_in_radius(center, radius, func(actor: Actor) -> void:
		actor.take_damage(damage, _owner)
		actor.take_damage(damage, _owner)
		actor.take_damage(damage, _owner)
	)


func _swamp_ritual(target_position: Vector2, ability: Dictionary) -> void:
	var center := _limited_target(target_position, float(ability.get("range", 0.0)))
	var radius := float(ability.get("radius", 0.0))
	var power := float(ability.get("power", 0.0))
	_apply_to_enemies_in_radius(center, radius, func(actor: Actor) -> void:
		actor.take_damage(power, _owner)
		actor.apply_move_speed_multiplier(0.62, 4.0)
		actor.apply_vulnerability(1.18, 4.0)
	)
	_apply_to_allies_in_radius(center, radius, func(actor: Actor) -> void:
		actor.heal(power * 0.6)
		actor.apply_damage_reduction(0.86, 4.0)
	)


func _sticky_tongue(target_position: Vector2, ability: Dictionary) -> void:
	var target := _find_nearest_enemy_to_point(target_position, float(ability.get("range", 0.0)))
	if target == null:
		return

	target.pull_toward(_owner.global_position, 95.0)
	target.apply_move_speed_multiplier(0.55, 2.0)
	target.take_damage(float(ability.get("power", 0.0)), _owner)


func _battle_cry(ability: Dictionary) -> void:
	_apply_to_allies_in_radius(_owner.global_position, float(ability.get("radius", 0.0)), func(actor: Actor) -> void:
		actor.apply_damage_reduction(0.62, 5.0)
	)


func _berserkers_call(ability: Dictionary) -> void:
	_apply_to_enemies_in_radius(_owner.global_position, float(ability.get("radius", 0.0)), func(actor: Actor) -> void:
		actor.force_target(_owner, 3.5)
		actor.take_damage(float(ability.get("power", 0.0)) * 0.5, _owner)
	)


func _ice_sphere(target_position: Vector2, ability: Dictionary) -> void:
	var end := _limited_target(target_position, float(ability.get("range", 0.0)))
	for node in get_tree().get_nodes_in_group("combat_actor"):
		var actor := node as Actor
		if actor == null or not _owner.can_damage(actor):
			continue

		if _distance_point_to_segment(actor.global_position, _owner.global_position, end) <= maxf(float(ability.get("radius", 0.0)), 42.0):
			actor.take_damage(float(ability.get("power", 0.0)), _owner)
			actor.apply_move_speed_multiplier(0.0, 1.8)


func _void_sphere(target_position: Vector2, ability: Dictionary) -> void:
	var center := _limited_target(target_position, float(ability.get("range", 0.0)))
	_apply_to_enemies_in_radius(center, float(ability.get("radius", 0.0)), func(actor: Actor) -> void:
		actor.pull_toward(center, 120.0)
		actor.apply_move_speed_multiplier(0.35, 2.5)
		actor.take_damage(float(ability.get("power", 0.0)), _owner)
	)


func _thorns(target_position: Vector2, ability: Dictionary) -> void:
	var center := _limited_target(target_position, float(ability.get("range", 0.0)))
	_apply_to_enemies_in_radius(center, float(ability.get("radius", 0.0)), func(actor: Actor) -> void:
		actor.take_damage(float(ability.get("power", 0.0)), _owner)
		actor.apply_move_speed_multiplier(0.72, 4.0)
		actor.apply_vulnerability(1.12, 4.0)
	)


func _snake_charmer(target_position: Vector2, ability: Dictionary) -> void:
	var target := _find_nearest_enemy_to_point(target_position, float(ability.get("range", 0.0)))
	if target == null:
		_damage_nearest_enemy_to_point(target_position, float(ability.get("range", 0.0)), float(ability.get("power", 0.0)))
		return

	_spawn_companion("snake", _owner.global_position + Vector2(18.0, 10.0), target, target.global_position)
	target.take_damage(float(ability.get("power", 0.0)) * 0.35, _owner)


func _spawn_companion(kind: String, position: Vector2, target: Actor, objective: Vector2) -> void:
	var companion := SummonedCompanion.new()
	var parent := _owner.get_parent()
	if parent == null:
		parent = get_tree().current_scene
	parent.add_child(companion)
	companion.configure_companion(kind, _owner, _clamp_to_playable_rect(position), _companion_stats(kind), target, _clamp_to_playable_rect(objective))


func _companion_stats(kind: String) -> Dictionary:
	match kind:
		"treant":
			return GameCatalog.stats(210.0, 68.0, 22.0, 46.0, 1.15, 0, 0)
		"snake":
			return GameCatalog.stats(75.0, 185.0, 13.0, 30.0, 0.55, 0, 0)
		_:
			return GameCatalog.stats(95.0, 145.0, 15.0, 38.0, 0.75, 0, 0)


func _get_enemy_base_position() -> Vector2:
	var fallback := Vector2(1245.0, -1255.0) if _owner.team == GameCatalog.TEAM_PLAYER else Vector2(-1245.0, 1255.0)
	for node in get_tree().get_nodes_in_group("combat_actor"):
		var actor := node as BaseStructure
		if actor != null and _owner.can_damage(actor):
			return actor.global_position

	return fallback


func _limited_target(target_position: Vector2, max_range: float) -> Vector2:
	if max_range <= 0.0:
		return _clamp_to_playable_rect(target_position)

	return _clamp_to_playable_rect(_owner.global_position.move_toward(target_position, max_range))


func _clamp_to_playable_rect(position: Vector2) -> Vector2:
	return Vector2(
		clampf(position.x, PLAYABLE_RECT.position.x, PLAYABLE_RECT.end.x),
		clampf(position.y, PLAYABLE_RECT.position.y, PLAYABLE_RECT.end.y)
	)


func _reset_cooldowns() -> void:
	_cooldowns.clear()
	_cooldowns.resize(abilities.size())
	for i in range(_cooldowns.size()):
		_cooldowns[i] = 0.0


func _reset_ability_levels() -> void:
	_ability_levels.clear()
	_ability_levels.resize(abilities.size())
	for i in range(_ability_levels.size()):
		_ability_levels[i] = 0
	_unspent_ability_points = 0
	_emit_ability_build_changed()


func _ability_for_level(ability: Dictionary, level: int) -> Dictionary:
	if ability.is_empty():
		return {}

	var scaled := ability.duplicate(true)
	var power := float(scaled.get("power", 0.0))
	scaled["power"] = power * (1.0 + float(maxi(level, 1) - 1) * 0.25)
	return scaled


func _emit_ability_build_changed() -> void:
	ability_build_changed.emit(_unspent_ability_points, get_ability_levels())


func _distance_point_to_segment(point: Vector2, start: Vector2, end: Vector2) -> float:
	var segment := end - start
	var length_squared := segment.length_squared()

	if length_squared <= 0.001:
		return point.distance_to(start)

	var t := clampf((point - start).dot(segment) / length_squared, 0.0, 1.0)
	var projection := start + segment * t
	return point.distance_to(projection)
