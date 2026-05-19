extends Node

signal volumes_changed(music_volume: float, effects_volume: float)

const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"
const SETTINGS_PATH := "user://audio_settings.cfg"
const DEFAULT_MUSIC_VOLUME := 0.75
const DEFAULT_EFFECTS_VOLUME := 0.85
const STRUCTURE_FIGHT_HOLD_TIME := 6.0
const ATTACK_SOUND_MIN_INTERVAL_MSEC := 45
const MUSIC_FADE_DURATION := 1.35
const MUSIC_SILENT_DB := -48.0

const MUSIC_PATHS := {
	"menu": [
		"res://assets/audio/music/main_menu_theme.ogg",
		"res://assets/audio/music/main_menu_theme.wav",
		"res://assets/audio/music/main_menu_theme.mp3",
	],
	"game": [
		"res://assets/audio/music/gameplay_theme.ogg",
		"res://assets/audio/music/gameplay_theme.wav",
		"res://assets/audio/music/gameplay_theme.mp3",
	],
	"enemy_structure_fight": [
		"res://assets/audio/music/enemy_structure_fight_theme.ogg",
		"res://assets/audio/music/enemy_structure_fight_theme.wav",
		"res://assets/audio/music/enemy_structure_fight_theme.mp3",
	],
	"dead": [
		"res://assets/audio/music/dead_theme.ogg",
		"res://assets/audio/music/dead_theme.wav",
		"res://assets/audio/music/dead_theme.mp3",
	],
}

const SFX_PATHS := {
	"melee": [
		"res://assets/audio/sfx/attack_melee.ogg",
		"res://assets/audio/sfx/attack_melee.wav",
		"res://assets/audio/sfx/attack_melee.mp3",
	],
	"ranged": [
		"res://assets/audio/sfx/attack_ranged.ogg",
		"res://assets/audio/sfx/attack_ranged.wav",
		"res://assets/audio/sfx/attack_ranged.mp3",
	],
	"tower": [
		"res://assets/audio/sfx/attack_tower.ogg",
		"res://assets/audio/sfx/attack_tower.wav",
		"res://assets/audio/sfx/attack_tower.mp3",
	],
}

var music_volume := DEFAULT_MUSIC_VOLUME
var effects_volume := DEFAULT_EFFECTS_VOLUME

var _music_players: Array[AudioStreamPlayer] = []
var _music_player_keys: Array[String] = []
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_cache := {}
var _music_cache := {}
var _last_attack_sound_msec := {}
var _requested_music_key := ""
var _base_music_key := ""
var _structure_fight_timer := 0.0
var _active_music_index := -1
var _music_fade_tween: Tween
var _audible_world_rect := Rect2()
var _has_audible_world_rect := false
var _sfx_blocked := false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_ensure_audio_bus(MUSIC_BUS)
	_ensure_audio_bus(SFX_BUS)
	_create_players()
	_load_settings()
	_apply_bus_volumes()
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	if _structure_fight_timer <= 0.0:
		return

	_structure_fight_timer = maxf(0.0, _structure_fight_timer - delta)
	if _structure_fight_timer <= 0.0 and _base_music_key == "game":
		_play_music_key("game")


func play_menu_music() -> void:
	_base_music_key = "menu"
	_structure_fight_timer = 0.0
	_play_music_key("menu")


func play_game_music() -> void:
	_base_music_key = "game"
	if _structure_fight_timer > 0.0:
		_play_music_key("enemy_structure_fight")
	else:
		_play_music_key("game")


func play_death_music() -> void:
	if _base_music_key != "game":
		return

	_structure_fight_timer = 0.0
	_sfx_blocked = true
	_play_music_key("dead")


func stop_death_music() -> void:
	if _base_music_key != "game":
		return

	_structure_fight_timer = 0.0
	_sfx_blocked = false
	_play_music_key("game")


func stop_music() -> void:
	_base_music_key = ""
	_requested_music_key = ""
	_stop_music_players()


func notify_enemy_structure_fight(duration := STRUCTURE_FIGHT_HOLD_TIME) -> void:
	if _base_music_key != "game":
		return

	_structure_fight_timer = maxf(_structure_fight_timer, duration)
	_play_music_key("enemy_structure_fight")


func set_audible_world_rect(rect: Rect2) -> void:
	_audible_world_rect = rect
	_has_audible_world_rect = rect.size.x > 0.0 and rect.size.y > 0.0


func clear_listener_context() -> void:
	_has_audible_world_rect = false


func set_effects_blocked(blocked: bool) -> void:
	_sfx_blocked = blocked


func play_attack_sound(kind: String, sound_position = null) -> void:
	if _sfx_blocked or effects_volume <= 0.001:
		return

	var sound_key := kind
	if not SFX_PATHS.has(sound_key):
		sound_key = "ranged" if kind != "melee" else "melee"

	var now := Time.get_ticks_msec()
	var last := int(_last_attack_sound_msec.get(sound_key, -ATTACK_SOUND_MIN_INTERVAL_MSEC))
	if now - last < ATTACK_SOUND_MIN_INTERVAL_MSEC:
		return

	var stream := _get_sfx_stream(sound_key)
	if stream == null:
		return

	if not _is_sound_position_audible(sound_position):
		return

	_last_attack_sound_msec[sound_key] = now
	var player := _get_available_sfx_player()
	player.stream = stream
	player.pitch_scale = _rng.randf_range(0.94, 1.06)
	player.volume_db = linear_to_db(_rng.randf_range(0.82, 1.0))
	player.play()


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_apply_bus_volumes()
	_save_settings()
	volumes_changed.emit(music_volume, effects_volume)


func set_effects_volume(value: float) -> void:
	effects_volume = clampf(value, 0.0, 1.0)
	_apply_bus_volumes()
	_save_settings()
	volumes_changed.emit(music_volume, effects_volume)


func get_music_volume() -> float:
	return music_volume


func get_effects_volume() -> float:
	return effects_volume


func _create_players() -> void:
	for i in range(2):
		var music_player := AudioStreamPlayer.new()
		music_player.name = "MusicPlayer%d" % i
		music_player.bus = MUSIC_BUS
		music_player.volume_db = MUSIC_SILENT_DB
		music_player.finished.connect(_on_music_finished.bind(music_player))
		add_child(music_player)
		_music_players.append(music_player)
		_music_player_keys.append("")

	for i in range(10):
		var player := AudioStreamPlayer.new()
		player.name = "SfxPlayer%d" % i
		player.bus = SFX_BUS
		add_child(player)
		_sfx_players.append(player)


func _play_music_key(key: String) -> void:
	if _requested_music_key == key and _active_music_index >= 0 and _music_players[_active_music_index].playing:
		return

	var stream := _get_music_stream(key)
	if stream == null:
		if key != "enemy_structure_fight" and key != "dead":
			_requested_music_key = key
			_fade_out_current_music(MUSIC_FADE_DURATION)
		return

	_requested_music_key = key
	_crossfade_to_stream(key, stream, MUSIC_FADE_DURATION)


func _crossfade_to_stream(key: String, stream: AudioStream, fade_duration: float) -> void:
	if _music_players.is_empty():
		return

	var previous_index := _active_music_index
	var next_index := 0 if previous_index != 0 else 1
	var next_player := _music_players[next_index]
	var previous_player := _music_players[previous_index] if previous_index >= 0 else null

	if _music_fade_tween != null:
		_music_fade_tween.kill()

	next_player.stop()
	next_player.stream = stream
	next_player.volume_db = MUSIC_SILENT_DB
	_music_player_keys[next_index] = key
	next_player.play()
	_active_music_index = next_index

	_music_fade_tween = create_tween()
	_music_fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_music_fade_tween.set_parallel(true)
	_music_fade_tween.tween_property(next_player, "volume_db", 0.0, fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if previous_player != null and previous_player.playing:
		_music_fade_tween.tween_property(previous_player, "volume_db", MUSIC_SILENT_DB, fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		_music_fade_tween.finished.connect(func() -> void:
			var active_player := _music_players[_active_music_index] if _active_music_index >= 0 else null
			if previous_player != null and previous_player != active_player:
				previous_player.stop()
		)


func _fade_out_current_music(fade_duration: float) -> void:
	if _active_music_index < 0 or _music_players.is_empty():
		return

	var player := _music_players[_active_music_index]
	_active_music_index = -1
	if _music_fade_tween != null:
		_music_fade_tween.kill()

	_music_fade_tween = create_tween()
	_music_fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_music_fade_tween.tween_property(player, "volume_db", MUSIC_SILENT_DB, fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_music_fade_tween.finished.connect(func() -> void: player.stop())


func _stop_music_players() -> void:
	if _music_fade_tween != null:
		_music_fade_tween.kill()

	_active_music_index = -1
	for i in range(_music_players.size()):
		_music_player_keys[i] = ""
		_music_players[i].stop()
		_music_players[i].volume_db = MUSIC_SILENT_DB


func _on_music_finished(player: AudioStreamPlayer) -> void:
	var player_index := _music_players.find(player)
	if player_index != _active_music_index or _requested_music_key.is_empty():
		return

	var stream := _get_music_stream(_requested_music_key)
	if stream == null:
		return

	player.stream = stream
	player.volume_db = 0.0
	player.play()


func _get_music_stream(key: String) -> AudioStream:
	if _music_cache.has(key):
		return _music_cache[key] as AudioStream
	if not MUSIC_PATHS.has(key):
		return null

	var stream := _load_first_existing_stream(MUSIC_PATHS[key])
	_music_cache[key] = stream
	return stream


func _get_sfx_stream(key: String) -> AudioStream:
	if _sfx_cache.has(key):
		return _sfx_cache[key] as AudioStream
	if not SFX_PATHS.has(key):
		return null

	var stream := _load_first_existing_stream(SFX_PATHS[key])
	_sfx_cache[key] = stream
	return stream


func _load_first_existing_stream(paths: Array) -> AudioStream:
	for path_value in paths:
		var path := String(path_value)
		if not ResourceLoader.exists(path):
			continue

		var stream := load(path) as AudioStream
		if stream != null:
			return stream

	return null


func _get_available_sfx_player() -> AudioStreamPlayer:
	for player in _sfx_players:
		if not player.playing:
			return player

	return _sfx_players[0]


func _is_sound_position_audible(sound_position) -> bool:
	if not _has_audible_world_rect or not (sound_position is Vector2):
		return true

	return _audible_world_rect.has_point(sound_position)


func _ensure_audio_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return

	var index := AudioServer.get_bus_count()
	AudioServer.add_bus(index)
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, "Master")


func _apply_bus_volumes() -> void:
	_apply_bus_volume(MUSIC_BUS, music_volume)
	_apply_bus_volume(SFX_BUS, effects_volume)


func _apply_bus_volume(bus_name: String, value: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return

	AudioServer.set_bus_mute(index, value <= 0.001)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(value, 0.001)))


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return

	music_volume = clampf(float(config.get_value("audio", "music_volume", DEFAULT_MUSIC_VOLUME)), 0.0, 1.0)
	effects_volume = clampf(float(config.get_value("audio", "effects_volume", DEFAULT_EFFECTS_VOLUME)), 0.0, 1.0)


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "effects_volume", effects_volume)
	config.save(SETTINGS_PATH)
