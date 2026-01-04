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

# === CONFIG OPEN ===
var API_KEY = ""
const MODEL_FREE_GOOD = "xiaomi/mimo-v2-flash:free"
const MODEL_BEST = "openai/gpt-5.2-pro"
const MODEL_GOOD = "openai/chatgpt-4o-latest"
const MODEL_FREE_TRY = "mistralai/devstral-2512:free"
const URL = "https://openrouter.ai/api/v1/chat/completions"
# === CONFIG OPEN ===
var API_KEY_GEM = ""
var MODEL_GEM = "gemini-2.5-flash-lite"
var URL_GEMINI = "https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent" % MODEL_GEM

# === INTERNAL ===
var _http := HTTPRequest.new()

func setup():
	#"api key" for original api
	API_KEY = await FirebaseMan.read_api_key("pyro")
	API_KEY_GEM = await FirebaseMan.read_api_key("gemini key")
	add_child(_http)

func send_request(prompt: String) -> String:
	#print_debug(MODEL_FREE_TRY)
	
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer %s" % API_KEY
	]

	var body = {
		"model": MODEL_FREE_TRY,
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

func send_request_gemini(prompt: String, type: String) -> String:
	# Gemini uses 'x-goog-api-key' header
	var headers = [
		"Content-Type: application/json",
		"x-goog-api-key: %s" % API_KEY_GEM
	]

	# Base generation config
	var generation_config := {
		"temperature": 0.6,
		"maxOutputTokens": 1024
	}

	# Force JSON ONLY for wave generation
	if type == "wave":
		generation_config["responseMimeType"] = "application/json"

	var body = {
		"contents": [
			{
				"parts": [
					{ "text": prompt }
				]
			}
		],
		"generationConfig": generation_config
	}

	var err = _http.request(URL_GEMINI, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		print_debug("HTTP Request Error: ", err)
		return ""

	var result = await _http.request_completed
	
	# Check for successful response (HTTP 200)
	if result[1] != 200:
		print_debug("Gemini Error Code: ", result[1])
		print_debug("Gemini Response: ", result[3].get_string_from_utf8())
		return ""

	var json := JSON.new()
	if json.parse(result[3].get_string_from_utf8()) != OK:
		print_debug("Failed to parse Gemini JSON")
		return ""

	var data = json.get_data()
	
	# Navigate the Gemini response tree
	if data.has("candidates") and not data["candidates"].is_empty():
		var first_candidate = data["candidates"][0]
		if first_candidate.has("content") and first_candidate["content"].has("parts"):
			return str(first_candidate["content"]["parts"][0]["text"]).strip_edges()

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
		return "AI model did not return any advice."

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
	ai_prompt += "- Tier 1 towers require empty tiles; higher tiers require upgrading.\n"
	ai_prompt += "- Priority: survival > damage > coin generation.\n\n"

	# --- GAME CONTEXT ---
	ai_prompt += "Next wave enemies (Type, Tier):\n%s\n" % next_wave
	ai_prompt += "=== GAME STATE and BASIC RULES ===\n"
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

func generate_wave(budget: int, allowed_enemies: Array) -> Array:
	var generated_wave = []
	var prompt = await collect_waves_prompt(budget, allowed_enemies)
	print_debug(prompt)
	var response = await send_request(prompt)
	print_debug(response)
	#print_debug("BUDGET:")
	#print_debug(budget)
	#print_debug("GENERATED RESPONSE:")
	#print_debug(response)
	var data = rework_response(response)
	print_debug(data)
	var message = "Wave has been generated"
	GameMan.log_event(message)
	#print_debug("REWORKED RESPONSE:")
	#print_debug(data)

	return data

func rework_response(response: String) -> Array:
	var wave := []
	if response == "":
		return wave

	# Step 1: Find start of array
	var start := response.find("[")
	if start == -1:
		print_debug("No JSON array start found")
		return wave

	# Step 2: Walk through and find last complete object
	var depth := 0
	var last_valid_index := -1
	for i in range(start, response.length()):
		var c := response[i]
		if c == "{":
			depth += 1
		elif c == "}":
			depth -= 1
			if depth == 0:
				last_valid_index = i

	# No complete objects
	if last_valid_index == -1:
		print_debug("No complete JSON objects found")
		return wave

	# Step 3: Rebuild valid JSON array
	var safe_json := response.substr(start, last_valid_index - start + 1) + "]"

	# Step 4: Parse salvaged JSON
	var json := JSON.new()
	if json.parse(safe_json) != OK:
		print_debug("Salvaged JSON still invalid")
		return wave

	var raw_wave = json.get_data()
	if typeof(raw_wave) != TYPE_ARRAY:
		return wave

	# Step 5: Convert to wave format
	for e in raw_wave:
		if typeof(e) != TYPE_DICTIONARY:
			continue
		if not e.has("type") or not e.has("tier"):
			continue

		var tier_index := int(e["tier"]) - 1
		if tier_index < 0:
			tier_index = 0

		wave.append({
			"type": e["type"],
			"tier_index": tier_index,
			"spawn_delay": 2.0
		})

	return wave


func collect_waves_prompt(budget: int, allowed_enemies: Array) -> String:
	var prompt := ""

	# --- CORE DIRECTIVE ---
	prompt += "You are an enemy commander in a tower defense game. "
	prompt += "Your goal is to defeat the player by designing an enemy wave. "
	prompt += "You may reason internally using the full game state, but your output must ONLY be the wave JSON response.\n\n"

	# --- HARD CONSTRAINTS ---
	prompt += "=== HARD CONSTRAINTS ===\n"
	prompt += "- Total budget: %d (each enemy costs its damage value)\n" % budget
	prompt += "- You may only use these enemies (type and tier):\n"

	#print_debug(allowed_enemies)
	var enemies = get_enemy_stats_summary()
	for key in enemies.keys():
		var e = enemies[key]
		# Filter by allowed_enemies
		if key in allowed_enemies:
			prompt += "enemy %s tier %d cost %d\n" % [e.type, e.tier, e.damage]
			#print_debug("enemy %s tier %d cost %d\n" % [e.type, e.tier, e.damage] )

	prompt += "- Do NOT include more enemies than the budget allows.\n"
	prompt += "- Do NOT exceed budget. Do NOT leave budget unused if you can reasonably spend it.\n"
	prompt += "- Output MUST be a valid JSON array.\n"
	prompt += "- Do NOT include explanations, comments, extra text or comma after last entry.\n"
	prompt += "- Example for budget of 30 you could only pick 3 TroopEnemy tier 1 units (because TroopEnemy tier 1 has Damage Cost of 10 which is also it is price)\n\n"
	# --- STRATEGY GUIDELINES ---
	prompt += "=== STRATEGY GUIDELINES ===\n"
	prompt += "- Read the full game state below and try to counter the player's towers.\n"
	prompt += "- Based on state try to spawn units for which user has no towers built (example no cannons - spam tanks).\n"
	prompt += "- Mix enemy types to maximize challenge given player's towers.\n"
	prompt += "- Prioritize survival of wave > reward > variety.\n\n"

	# --- GAME STATE ---
	prompt += "=== GAME STATE and BASIC RULES ===\n"
	prompt += current_game_state() + "\n\n"

	# --- OUTPUT FORMAT ---
	prompt += "=== OUTPUT FORMAT ===\n"
	prompt += "Return ONLY a JSON array. Each element MUST be formated this:\n"
	prompt += "{ type: [TroopEnemy, TankEnemy or PlaneEnemy], tier: [number for tier 1, 2 or 3] }\n"
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
		built_towers_info += "%s: %d, \n" % [t_name, BuildingMan.built_towers[t_name]] 
	var available_tiles_info := "" 
	for t_type in BuildingMan.available_tiles_for_towers.keys(): 
		available_tiles_info += "%s: %d, \n" % [t_type, BuildingMan.available_tiles_for_towers[t_type]] 
	var tower_stats = get_tower_stats_summary() 
	var tower_stats_info := "" 
	for key in tower_stats.keys(): 
		var s = tower_stats[key] 
		tower_stats_info += "%s: dmg %.1f, fire %.1f, range %.1f, cost %d coins, target %s; " % [ key.capitalize(), s.damage, s.firerate, s.range, s.cost, s.target_group ] # Enemy stats summary 
	var game_state = "" 
	game_state += "Game status:\n" 
	game_state += "Current coins: %d\n" % coins 
	game_state += "Current health: %d\n" % health 
	game_state += "Already built towers(tower name with tier and count):\n%s" % built_towers_info 
	game_state += "Available tiles:\n%s" % available_tiles_info 
	game_state += "Each tower stats: %s\n" % tower_stats_info 
	game_state += "BASIC RULES\n"
	game_state += "Turrets attack Troops, Cannons attack Tanks, Missiles attack Planes, Support towers heal base and generate coins passively\n"
	game_state += "Towers once built stay persistent trought all waves\n"
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
				"tier": res.tier,
				"health": res.max_health,       # enemy HP
				"speed": res.movement_speed,    # movement speed
				"damage": res.damage_cost,      # damage to base
				"reward": res.coin_reward,      # coins given when killed
			}
	return stats_summary
