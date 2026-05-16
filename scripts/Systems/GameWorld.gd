class_name GameWorld
extends Node2D

signal game_ended(victory: bool)

@export var selected_hero_id := GameCatalog.DEFAULT_HERO_ID
@export var player_hero_scene: PackedScene
@export var enemy_hero_scene: PackedScene
@export var lane_unit_scene: PackedScene
@export var neutral_unit_scene: PackedScene
@export var base_scene: PackedScene
@export var tower_scene: PackedScene
@export var hud_scene: PackedScene
@export var shop_scene: PackedScene
@export var player_respawn_time := 8.0
@export var enemy_hero_respawn_time := 12.0

const PLAYABLE_RECT := Rect2(Vector2(-1400.0, -1400.0), Vector2(2800.0, 2800.0))
const CAMERA_RECT := Rect2(Vector2(-1580.0, -1500.0), Vector2(3160.0, 3260.0))
const WORLD_BOUND_THICKNESS := 80.0
const CAMERA_FOLLOW_OFFSET := Vector2(0.0, 80.0)

var _actors: Node2D
var _structures: Node2D
var _map_painter: MapPainter
var _camera: Camera2D
var _lane_manager: LaneManager
var _wave_spawner: WaveSpawner
var _neutral_spawner: NeutralCampSpawner
var _economy: EconomySystem
var _experience: ExperienceSystem
var _shop: ShopSystem
var _player_hero: HeroController
var _enemy_hero: EnemyHeroAi
var _hud: InGameHudController
var _shop_panel: ShopController
var _selected_actor: Actor
var _match_ended := false
var _player_respawn_remaining := 0.0
var _enemy_respawn_remaining := 0.0
var _order_marker_position := Vector2.ZERO
var _order_marker_timer := 0.0
var _order_marker_duration := 0.45
var _order_marker_is_attack := false


func _process(delta: float) -> void:
	_tick_respawns(delta)
	_tick_order_marker(delta)

	if _camera == null or _player_hero == null or not is_instance_valid(_player_hero):
		return

	var camera_target := _player_hero.global_position + CAMERA_FOLLOW_OFFSET
	_camera.global_position = _camera.global_position.lerp(camera_target, minf(1.0, delta * 6.0))


func _ready() -> void:
	_load_default_scenes()

	_create_camera()
	_actors = _get_or_create_node2d("Actors")
	_structures = _get_or_create_node2d("Structures")
	_spawn_world_bounds()
	_lane_manager = _get_or_create_lane_manager()
	_map_painter = _get_or_create_map_painter()
	_wave_spawner = _get_or_create_wave_spawner()
	_neutral_spawner = _get_or_create_neutral_spawner()
	_economy = _get_or_create_economy()
	_experience = _get_or_create_experience()
	_shop = _get_or_create_shop()

	_economy.reset_economy()
	_experience.reset_progress()
	_shop.bind(_economy)
	_shop.unit_upgraded.connect(_on_unit_upgraded)

	_wave_spawner.configure(_actors, lane_unit_scene, _lane_manager)
	_wave_spawner.unit_spawned.connect(_register_actor)
	_neutral_spawner.configure(_actors, neutral_unit_scene)
	_neutral_spawner.unit_spawned.connect(_register_actor)

	_spawn_bases()
	_spawn_base_walls()
	_spawn_lane_towers()
	_spawn_player_hero()
	_spawn_enemy_hero()
	_neutral_spawner.spawn_initial_camps()
	_wave_spawner.start_spawning()
	_create_ui()
	_select_actor(_player_hero)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_B:
		if _shop_panel != null:
			_shop_panel.toggle()

	if event is InputEventMouseButton and event.pressed:
		var mouse_event := event as InputEventMouseButton
		var mouse_position := get_global_mouse_position()
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			var clicked_actor := _find_actor_at(mouse_position)
			if clicked_actor != null:
				_select_actor(clicked_actor)
		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			_handle_right_click_order(mouse_position)


func _load_default_scenes() -> void:
	if player_hero_scene == null:
		player_hero_scene = load("res://scenes/Characters/Hero.tscn")
	if enemy_hero_scene == null:
		enemy_hero_scene = load("res://scenes/Characters/EnemyHero.tscn")
	if lane_unit_scene == null:
		lane_unit_scene = load("res://scenes/Units/LaneUnit.tscn")
	if neutral_unit_scene == null:
		neutral_unit_scene = load("res://scenes/Units/NeutralUnit.tscn")
	if base_scene == null:
		base_scene = load("res://scenes/Structures/BaseStructure.tscn")
	if tower_scene == null:
		tower_scene = load("res://scenes/Structures/TowerStructure.tscn")
	if hud_scene == null:
		hud_scene = load("res://scenes/UI/InGameHud.tscn")
	if shop_scene == null:
		shop_scene = load("res://scenes/UI/ShopPanel.tscn")


func _spawn_bases() -> void:
	_spawn_base(GameCatalog.TEAM_PLAYER)
	_spawn_base(GameCatalog.TEAM_ENEMY)


func _spawn_base_walls() -> void:
	for team in [GameCatalog.TEAM_PLAYER, GameCatalog.TEAM_ENEMY]:
		for wall_segment in _lane_manager.get_base_wall_segments(team):
			_spawn_base_wall_segment(wall_segment)


func _spawn_world_bounds() -> void:
	var center := PLAYABLE_RECT.get_center()
	var half_thickness := WORLD_BOUND_THICKNESS * 0.5

	_spawn_world_bound(
		"WorldBoundTop",
		Vector2(center.x, PLAYABLE_RECT.position.y - half_thickness),
		Vector2(PLAYABLE_RECT.size.x + WORLD_BOUND_THICKNESS * 2.0, WORLD_BOUND_THICKNESS)
	)
	_spawn_world_bound(
		"WorldBoundBottom",
		Vector2(center.x, PLAYABLE_RECT.end.y + half_thickness),
		Vector2(PLAYABLE_RECT.size.x + WORLD_BOUND_THICKNESS * 2.0, WORLD_BOUND_THICKNESS)
	)
	_spawn_world_bound(
		"WorldBoundLeft",
		Vector2(PLAYABLE_RECT.position.x - half_thickness, center.y),
		Vector2(WORLD_BOUND_THICKNESS, PLAYABLE_RECT.size.y + WORLD_BOUND_THICKNESS * 2.0)
	)
	_spawn_world_bound(
		"WorldBoundRight",
		Vector2(PLAYABLE_RECT.end.x + half_thickness, center.y),
		Vector2(WORLD_BOUND_THICKNESS, PLAYABLE_RECT.size.y + WORLD_BOUND_THICKNESS * 2.0)
	)


func _spawn_world_bound(bound_name: String, bound_center: Vector2, bound_size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.name = bound_name
	body.global_position = bound_center
	body.add_to_group("world_bound")

	var shape := RectangleShape2D.new()
	shape.size = bound_size

	var collision := CollisionShape2D.new()
	collision.shape = shape
	body.add_child(collision)

	_structures.add_child(body)


func _spawn_base_wall_segment(wall_segment: Dictionary) -> void:
	var body := StaticBody2D.new()
	body.name = "BaseWall"
	var wall_center: Vector2 = wall_segment.get("center", Vector2.ZERO)
	var wall_size: Vector2 = wall_segment.get("size", Vector2.ZERO)
	body.global_position = wall_center
	body.global_rotation = float(wall_segment.get("rotation", 0.0))
	body.add_to_group("base_wall")

	var shape := RectangleShape2D.new()
	shape.size = wall_size

	var collision := CollisionShape2D.new()
	collision.shape = shape
	body.add_child(collision)

	_structures.add_child(body)


func _spawn_base(team: String) -> void:
	var base_structure := base_scene.instantiate() as BaseStructure
	_structures.add_child(base_structure)
	base_structure.configure_base(team, _lane_manager.get_base_position(team))
	_register_actor(base_structure)


func _spawn_lane_towers() -> void:
	_spawn_towers_for_team(GameCatalog.TEAM_PLAYER)
	_spawn_towers_for_team(GameCatalog.TEAM_ENEMY)


func _spawn_towers_for_team(team: String) -> void:
	for tower_data in _lane_manager.get_lane_tower_layout(team):
		var tower := tower_scene.instantiate() as TowerStructure
		var tower_lane := String(tower_data.get("lane", GameCatalog.LANE_MIDDLE))
		var tower_position: Vector2 = tower_data.get("position", Vector2.ZERO)
		var tower_tier := int(tower_data.get("tier", 1))
		_structures.add_child(tower)
		tower.configure_tower(team, tower_lane, tower_position, tower_tier)
		_register_actor(tower)


func _spawn_player_hero() -> void:
	var heroes := GameCatalog.create_hero_definitions()
	var definition: Dictionary = heroes.get(selected_hero_id, heroes[GameCatalog.DEFAULT_HERO_ID])
	_player_hero = player_hero_scene.instantiate() as HeroController
	_actors.add_child(_player_hero)
	_player_hero.configure_hero(definition)
	_player_hero.global_position = _lane_manager.get_hero_spawn(GameCatalog.TEAM_PLAYER)
	_register_actor(_player_hero)


func _spawn_enemy_hero() -> void:
	_enemy_hero = enemy_hero_scene.instantiate() as EnemyHeroAi
	_actors.add_child(_enemy_hero)
	_enemy_hero.configure(GameCatalog.TEAM_ENEMY, GameCatalog.LANE_MIDDLE, GameCatalog.create_enemy_hero_stats())
	_enemy_hero.global_position = _lane_manager.get_hero_spawn(GameCatalog.TEAM_ENEMY)
	_enemy_hero.objective_position = _lane_manager.get_base_position(GameCatalog.TEAM_PLAYER)
	_register_actor(_enemy_hero)


func _create_ui() -> void:
	var ui_layer := _get_or_create_ui_layer()

	_hud = hud_scene.instantiate() as InGameHudController
	ui_layer.add_child(_hud)
	_hud.bind(_economy, _experience, _player_hero)
	_hud.shop_requested.connect(_toggle_shop)

	_shop_panel = shop_scene.instantiate() as ShopController
	ui_layer.add_child(_shop_panel)
	_shop_panel.bind(_shop, _economy)
	_shop_panel.visible = false


func _register_actor(actor: Actor) -> void:
	if actor == null:
		return

	actor.died.connect(_on_actor_died)


func _on_actor_died(victim: Actor, killer: Actor) -> void:
	if _match_ended or victim == null:
		return

	if killer != null and killer.team == GameCatalog.TEAM_PLAYER and victim.team != GameCatalog.TEAM_PLAYER:
		_economy.add_gold(int(victim.stats.get("gold_reward", 0)))
		_experience.add_experience(int(victim.stats.get("experience_reward", 0)))

	if victim == _selected_actor:
		_select_actor(null)

	if victim is BaseStructure:
		_match_ended = true
		_wave_spawner.stop_spawning()
		game_ended.emit(victim.team == GameCatalog.TEAM_ENEMY)
		return

	if victim == _player_hero:
		_start_player_respawn()
	elif victim == _enemy_hero:
		_start_enemy_respawn()


func _on_unit_upgraded(unit_id: String, level: int) -> void:
	_wave_spawner.set_unit_upgrade_level(unit_id, level)


func _toggle_shop() -> void:
	if _shop_panel != null:
		_shop_panel.toggle()


func _start_player_respawn() -> void:
	_player_respawn_remaining = player_respawn_time
	if _hud != null:
		_hud.set_respawn_time(_player_respawn_remaining)


func _start_enemy_respawn() -> void:
	_enemy_respawn_remaining = enemy_hero_respawn_time


func _tick_respawns(delta: float) -> void:
	if _player_respawn_remaining > 0.0:
		_player_respawn_remaining = maxf(0.0, _player_respawn_remaining - delta)
		if _hud != null:
			_hud.set_respawn_time(_player_respawn_remaining)
		if _player_respawn_remaining <= 0.0:
			_respawn_player_hero()

	if _enemy_respawn_remaining > 0.0:
		_enemy_respawn_remaining = maxf(0.0, _enemy_respawn_remaining - delta)
		if _enemy_respawn_remaining <= 0.0:
			_spawn_enemy_hero()


func _respawn_player_hero() -> void:
	_spawn_player_hero()
	if _hud != null:
		_hud.bind(_economy, _experience, _player_hero)
		_hud.set_respawn_time(0.0)
	_select_actor(_player_hero)
	if _camera != null:
		_camera.global_position = _player_hero.global_position + CAMERA_FOLLOW_OFFSET


func _select_actor(actor: Actor) -> void:
	if _selected_actor != null and is_instance_valid(_selected_actor):
		_selected_actor.set_selected(false)

	_selected_actor = actor
	if _selected_actor != null:
		_selected_actor.set_selected(true)

	if _hud != null:
		_hud.show_selected_actor(_selected_actor)


func _handle_right_click_order(target_position: Vector2) -> void:
	if _selected_actor != _player_hero or _player_hero == null or not is_instance_valid(_player_hero) or not _player_hero.is_alive():
		return

	var clicked_actor := _find_actor_at(target_position)
	if clicked_actor != null and _player_hero.can_damage(clicked_actor):
		_player_hero.order_attack(clicked_actor)
		_show_order_marker(clicked_actor.global_position, true)
	else:
		var move_position := _clamp_to_playable_rect(target_position)
		_player_hero.order_move(move_position)
		_show_order_marker(move_position, false)


func _clamp_to_playable_rect(position: Vector2) -> Vector2:
	return Vector2(
		clampf(position.x, PLAYABLE_RECT.position.x, PLAYABLE_RECT.end.x),
		clampf(position.y, PLAYABLE_RECT.position.y, PLAYABLE_RECT.end.y)
	)


func _find_actor_at(position: Vector2) -> Actor:
	var best: Actor = null
	var best_distance_squared := INF

	for node in get_tree().get_nodes_in_group("combat_actor"):
		var actor := node as Actor
		if actor == null or not is_instance_valid(actor) or not actor.is_alive():
			continue

		var pick_radius := _get_actor_pick_radius(actor)
		var distance_squared := position.distance_squared_to(actor.global_position)
		if distance_squared <= pick_radius * pick_radius and distance_squared < best_distance_squared:
			best = actor
			best_distance_squared = distance_squared

	return best


func _get_actor_pick_radius(actor: Actor) -> float:
	if actor is BaseStructure:
		var base := actor as BaseStructure
		return maxf(base.size.length() * 0.42, 56.0)
	if actor is TowerStructure:
		var tower := actor as TowerStructure
		return maxf(tower.size.length() * 0.42, 34.0)

	return maxf(actor.draw_radius + 12.0, 24.0)


func _show_order_marker(position: Vector2, is_attack: bool) -> void:
	_order_marker_position = position
	_order_marker_timer = _order_marker_duration
	_order_marker_is_attack = is_attack
	queue_redraw()


func _tick_order_marker(delta: float) -> void:
	if _order_marker_timer <= 0.0:
		return

	_order_marker_timer = maxf(0.0, _order_marker_timer - delta)
	queue_redraw()


func _draw() -> void:
	if _order_marker_timer <= 0.0:
		return

	var progress := 1.0 - (_order_marker_timer / _order_marker_duration)
	var alpha := 1.0 - progress
	var radius := 12.0 + progress * 16.0
	var color := Color(0.95, 0.26, 0.18, alpha) if _order_marker_is_attack else Color(0.32, 1.0, 0.42, alpha)
	var dark := Color(0.02, 0.04, 0.02, alpha * 0.65)

	draw_arc(_order_marker_position, radius + 3.0, 0.0, TAU, 36, dark, 4.0)
	draw_arc(_order_marker_position, radius, 0.0, TAU, 36, color, 3.0)

	for direction in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
		var outer: Vector2 = _order_marker_position + direction * (radius + 12.0)
		var inner: Vector2 = _order_marker_position + direction * (radius + 3.0)
		var side: Vector2 = direction.orthogonal() * 5.0
		draw_colored_polygon(PackedVector2Array([outer, inner + side, inner - side]), color)


func _get_or_create_node2d(child_name: String) -> Node2D:
	var node := get_node_or_null(child_name) as Node2D
	if node != null:
		return node

	node = Node2D.new()
	node.name = child_name
	add_child(node)
	return node


func _create_camera() -> void:
	_camera = get_node_or_null("Camera2D") as Camera2D
	if _camera == null:
		_camera = Camera2D.new()
		_camera.name = "Camera2D"
		_camera.position = Vector2.ZERO
		add_child(_camera)

	_camera.zoom = Vector2(1.0, 1.0)
	_camera.limit_left = int(CAMERA_RECT.position.x)
	_camera.limit_right = int(CAMERA_RECT.end.x)
	_camera.limit_top = int(CAMERA_RECT.position.y)
	_camera.limit_bottom = int(CAMERA_RECT.end.y)
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = 7.0
	_camera.enabled = true
	_camera.make_current()


func _get_or_create_ui_layer() -> CanvasLayer:
	var node := get_node_or_null("UI") as CanvasLayer
	if node != null:
		return node

	node = CanvasLayer.new()
	node.name = "UI"
	add_child(node)
	return node


func _get_or_create_lane_manager() -> LaneManager:
	var node := get_node_or_null("LaneManager") as LaneManager
	if node != null:
		return node

	node = LaneManager.new()
	node.name = "LaneManager"
	add_child(node)
	return node


func _get_or_create_map_painter() -> MapPainter:
	var node := get_node_or_null("MapPainter") as MapPainter
	if node != null:
		move_child(node, 0)
		return node

	node = MapPainter.new()
	node.name = "MapPainter"
	add_child(node)
	move_child(node, 0)
	return node


func _get_systems_root() -> Node:
	var systems := get_node_or_null("Systems")
	if systems == null:
		systems = Node.new()
		systems.name = "Systems"
		add_child(systems)

	return systems


func _get_or_create_wave_spawner() -> WaveSpawner:
	var systems := _get_systems_root()
	var node := systems.get_node_or_null("WaveSpawner") as WaveSpawner
	if node != null:
		return node

	node = WaveSpawner.new()
	node.name = "WaveSpawner"
	systems.add_child(node)
	return node


func _get_or_create_neutral_spawner() -> NeutralCampSpawner:
	var systems := _get_systems_root()
	var node := systems.get_node_or_null("NeutralCampSpawner") as NeutralCampSpawner
	if node != null:
		return node

	node = NeutralCampSpawner.new()
	node.name = "NeutralCampSpawner"
	systems.add_child(node)
	return node


func _get_or_create_economy() -> EconomySystem:
	var systems := _get_systems_root()
	var node := systems.get_node_or_null("EconomySystem") as EconomySystem
	if node != null:
		return node

	node = EconomySystem.new()
	node.name = "EconomySystem"
	systems.add_child(node)
	return node


func _get_or_create_experience() -> ExperienceSystem:
	var systems := _get_systems_root()
	var node := systems.get_node_or_null("ExperienceSystem") as ExperienceSystem
	if node != null:
		return node

	node = ExperienceSystem.new()
	node.name = "ExperienceSystem"
	systems.add_child(node)
	return node


func _get_or_create_shop() -> ShopSystem:
	var systems := _get_systems_root()
	var node := systems.get_node_or_null("ShopSystem") as ShopSystem
	if node != null:
		return node

	node = ShopSystem.new()
	node.name = "ShopSystem"
	systems.add_child(node)
	return node
