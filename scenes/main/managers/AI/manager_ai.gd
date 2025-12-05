class_name ManagerAI
extends Node

# === CONFIG ===
const API_KEY := "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"
const MODEL := "meta-llama/llama-3.1-8b-instruct"
const URL := "https://openrouter.ai/api/v1/chat/completions"

# === INTERNAL ===
var _http := HTTPRequest.new()

func _ready():
	# Add HTTPRequest node once
	add_child(_http)

# === PUBLIC FUNCTION ===
# Async function you can await in your UI
func ask_ai(prompt: String) -> String:
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
		"max_tokens": 128,
		"temperature": 0.6
	}

	var json_body = JSON.stringify(body)

	# --- Send request ---
	var err = _http.request(URL, headers, HTTPClient.METHOD_POST, json_body)
	if err != OK:
		push_error("AI request failed: %s" % err)
		return "Error sending request"

	# --- Wait for response ---
	var result = await _http.request_completed

	# result is a tuple: (result, response_code, headers, body_bytes)
	var response_code = result[1]
	var body_bytes = result[3]
	var body_text = body_bytes.get_string_from_utf8()

	if response_code != 200:
		return "AI Error: %s" % body_text

	# --- Parse JSON ---
	var json = JSON.new()
	var error = json.parse(body_text)
	if error != OK:
		return "Failed to parse AI response"

	var data = json.get_data()  # This is your parsed dictionary


	# --- Extract AI content ---
	# OpenRouter returns something like:
	# {"id":"...","object":"chat.completion","model":"meta-llama/...","choices":[{"message":{"role":"assistant","content":"..."},"index":0}]}

	if not data.has("choices") or data["choices"].size() == 0:
		return "No AI response found"

	var choice = data["choices"][0]
	if not choice.has("message") or not choice["message"].has("content"):
		return "Malformed AI response"

	var advice = str(choice["message"]["content"]).strip_edges()  # remove extra whitespace
	#print_debug(advice)
	return advice
