class_name ManagerAI
extends Node

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

# === CONFIG ===
var API_KEY := ""
const MODEL := "openai/gpt-5.2-chat"
const URL := "https://openrouter.ai/api/v1/chat/completions"

# === INTERNAL ===
var _http := HTTPRequest.new()

func setup():
	API_KEY = await FirebaseMan.read_api_key("api key")
	add_child(_http)

# === PUBLIC FUNCTION ===
# Async function you can await in your UI
func ask_AI_advice() -> String:
	var prompt = await collect_ai_prompt()
	#print_debug(prompt)
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer %s" % API_KEY
	]

	var body = {
		"model": MODEL,
		"messages": [
			{"role": "user", "content": prompt}
		],
		"max_tokens": 1024,
		"temperature": 0.6
	}

	var json_body = JSON.stringify(body)

	# --- Send request ---
	var err = _http.request(URL, headers, HTTPClient.METHOD_POST, json_body)
	if err != OK:
		return "Error sending request"

	# --- Wait for response ---
	var result = await _http.request_completed

	# result is a tuple: (result, response_code, headers, body_bytes)
	var response_code = result[1]
	var body_bytes = result[3]
	var body_text = body_bytes.get_string_from_utf8()
	#print_debug(body_text)

	if response_code != 200:
		return "AI connection error"
		

	# --- Parse JSON ---
	var json = JSON.new()
	var error = json.parse(body_text)
	if error != OK:
		return "Failed to parse AI response"

	var data = json.get_data()  # This is your parsed dictionary

	# --- Extract AI content robustly ---
	var advice := "Failed to receive advice from AI"

	if data.has("choices") and data["choices"].size() > 0:
		var choice = data["choices"][0]

		if choice.has("message") and choice["message"].has("content"):
			advice = str(choice["message"]["content"])
		elif choice.has("content"):
			advice = str(choice["content"])
		else:
			return "Malformed AI response"
	else:
		return "No AI response found"

	advice = advice.strip_edges()  # remove extra whitespace
	
	# --- Ensure something is returned even if AI gave nothing ---
	if advice == "":
		advice = "AI did not return advice, try again."
	
	return advice

func collect_ai_prompt() -> String:
	var next_wave = await WavesMan.read_next_wave()

	var ai_prompt := ""

	# --- CORE DIRECTIVE ---
	ai_prompt += "You may reason internally using all provided data, but ONLY output the final advice.\n"
	ai_prompt += "Do NOT restate game state, stats, or rules.\n\n"

	# --- OUTPUT FORMAT ---
	ai_prompt += "=== OUTPUT FORMAT (MANDATORY) ===\n"
	ai_prompt += "- Exactly ONE paragraph\n"
	ai_prompt += "- Maximum 500 characters\n"
	ai_prompt += "- No line breaks\n"
	ai_prompt += "- No bullet points\n"
	ai_prompt += "- Start with: You have X coins.\n"
	ai_prompt += "- Do not exceed available coins.\n"
	ai_prompt += "- While mentioning tower use names naturally and not based on code (turret_tier_1 to turret, cannon_tier_2 to upgraded cannon)\n"

	# --- CONDITIONAL LOGIC ---
	ai_prompt += "=== CONDITIONAL LOGIC ===\n"
	ai_prompt += "- If towers are sufficient, respond EXACTLY with: Save coins for upcoming waves.\n"
	ai_prompt += "- Include at least one Support tower if coins >= 2000.\n"
	ai_prompt += "- Do not suggest towers with 0 available tiles.\n"
	ai_prompt += "- Upgraded towers are more efficient but more expensive, it is worth investment.\n"
	ai_prompt += "- Upgraded towers can only be built on tier 1 towers, so to get tier 2 tower price is tier 1 and tier 2 combined.\n"
	ai_prompt += "- Total suggested cost must not exceed current coins.\n\n"

	# --- CORE RULES (COMPRESSED) ---
	ai_prompt += "=== CORE RULES ===\n"
	ai_prompt += "- Towers attack only their target enemy type.\n"
	ai_prompt += "- Tier 1 towers require empty tiles; higher tiers require upgrading.\n"
	ai_prompt += "- Turrets persist across waves; plan long-term.\n"
	ai_prompt += "- Priority: survival > damage > coin generation.\n\n"

	# --- GAME CONTEXT ---
	ai_prompt += "Next wave enemies (Type, Tier):\n%s\n" % next_wave
	ai_prompt += current_game_state()
	
	#print_debug(ai_prompt)
	return ai_prompt


func current_game_state() -> String: 
	var coins = CoinsMan.coins 
	var health = HealthMan.current_health # Built towers info compact 
	var built_towers_info := "" 
	for t_name in BuildingMan.built_towers.keys(): 
		built_towers_info += "%s: %d, " % [t_name, BuildingMan.built_towers[t_name]] 
		if built_towers_info.length() > 2: 
			built_towers_info = built_towers_info.substr(0, built_towers_info.length() - 2) # Available tiles info 
	var available_tiles_info := "" 
	for t_type in BuildingMan.available_tiles_for_towers.keys(): 
		available_tiles_info += "%s: %d, " % [t_type, BuildingMan.available_tiles_for_towers[t_type]] 
		if available_tiles_info.length() > 2:
			available_tiles_info = available_tiles_info.substr(0, available_tiles_info.length() - 2) # Tower stats summary 
	var tower_stats = get_tower_stats_summary() 
	var tower_stats_info := "" 
	for key in tower_stats.keys(): 
		var s = tower_stats[key] 
		tower_stats_info += "%s: dmg %.1f, fire %.1f, range %.1f, cost %d coins, target %s; " % [ key.capitalize(), s.damage, s.firerate, s.range, s.cost, s.target_group ] # Enemy stats summary 
	var enemy_stats = get_enemy_stats_summary() 
	var enemy_stats_info := "" 
	for key in enemy_stats.keys(): 
		var e = enemy_stats[key] 
		enemy_stats_info += "%s: type %s, speed %.1f, damage %.1f, reward %d coins, hp %.1f; " % [ key.capitalize(), e.type, e.speed, e.damage, e.reward, e.health ] 
	var game_state = "" 
	game_state += "Game status:\n" 
	game_state += "Current coins: %d\n" % coins 
	game_state += "Current health: %d\n" % health 
	game_state += "Already built towers(tower name with tier and count):%s\n" % built_towers_info 
	game_state += "Available tiles: %s\n" % available_tiles_info 
	game_state += "Each tower stats: %s\n" % tower_stats_info 
	game_state += "Each enemy stats: %s\n" % enemy_stats_info 
	#print_debug(game_state) 
	return game_state 

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
