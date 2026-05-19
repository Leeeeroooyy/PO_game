class_name GameRoot
extends Node

@export var main_menu_scene: PackedScene
@export var hero_select_scene: PackedScene
@export var game_world_scene: PackedScene

var _current_screen: Node


func _ready() -> void:
	_load_default_scenes()
	_show_main_menu()


func _load_default_scenes() -> void:
	if main_menu_scene == null:
		main_menu_scene = load("res://scenes/Menu/MainMenu.tscn")
	if hero_select_scene == null:
		hero_select_scene = load("res://scenes/UI/HeroSelect.tscn")
	if game_world_scene == null:
		game_world_scene = load("res://scenes/World/GameWorld.tscn")


func _show_main_menu() -> void:
	var audio := get_node_or_null("/root/AudioDirector")
	if audio != null and audio.has_method("play_menu_music"):
		audio.call("play_menu_music")

	var menu := main_menu_scene.instantiate() as MainMenuController
	menu.start_pressed.connect(_show_hero_select)
	menu.quit_pressed.connect(_quit_game)
	_replace_screen(menu)


func _show_hero_select() -> void:
	var hero_select := hero_select_scene.instantiate() as HeroSelectController
	hero_select.hero_chosen.connect(_start_game)
	hero_select.back_requested.connect(_show_main_menu)
	_replace_screen(hero_select)


func _start_game(hero_id: String) -> void:
	var audio := get_node_or_null("/root/AudioDirector")
	if audio != null and audio.has_method("play_game_music"):
		audio.call("play_game_music")

	var world := game_world_scene.instantiate() as GameWorld
	world.selected_hero_id = hero_id
	world.game_ended.connect(_on_game_ended)
	world.main_menu_requested.connect(_show_main_menu)
	_replace_screen(world)


func _on_game_ended(victory: bool) -> void:
	print("Victory" if victory else "Defeat")
	_show_main_menu()


func _quit_game() -> void:
	get_tree().quit()


func _replace_screen(next_screen: Node) -> void:
	get_tree().paused = false
	if _current_screen != null:
		remove_child(_current_screen)
		_current_screen.queue_free()

	_current_screen = next_screen
	add_child(_current_screen)
