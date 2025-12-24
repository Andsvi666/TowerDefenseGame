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
const MODEL := "xiaomi/mimo-v2-flash:free"
const URL := "https://openrouter.ai/api/v1/chat/completions"

# === INTERNAL ===
var _http := HTTPRequest.new()

func setup():
	API_KEY = await FirebaseMan.read_api_key("api key")
	add_child(_http)

func send_request(prompt: String) -> String:
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer %s" % API_KEY
	]

	var body = {
		"model": MODEL,
		"messages": [
		{ "role": "user", "content": prompt }
		],
		"max_tokens": 1024,
		"temperature": 0.6
	}

	var err = _http.request(URL, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		print_debug(err)
		return ""

	var result = await _http.request_completed
	#print_debug(result)
	if result[1] != 200:
		#print_debug(result)
		return ""

	var json := JSON.new()
	if json.parse(result[3].get_string_from_utf8()) != OK:
		return ""

	var data = json.get_data()
	if not data.has("choices") or data["choices"].is_empty():
		return ""

	var choice = data["choices"][0]
	if choice.has("message") and choice["message"].has("content"):
		return str(choice["message"]["content"]).strip_edges()

	return ""


# ==================================================================
# ---------------------------- ADVICE ------------------------------
# ==================================================================

# === PUBLIC FUNCTION ===
# Async function you can await in your UI
func ask_AI_advice() -> String:
	var prompt = await collect_advice_prompt()
	var response = await send_request(prompt)

	if response == "":
		return "AI did not return advice."

	return response

func collect_advice_prompt() -> String:
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
	
	var enemy_stats = get_enemy_stats_summary() 
	var enemy_stats_info := "" 
	for key in enemy_stats.keys(): 
		var e = enemy_stats[key] 
		enemy_stats_info += "%s: type %s, speed %.1f, damage %.1f, reward %d coins, hp %.1f; " % [ key.capitalize(), e.type, e.speed, e.damage, e.reward, e.health ] 
	ai_prompt += "Each enemy stats: %s\n" % enemy_stats_info 
	
	#print_debug(ai_prompt)
	return ai_prompt

# ==================================================================
# ---------------------------- WAVES ------------------------------
# ==================================================================

func generate_wave(budget: int, max_tier: int, allowed_types: Array) -> Array:
	var generated_wave = []
	var prompt = await collect_waves_prompt(budget, max_tier, allowed_types)
	#print_debug(prompt)
	var response = await send_request(prompt)
	print_debug("BUDGET:")
	print_debug(budget)
	print_debug("GENERATED RESPONSE:")
	print_debug(response)
	var data = rework_response(response)
	var message = "Wave has been generated"
	GameMan.log_event(message)
	print_debug("REWORKED RESPONSE:")
	print_debug(data)
	
	return data

func rework_response(response: String) -> Array:
	var wave = []
	if response == "":
		return wave
	# Parse JSON safely
	var json := JSON.new()
	var err = json.parse(response)
	if err != OK:
		print_debug("Failed to parse AI response JSON")
		return wave

	var raw_wave = json.get_data()
	if typeof(raw_wave) != TYPE_ARRAY:
		print_debug("AI response is not an array")
		return wave

	# Convert to expected wave format
	for e in raw_wave:
		if typeof(e) != TYPE_DICTIONARY:
			continue
		if not e.has("type") or not e.has("tier"):
			continue

		var tier_index = int(e["tier"]) - 1
		if tier_index < 0:
			tier_index = 0

		wave.append({
			"type": e["type"],
			"tier_index": tier_index,
			"spawn_delay": 2.0
		})

	return wave


func collect_waves_prompt(budget: int, max_tier: int, allowed_types: Array) -> String:
	var prompt := ""

	# --- CORE DIRECTIVE ---
	prompt += "You are an enemy commander in a tower defense game. "
	prompt += "Your goal is to defeat the player by designing a single enemy wave. "
	prompt += "You may reason internally using the full game state, but your output must ONLY be the wave.\n\n"

	# --- HARD CONSTRAINTS ---
	prompt += "=== HARD CONSTRAINTS ===\n"
	prompt += "- Total budget: %d (each enemy costs its damage value)\n" % budget
	prompt += "- Maximum enemy tier allowed: %d\n" % max_tier
	prompt += "- You may only use these enemies (type and tier):\n"

	var enemies = get_enemy_stats_summary()
	for key in enemies.keys():
		var tier = int(key.get_slice("_", 2))
		var e = enemies[key]

		# Filter by max_tier AND allowed_types
		if tier <= max_tier and e.type in allowed_types:
			prompt += "%s tier %d cost %d\n" % [e.type, tier, e.damage]

	prompt += "- You MUST only include enemies such that the sum of their costs <= total budget.\n"
	prompt += "- Do NOT include more enemies than the budget allows.\n"
	prompt += "- Do NOT exceed budget. Do NOT leave budget unused if you can reasonably spend it.\n"
	prompt += "- Output MUST be a valid JSON array.\n"
	prompt += "- Do NOT include explanations, comments, or extra text.\n"
	prompt += "- Example for budget of 30 you could only pick 3 TroopEnemy tier 1 units (because TroopEnemy tier 1 has Damage Cost of 10 which is also it is price):\n"


	# --- STRATEGY GUIDELINES ---
	prompt += "=== STRATEGY GUIDELINES ===\n"
	prompt += "- Read the full game state below and try to counter the player's towers.\n"
	prompt += "- Mix enemy types to maximize challenge given player's towers.\n"
	prompt += "- Prioritize survival of wave > reward > variety.\n\n"

	# --- GAME STATE ---
	prompt += "=== GAME STATE ===\n"
	prompt += current_game_state() + "\n\n"

	# --- OUTPUT FORMAT ---
	prompt += "=== OUTPUT FORMAT ===\n"
	prompt += "Return ONLY a JSON array. Each element MUST be exactly:\n"
	prompt += "{ \"type\": \"%s\", \"tier\": number }\n" % "|".join(allowed_types)
	prompt += "Do not include anything else."

	return prompt

# ==================================================================
# ---------------------------- GENERAL ------------------------------
# ==================================================================

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
	var game_state = "" 
	game_state += "Game status:\n" 
	game_state += "Current coins: %d\n" % coins 
	game_state += "Current health: %d\n" % health 
	game_state += "Already built towers(tower name with tier and count):%s\n" % built_towers_info 
	game_state += "Available tiles: %s\n" % available_tiles_info 
	game_state += "Each tower stats: %s\n" % tower_stats_info 
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
