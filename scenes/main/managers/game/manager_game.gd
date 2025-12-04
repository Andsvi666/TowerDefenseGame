class_name ManagerGame
extends Node

var endless_mode: bool = false

signal wave_complete_support
var wave_active: bool = false

var built_towers := {
	"turret_tier_1": 0,
	"turret_tier_2": 0,
	"cannon_tier_1": 0,
	"cannon_tier_2": 0,
	"missile_tier_1": 0,
	"missile_tier_2": 0,
	"support_tier_1": 0,
	"support_tier_2": 0,
}

var available_tiles_for_towers := {
	"turret_tiles": 43,
	"cannon_tiles": 27,
	"missile_tiles": 12,
	"support_tiles": 9,
}

# Tower resource paths
var tower_files := {
	"turret_tier_1": "res://scenes/main/tower/turret/tiers/turret_tier_1.tres",
	"turret_tier_2": "res://scenes/main/tower/turret/tiers/turret_tier_2.tres",
	"cannon_tier_1": "res://scenes/main/tower/cannon/tiers/cannon_tier_1.tres",
	"cannon_tier_2": "res://scenes/main/tower/cannon/tiers/cannon_tier_2.tres",
	"missile_tier_1": "res://scenes/main/tower/missile/tiers/missile_tier_1.tres",
	"missile_tier_2": "res://scenes/main/tower/missile/tiers/missile_tier_2.tres",
	"support_tier_1": "res://scenes/main/tower/support/tiers/support_tier_1.tres",
	"support_tier_2": "res://scenes/main/tower/support/tiers/support_tier_2.tres"
}

# Enemy resource paths
var enemy_files := {
	# Troops
	"troop_tier_1": "res://scenes/main/enemy/troop/tiers/troop_tier_1.tres",
	"troop_tier_2": "res://scenes/main/enemy/troop/tiers/troop_tier_2.tres",
	"troop_tier_3": "res://scenes/main/enemy/troop/tiers/troop_tier_3.tres",

	# Tanks
	"tank_tier_1": "res://scenes/main/enemy/tank/tiers/tank_tier_1.tres",
	"tank_tier_2": "res://scenes/main/enemy/tank/tiers/tank_tier_2.tres",
	"tank_tier_3": "res://scenes/main/enemy/tank/tiers/tank_tier_3.tres",

	# Planes
	"plane_tier_1": "res://scenes/main/enemy/plane/tiers/plane_tier_1.tres",
	"plane_tier_2": "res://scenes/main/enemy/plane/tiers/plane_tier_2.tres",
	"plane_tier_3": "res://scenes/main/enemy/plane/tiers/plane_tier_3.tres"
}

func setup_fresh_game() -> void:
	HealthMan.setup_health()
	CoinsMan.setup_coins()
	WavesMan.setup_waves()
	wave_active = false

func stop_support_towers() -> void:
	emit_signal("wave_complete_support")

func show_floating_message(text: String) -> void:
	var msg = Label.new()
	msg.text = text
	msg.add_theme_color_override("font_color", Color.RED)
	msg.add_theme_color_override("font_outline_color", Color.BLACK)
	msg.add_theme_constant_override("outline_size", 5)
	msg.add_theme_font_size_override("font_size", 28)
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Add label under your UI root instead of the autoload
	var ui_root = get_node_or_null("/root/Main/UIRoot")
	if ui_root:
		ui_root.add_child(msg)
	else:
		print_debug("Could not find UIRoot, adding to self")
		add_child(msg)
	
	# Center the message on the screen
	var screen_size = get_viewport().get_visible_rect().size
	msg.global_position = screen_size / 2.0 + Vector2(-400, -100)
	
	# Animate upward + fade out
	var tween = get_tree().create_tween()
	tween.tween_property(msg, "position:y", msg.position.y - 150, 2)
	tween.parallel().tween_property(msg, "modulate:a", 0.0, 1).set_delay(1)
	tween.tween_callback(Callable(msg, "queue_free"))

func collect_ai_prompt() -> String:
	var coins = CoinsMan.coins
	var health = HealthMan.current_health
	var next_wave = WavesMan.return_next_wave_info()  # should be aggregated already
	
	# Built towers info compact
	var built_towers_info := ""
	for t_name in built_towers.keys():
		built_towers_info += "%s: %d, " % [t_name, built_towers[t_name]]
	if built_towers_info.length() > 2:
		built_towers_info = built_towers_info.substr(0, built_towers_info.length() - 2)
	
	# Available tiles info
	var available_tiles_info := ""
	for t_type in available_tiles_for_towers.keys():
		available_tiles_info += "%s: %d, " % [t_type, available_tiles_for_towers[t_type]]
	if available_tiles_info.length() > 2:
		available_tiles_info = available_tiles_info.substr(0, available_tiles_info.length() - 2)
	
	# Tower stats summary
	var tower_stats = get_tower_stats_summary()
	var tower_stats_info := ""
	for key in tower_stats.keys():
		var s = tower_stats[key]
		tower_stats_info += "%s: dmg %.1f, fire %.1f, range %.1f, cost %d coins, target %s; " % [
			key.capitalize(), s.damage, s.firerate, s.range, s.cost, s.target_group
		]
	
	# Enemy stats summary
	var enemy_stats = get_enemy_stats_summary()
	var enemy_stats_info := ""
	for key in enemy_stats.keys():
		var e = enemy_stats[key]
		enemy_stats_info += "%s: type %s, speed %.1f, damage %.1f, reward %d coins, hp %.1f; " % [
			key.capitalize(), e.type, e.speed, e.damage, e.reward, e.health
		]
	
	var ai_prompt := ""
	ai_prompt += "=== INSTRUCTIONS ===\n"
	ai_prompt += "Think step-by-step internally, but DO NOT reveal your reasoning. "
	ai_prompt += "Output ONLY the final answer in one short sentence (max 300 characters). "
	ai_prompt += "Do not use underscores in tower names; use spaces.\n\n"

	ai_prompt += "=== CONDITIONAL LOGIC ===\n"
	ai_prompt += "- If coins >= 2000, include at least one support tower.\n"
	ai_prompt += "- You may suggest multiple tower types in one sentence.\n"
	ai_prompt += "- If the player already has enough towers for the next wave, respond exactly with: 'Save coins for upcoming waves.'\n\n"

	ai_prompt += "=== EXAMPLE FORMAT ===\n"
	ai_prompt += "Example: Build 3 cannon (tier 1) towers for 900 coins and upgrade them to tier 2 for 3000 coins, also build 2 missile (tier 1) towers for 3000 coins and upgrade them to tier 2 for 6000 coins.\n\n"

	ai_prompt += "=== RULES FOR RESPONSE ===\n"
	ai_prompt += "1. Towers only attack their target enemy type; support towers heal base = attack damage and generate coins = 10× attack damage.\n"
	ai_prompt += "2. Killing enemies grants coins equal to their reward.\n"
	ai_prompt += "3. Enemies spawn every 0.5–2 seconds.\n"
	ai_prompt += "4. Turrets persist across waves; plan long-term.\n"
	ai_prompt += "5. Prioritize: survival → damage → coin generation.\n"
	ai_prompt += "6. Do not suggest building towers on types with 0 available tiles.\n"
	ai_prompt += "7. Tier 1 towers must be built on empty tiles; higher tiers only through upgrading.\n\n"


	ai_prompt += "Game status:\n"
	ai_prompt += "Current coins: %d\nCurrent health: %d\nAlready built towers: %s\nAvailable tiles: %s\nNext wave: %s\n" % [coins, health, built_towers_info, available_tiles_info, next_wave]
	ai_prompt += "Each tower stats: %s\n" % tower_stats_info
	ai_prompt += "Each enemy stats: %s\n" % enemy_stats_info

	
	return ai_prompt


func get_tower_stats_summary() -> Dictionary:
	var stats_summary := {}
	for key in tower_files.keys():
		var res: Resource = load(tower_files[key])
		if res:
			stats_summary[key] = {
				"name": res.tower_name,
				"damage": res.attack_damage,
				"firerate": res.attack_cooldown,
				"cost": res.build_cost,
				"range": res.attack_range, 
				"target_group": res.target_group
			}
	return stats_summary

func get_enemy_stats_summary() -> Dictionary:
	var stats_summary := {}
	for key in enemy_files.keys():
		var res: Resource = load(enemy_files[key])
		if res:
			stats_summary[key] = {
				"type": res.group,         # enemy group: "troop", "tank", "plane"
				"health": res.max_health,       # enemy HP
				"speed": res.movement_speed,    # movement speed
				"damage": res.damage_cost,      # damage to base
				"reward": res.coin_reward,      # coins given when killed
			}
	return stats_summary
