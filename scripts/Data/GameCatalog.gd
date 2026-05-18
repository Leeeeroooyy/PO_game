class_name GameCatalog
extends RefCounted

const TEAM_NEUTRAL := "neutral"
const TEAM_PLAYER := "player"
const TEAM_ENEMY := "enemy"

const LANE_TOP := "top"
const LANE_MIDDLE := "middle"
const LANE_BOTTOM := "bottom"

const DEFAULT_HERO_ID := "forest_ranger"
const LANE_UNIT_MOVE_SPEED := 85.0
const MAX_ABILITY_LEVEL := 4
const ABILITY_REFERENCE_LEVEL := 3
const HERO_HEALTH_BONUS_PER_LEVEL := 0.14
const HERO_DAMAGE_BONUS_PER_LEVEL := 0.10
const HERO_ATTACK_SPEED_BONUS_PER_LEVEL := 0.045
const HERO_HEALTH_REGEN_BONUS_PER_LEVEL := 0.45
const SHOP_UPGRADE_STAT := "stat"
const SHOP_UPGRADE_WAVE_COUNT := "wave_count"


static func stats(max_health: float, move_speed: float, attack_damage: float, attack_range: float, attack_cooldown: float, gold_reward: int = 0, experience_reward: int = 0, health_regen: float = 0.0) -> Dictionary:
	return {
		"max_health": max_health,
		"move_speed": move_speed,
		"attack_damage": attack_damage,
		"attack_range": attack_range,
		"attack_cooldown": attack_cooldown,
		"gold_reward": gold_reward,
		"experience_reward": experience_reward,
		"health_regen": health_regen,
	}


static func ability(id: String, display_name: String, description: String, targeting: String, cooldown: float, cast_range: float, radius: float, power: float) -> Dictionary:
	return {
		"id": id,
		"display_name": display_name,
		"description": description,
		"targeting": targeting,
		"cooldown": cooldown,
		"range": cast_range,
		"radius": radius,
		"power": power,
	}


static func ability_scaled(id: String, display_name: String, description: String, targeting: String, cooldown: float, cast_range: float, radius: float, power: float, scaled_stats: Array, extra_stats: Dictionary) -> Dictionary:
	var result := ability(id, display_name, description, targeting, cooldown, cast_range, radius, power)
	result["scaled_stats"] = scaled_stats.duplicate()
	for key in extra_stats.keys():
		result[key] = extra_stats[key]

	return result


static func ability_for_level(ability_definition: Dictionary, level: int) -> Dictionary:
	if ability_definition.is_empty():
		return {}

	var scaled := ability_definition.duplicate(true)
	for stat_key_value in ability_scaled_stat_keys(ability_definition):
		var stat_key := String(stat_key_value)
		if scaled.has(stat_key):
			scaled[stat_key] = ability_stat_at_level(ability_definition, stat_key, level)

	return scaled


static func ability_scaled_stat_keys(ability_definition: Dictionary) -> Array:
	return ability_definition.get("scaled_stats", []).duplicate()


static func ability_stat_values(ability_definition: Dictionary, stat_key: String) -> Array:
	var values: Array[float] = []
	for level in range(1, MAX_ABILITY_LEVEL + 1):
		values.append(ability_stat_at_level(ability_definition, stat_key, level))

	return values


static func ability_stat_at_level(ability_definition: Dictionary, stat_key: String, level: int) -> float:
	var base_value := float(ability_definition.get(stat_key, 0.0))
	if not ability_scaled_stat_keys(ability_definition).has(stat_key):
		return base_value

	return _scale_ability_stat_value(stat_key, base_value, level)


static func _scale_ability_stat_value(stat_key: String, base_value: float, level: int) -> float:
	var clamped_level := clampi(level, 1, MAX_ABILITY_LEVEL)
	var factor := _ability_stat_level_factor(stat_key, clamped_level)

	match stat_key:
		"speed_multiplier", "attack_damage_multiplier":
			return 1.0 + (base_value - 1.0) * factor
		"slow_multiplier", "damage_reduction_multiplier":
			return 1.0 - (1.0 - base_value) * factor
		_:
			return base_value * factor


static func _ability_stat_level_factor(stat_key: String, level: int) -> float:
	match stat_key:
		"cooldown":
			match level:
				1:
					return 1.32
				2:
					return 1.15
				4:
					return 0.86
				_:
					return 1.0
		"range", "radius":
			match level:
				1:
					return 0.72
				2:
					return 0.86
				4:
					return 1.12
				_:
					return 1.0
		"duration", "taunt_duration", "freeze_duration", "pull_distance", "speed_multiplier", "attack_damage_multiplier", "slow_multiplier", "damage_reduction_multiplier":
			match level:
				1:
					return 0.68
				2:
					return 0.84
				4:
					return 1.16
				_:
					return 1.0
		_:
			match level:
				1:
					return 0.62
				2:
					return 0.80
				4:
					return 1.18
				_:
					return 1.0


static func create_hero_definitions() -> Dictionary:
	return {
		"forest_ranger": {
			"id": "forest_ranger",
			"display_name": "Forest Ranger",
			"description": "Mobile ranged hero focused on arrows, marks and fast repositioning.",
			"stats": stats(170.0, 235.0, 16.0, 150.0, 0.75, 35, 30, 1.15),
			"abilities": [
				ability_scaled("piercing_arrow", "Piercing Arrow", "Shoots through enemies toward the cursor.", "direction", 4.0, 300.0, 24.0, 32.0, ["power", "cooldown", "range", "radius"], {}),
				ability_scaled("mark_prey", "Mark Prey", "Marks a target for focused burst damage.", "single_target", 7.0, 240.0, 50.0, 44.0, ["power", "cooldown", "range"], {}),
				ability_scaled("nature_dash", "Nature Dash", "Briefly accelerates the hero.", "self", 5.0, 0.0, 0.0, 0.0, ["cooldown", "duration", "speed_multiplier"], {"duration": 2.4, "speed_multiplier": 1.85}),
				ability_scaled("hail_of_arrows", "Hail of Arrows", "Rapid arrows on a selected enemy area.", "area", 10.0, 260.0, 80.0, 70.0, ["power", "cooldown", "range", "radius"], {}),
			],
		},
		"bard_frog": {
			"id": "bard_frog",
			"display_name": "Bard Frog",
			"description": "Support hero with healing, ritual zones and disruptive control.",
			"stats": stats(195.0, 215.0, 12.0, 110.0, 0.95, 35, 30, 1.55),
			"abilities": [
				ability_scaled("healing_melody", "Healing Melody", "Heals nearby allies.", "self", 8.0, 0.0, 85.0, 35.0, ["power", "cooldown", "radius"], {}),
				ability_scaled("swamp_ritual", "Swamp Ritual", "Creates a temporary area that weakens enemies.", "area", 11.0, 220.0, 95.0, 28.0, ["power", "cooldown", "range", "radius"], {"duration": 4.0}),
				ability_scaled("frog_jump", "Frog Jump", "Jumps to a point and damages nearby enemies.", "point", 6.0, 180.0, 70.0, 36.0, ["power", "cooldown", "range", "radius"], {}),
				ability_scaled("sticky_tongue", "Sticky Tongue", "Pull-themed single target strike.", "single_target", 7.0, 210.0, 42.0, 38.0, ["power", "cooldown", "range", "pull_distance"], {"pull_distance": 95.0}),
			],
		},
		"axe_barbarian": {
			"id": "axe_barbarian",
			"display_name": "Axe Barbarian",
			"description": "Durable melee hero who wins by staying in the center of combat.",
			"stats": stats(275.0, 205.0, 24.0, 48.0, 0.9, 40, 35, 2.0),
			"abilities": [
				ability_scaled("whirlwind", "Whirlwind", "Damages enemies around the hero.", "self", 6.0, 0.0, 78.0, 34.0, ["power", "cooldown", "radius"], {}),
				ability_scaled("blood_rage", "Blood Rage", "Self sustain burst.", "self", 9.0, 0.0, 0.0, 38.0, ["power", "cooldown", "duration", "speed_multiplier", "attack_damage_multiplier"], {"duration": 4.0, "speed_multiplier": 1.45, "attack_damage_multiplier": 1.35}),
				ability_scaled("battle_cry", "Battle Cry", "Protects nearby allies.", "self", 10.0, 0.0, 90.0, 0.0, ["cooldown", "radius", "duration", "damage_reduction_multiplier"], {"duration": 5.0, "damage_reduction_multiplier": 0.62}),
				ability_scaled("berserkers_call", "Berserker's Call", "Forces nearby enemies to focus the hero.", "self", 12.0, 0.0, 105.0, 26.0, ["power", "cooldown", "radius", "taunt_duration"], {"taunt_duration": 3.5}),
			],
		},
		"sorcerer": {
			"id": "sorcerer",
			"display_name": "Sorcerer",
			"description": "Fragile caster with strong area damage and control spheres.",
			"stats": stats(145.0, 220.0, 18.0, 170.0, 1.05, 35, 32, 0.95),
			"abilities": [
				ability_scaled("fire_sphere", "Fire Sphere", "Meteor-like damage in target area.", "area", 8.0, 270.0, 86.0, 58.0, ["power", "cooldown", "range", "radius"], {}),
				ability_scaled("ice_sphere", "Ice Sphere", "Freezes enemies in front of the hero.", "direction", 9.0, 220.0, 60.0, 24.0, ["power", "cooldown", "range", "radius", "freeze_duration"], {"freeze_duration": 1.8}),
				ability_scaled("water_sphere", "Water Sphere", "Self heal.", "self", 10.0, 0.0, 0.0, 45.0, ["power", "cooldown"], {}),
				ability_scaled("void_sphere", "Void Sphere", "Pulls enemies into target area.", "area", 13.0, 260.0, 100.0, 36.0, ["power", "cooldown", "range", "radius", "pull_distance"], {"pull_distance": 120.0}),
			],
		},
		"ancient_druid": {
			"id": "ancient_druid",
			"display_name": "Ancient Druid",
			"description": "Summoner-controller inspired by wolves, thorns, treants and snakes.",
			"stats": stats(200.0, 210.0, 15.0, 135.0, 0.9, 35, 32, 1.45),
			"abilities": [
				ability_scaled("alpha_wolf", "Alpha Wolf", "Summons a wolf that attacks nearby enemies.", "self", 11.0, 0.0, 85.0, 30.0, ["power", "cooldown", "radius"], {}),
				ability_scaled("thorns", "Thorns", "Damages and slows enemies in a target area.", "area", 8.0, 230.0, 88.0, 32.0, ["power", "cooldown", "range", "radius"], {}),
				ability_scaled("summon_treant", "Summon Treant", "Summons a treant that pushes toward the enemy base.", "point", 13.0, 220.0, 70.0, 40.0, ["power", "cooldown", "range"], {}),
				ability_scaled("snake_charmer", "Snake Charmer", "Snake-themed chase strike on one target.", "single_target", 9.0, 240.0, 48.0, 42.0, ["power", "cooldown", "range"], {}),
			],
		},
	}


static func create_scaled_hero_stats(definition: Dictionary, level: int) -> Dictionary:
	var hero_stats: Dictionary = definition.get("stats", {}).duplicate(true)
	var level_value := float(maxi(1, level) - 1)
	hero_stats["max_health"] = float(hero_stats.get("max_health", 1.0)) * (1.0 + level_value * HERO_HEALTH_BONUS_PER_LEVEL)
	hero_stats["attack_damage"] = float(hero_stats.get("attack_damage", 1.0)) * (1.0 + level_value * HERO_DAMAGE_BONUS_PER_LEVEL)
	hero_stats["attack_cooldown"] = float(hero_stats.get("attack_cooldown", 1.0)) * maxf(0.55, 1.0 - level_value * HERO_ATTACK_SPEED_BONUS_PER_LEVEL)
	hero_stats["health_regen"] = float(hero_stats.get("health_regen", 0.0)) + level_value * HERO_HEALTH_REGEN_BONUS_PER_LEVEL
	return hero_stats


static func create_unit_definitions() -> Dictionary:
	return {
		"line_melee": {
			"id": "line_melee",
			"display_name": "Melee Creep",
			"is_lane_unit": true,
			"is_siege_unit": false,
			"cost": 25,
			"upgrade_cost": 60,
			"stats": stats(90.0, LANE_UNIT_MOVE_SPEED, 10.0, 32.0, 1.15, 8, 6),
		},
		"line_mage": {
			"id": "line_mage",
			"display_name": "Ranged Creep",
			"is_lane_unit": true,
			"is_siege_unit": false,
			"cost": 40,
			"upgrade_cost": 85,
			"stats": stats(62.0, LANE_UNIT_MOVE_SPEED, 14.0, 120.0, 1.35, 10, 7),
		},
		"line_siege": {
			"id": "line_siege",
			"display_name": "Siege Cart",
			"is_lane_unit": true,
			"is_siege_unit": true,
			"cost": 90,
			"upgrade_cost": 140,
			"stats": stats(180.0, 45.0, 38.0, 190.0, 2.25, 22, 16),
		},
		"neutral_bruiser": neutral("neutral_bruiser", "Forest Bruiser", 130.0, 12.0, 36.0, 12, 10),
		"neutral_spitter": neutral("neutral_spitter", "Venom Spitter", 80.0, 11.0, 125.0, 13, 11),
		"neutral_thrower": neutral("neutral_thrower", "Stone Thrower", 72.0, 13.0, 145.0, 15, 12),
		"neutral_claw": neutral("neutral_claw", "Claw Beast", 155.0, 18.0, 42.0, 18, 14),
	}


static func create_enemy_hero_stats() -> Dictionary:
	return stats(230.0, 180.0, 18.0, 85.0, 1.0, 65, 55)


static func create_shop_upgrade_definitions() -> Dictionary:
	var units := create_unit_definitions()
	var upgrades := {}
	for unit_id in ["line_melee", "line_mage", "line_siege"]:
		var unit: Dictionary = units[unit_id]
		var stat_upgrade := unit.duplicate(true)
		stat_upgrade["shop_upgrade_type"] = SHOP_UPGRADE_STAT
		stat_upgrade["unit_id"] = unit_id
		stat_upgrade["max_level"] = 8
		if unit_id == "line_siege":
			stat_upgrade["required_upgrade_id"] = "unlock_line_siege"
			stat_upgrade["required_upgrade_level"] = 1
		upgrades[unit_id] = stat_upgrade

	upgrades["count_line_melee"] = {
		"id": "count_line_melee",
		"display_name": "Melee Creep Count",
		"description": "Adds one allied melee creep to each lane wave.",
		"shop_upgrade_type": SHOP_UPGRADE_WAVE_COUNT,
		"unit_id": "line_melee",
		"upgrade_cost": 360,
		"max_level": 2,
		"base_count": 2,
		"count_per_level": 1,
		"max_count": 4,
	}
	upgrades["count_line_mage"] = {
		"id": "count_line_mage",
		"display_name": "Ranged Creep Count",
		"description": "Adds one allied ranged creep to each lane wave.",
		"shop_upgrade_type": SHOP_UPGRADE_WAVE_COUNT,
		"unit_id": "line_mage",
		"upgrade_cost": 420,
		"max_level": 1,
		"base_count": 1,
		"count_per_level": 1,
		"max_count": 2,
	}
	upgrades["unlock_line_siege"] = {
		"id": "unlock_line_siege",
		"display_name": "Siege Cart Waves",
		"description": "Adds one allied siege cart to each lane wave.",
		"shop_upgrade_type": SHOP_UPGRADE_WAVE_COUNT,
		"unit_id": "line_siege",
		"upgrade_cost": 720,
		"max_level": 1,
		"base_count": 0,
		"count_per_level": 1,
		"max_count": 1,
	}
	return upgrades


static func unit_display_name(unit_id: String) -> String:
	var definitions := create_unit_definitions()
	if definitions.has(unit_id):
		return String(definitions[unit_id].get("display_name", unit_id))

	return _format_id_name(unit_id)


static func create_tower_stats(tier: int = 1) -> Dictionary:
	var clamped_tier := clampi(tier, 1, 3)
	var health := 520.0 + float(clamped_tier - 1) * 260.0
	var damage := 28.0 + float(clamped_tier - 1) * 18.0
	var attack_range := 155.0 + float(clamped_tier - 1) * 10.0
	var gold := 65 + (clamped_tier - 1) * 35
	var experience := 45 + (clamped_tier - 1) * 25
	return stats(health, 0.0, damage, attack_range, 0.82, gold, experience)


static func neutral(id: String, display_name: String, health: float, damage: float, attack_range: float, gold: int, experience: int) -> Dictionary:
	return {
		"id": id,
		"display_name": display_name,
		"is_lane_unit": false,
		"is_siege_unit": false,
		"cost": 0,
		"upgrade_cost": 0,
		"stats": stats(health, 70.0, damage, attack_range, 1.2, gold, experience),
	}


static func _format_id_name(id: String) -> String:
	var words := id.split("_")
	var parts := []
	for word in words:
		if not word.is_empty():
			parts.append(word.capitalize())

	return " ".join(parts) if not parts.is_empty() else id
