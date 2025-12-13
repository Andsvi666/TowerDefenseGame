class_name CanvasMenu
extends CanvasLayer

@onready var play_button: Button = $SubViewportContainer/SubViewport/VBoxContainerMain/StartButton
@onready var logout_button: Button = $SubViewportContainer/SubViewport/VBoxContainerMain/LogoutButton
@onready var user_name_label: Label = $SubViewportContainer/SubViewport/VBoxContainerRight/LabelUserName
@onready var user_image_rect: TextureRect = $SubViewportContainer/SubViewport/VBoxContainerRight/Control/ImageRect
@onready var user_total_games: Label = $SubViewportContainer/SubViewport/VBoxContainerLeft/HBoxContainerTotalGames/LabelData
@onready var user_total_kills: Label = $SubViewportContainer/SubViewport/VBoxContainerLeft/HBoxContainerTotalKills/LabelData
@onready var user_total_towers: Label = $SubViewportContainer/SubViewport/VBoxContainerLeft/HBoxContainerTotalTowers/LabelData
@onready var user_best_AI: Label = $SubViewportContainer/SubViewport/VBoxContainerLeft/HBoxContainerAiWavesRecord/LabelData
@onready var user_best_endless: Label = $SubViewportContainer/SubViewport/VBoxContainerLeft/HBoxContainerEndlessSeconds/LabelData

var temp_user_pic_path := "res://temp files/temp_user_pic.png"

func _ready() -> void:
	play_button.pressed.connect(_on_play_button_pressed)
	logout_button.pressed.connect(_on_logout_button_pressed)
	setup_user_profile()

func _on_play_button_pressed() -> void:
	ScreenMan.change_screen("game")

func _on_logout_button_pressed() -> void:
	FirebaseMan.logout_user()
	ScreenMan.change_screen("login")

func setup_user_profile() -> void:
	var user_data = FirebaseMan.current_user
	var custom_name = ""
	if user_data.has("fullname") and user_data["fullname"] != "":
		var user_name = user_data["fullname"]
		custom_name = format_name_by_width(user_name, user_name_label, 300)
		user_name_label.text = custom_name
	else:
		user_name_label.text = "No name found"
	# Check and set user picture
	if user_data.has("photourl") and user_data["photourl"] != "":
		setup_user_image(user_data["photourl"])
	if user_data.has("localid") and user_data["localid"] != "":
		setup_user_stats()

func setup_user_stats() -> void:
	var stats = await FirebaseMan.read_user_stats()
	await get_tree().process_frame
	user_total_games.text = str(stats.get("total_games_played", 0))
	user_total_kills.text = str(stats.get("total_enemies_killed", 0))
	user_total_towers.text = str(stats.get("total_towers_built", 0))
	user_best_AI.text = str(stats.get("highest_AI_wave", 0))
	user_best_endless.text = str(stats.get("longest_endless_time", 0))

func setup_user_image(url: String) -> void:
	var http = HTTPRequest.new()
	add_child(http)
	
	http.request_completed.connect(func(result, response_code, headers, body):
		if result != OK or response_code != 200:
			push_error("Failed to download image")
			return
		#print_debug(body)
		var img = Image.new()
		var err = img.load_jpg_from_buffer(body)
		if err != OK:
			#print_debug("Not a JPG")
			err = img.load_png_from_buffer(body)
			if err != OK:
				push_error("Not PNG or JPG")
				return
		
		#print_debug("Passed")
		var tex = ImageTexture.create_from_image(img)
		user_image_rect.texture = tex
	)
	
	http.request(url)

func format_name_by_width(name: String, label: Label, max_width: float) -> String:
	var font = label.get_theme_font("font")
	var result := ""
	var current_line := ""
	var lines = 0
	
	for i in name.length():
		var char := name.substr(i, 1)
		var test_line := current_line + char
		
		var width = font.get_string_size(test_line).x
		
		if width > max_width:
			lines += 1
			if lines == 2:
				# If second line overflows, trim last char and add "..."
				current_line = current_line.substr(0, current_line.length() - 1) + "..."
				result += "\n" + current_line
				return result
			else:
				# Add first line
				if result != "":
					result += "\n"
				result += current_line
				current_line = char
		else:
			current_line = test_line
	
	# Add the last line if there's space
	lines += 1
	if lines > 2:
		current_line = current_line.substr(0, current_line.length() - 1) + "..."
		result += "\n" + current_line
	else:
		if result != "":
			result += "\n"
		result += current_line
	
	return result
