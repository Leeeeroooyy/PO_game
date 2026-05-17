class_name HeroController
extends Actor

signal ability_build_changed(points: int, levels: Array)

@export var ability_caster_path: NodePath = NodePath("AbilityCaster")
@export var order_stop_distance := 8.0

var hero_id := GameCatalog.DEFAULT_HERO_ID
var _ability_caster: AbilityCaster
var _hero_body_color := Color(0.25, 0.78, 0.38)
var _has_move_order := false
var _move_target := Vector2.ZERO
var _attack_target: Actor


func _ready() -> void:
	super._ready()
	_bind_ability_caster()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if not is_alive():
		velocity = Vector2.ZERO
		return

	if _attack_target != null and (not is_instance_valid(_attack_target) or not can_damage(_attack_target)):
		_attack_target = null

	if _attack_target != null:
		if global_position.distance_to(_attack_target.global_position) > _stat("attack_range"):
			_move_toward(_attack_target.global_position)
		else:
			velocity = Vector2.ZERO
			try_attack(_attack_target)
	elif _has_move_order:
		if global_position.distance_to(_move_target) <= order_stop_distance:
			_has_move_order = false
			velocity = Vector2.ZERO
		else:
			_move_toward(_move_target)
	else:
		velocity = Vector2.ZERO

	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if not is_alive() or _ability_caster == null or not is_selected:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		var mouse_position := get_global_mouse_position()
		if event.keycode == KEY_1:
			_ability_caster.cast(0, mouse_position)
		elif event.keycode == KEY_2:
			_ability_caster.cast(1, mouse_position)
		elif event.keycode == KEY_3:
			_ability_caster.cast(2, mouse_position)
		elif event.keycode == KEY_4:
			_ability_caster.cast(3, mouse_position)


func configure_hero(definition: Dictionary) -> void:
	if definition.is_empty():
		return

	hero_id = String(definition.get("id", GameCatalog.DEFAULT_HERO_ID))
	_hero_body_color = _color_for_hero(hero_id)
	configure(GameCatalog.TEAM_PLAYER, GameCatalog.LANE_MIDDLE, definition.get("stats", {}))

	_bind_ability_caster()
	if _ability_caster != null:
		_ability_caster.set_abilities(definition.get("abilities", []))


func order_move(target_position: Vector2) -> void:
	_attack_target = null
	_move_target = target_position
	_has_move_order = true


func order_attack(target: Actor) -> void:
	if not can_damage(target):
		return

	_attack_target = target
	_has_move_order = false


func clear_orders() -> void:
	_attack_target = null
	_has_move_order = false
	velocity = Vector2.ZERO


func get_attack_target() -> Actor:
	return _attack_target if _attack_target != null and is_instance_valid(_attack_target) and can_damage(_attack_target) else null


func get_abilities() -> Array:
	if _ability_caster == null:
		return []

	return _ability_caster.abilities


func get_ability_cooldown(slot: int) -> float:
	if _ability_caster == null:
		return 0.0

	return _ability_caster.get_cooldown(slot)


func get_ability_level(slot: int) -> int:
	if _ability_caster == null:
		return 0

	return _ability_caster.get_ability_level(slot)


func get_ability_levels() -> Array:
	if _ability_caster == null:
		return []

	return _ability_caster.get_ability_levels()


func get_unspent_ability_points() -> int:
	if _ability_caster == null:
		return 0

	return _ability_caster.get_unspent_ability_points()


func grant_ability_points(amount: int) -> void:
	if _ability_caster != null:
		_ability_caster.grant_ability_points(amount)


func try_upgrade_ability(slot: int) -> bool:
	if _ability_caster == null:
		return false

	return _ability_caster.try_upgrade_ability(slot)


func apply_ability_build(points: int, levels: Array) -> void:
	if _ability_caster != null:
		_ability_caster.apply_ability_build(points, levels)


func get_hero_color() -> Color:
	return _hero_body_color


func _draw() -> void:
	draw_arc(Vector2.ZERO, draw_radius + 8.0, 0.0, TAU, 36, _hero_body_color.lightened(0.35), 2.5)
	super._draw()
	draw_circle(Vector2(0.0, -draw_radius * 1.42), 3.5, _hero_body_color.lightened(0.55))


func _move_toward(point: Vector2) -> void:
	velocity = global_position.direction_to(point) * get_move_speed()


func _get_team_color() -> Color:
	return _hero_body_color


func _bind_ability_caster() -> void:
	_ability_caster = get_node_or_null(ability_caster_path) as AbilityCaster
	if _ability_caster != null and not _ability_caster.ability_build_changed.is_connected(_on_ability_build_changed):
		_ability_caster.ability_build_changed.connect(_on_ability_build_changed)


func _on_ability_build_changed(points: int, levels: Array) -> void:
	ability_build_changed.emit(points, levels)


func _color_for_hero(id: String) -> Color:
	match id:
		"bard_frog":
			return Color(0.35, 0.78, 0.92)
		"axe_barbarian":
			return Color(0.90, 0.38, 0.22)
		"sorcerer":
			return Color(0.65, 0.45, 1.0)
		"ancient_druid":
			return Color(0.28, 0.66, 0.26)
		_:
			return Color(0.34, 0.78, 0.36)
