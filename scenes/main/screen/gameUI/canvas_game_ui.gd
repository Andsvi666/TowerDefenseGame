class_name CanvasGameUI
extends CanvasLayer

@onready var pause_button: Button = $BarsControl/BottomBar/Flexor/PauseButton
@onready var start_wave_button: Button = $BarsControl/BottomBar/Flexor/StartWaveButton
@onready var restart_button: Button = $BarsControl/BottomBar/Flexor/RestartButton
@onready var advice_button: Button = $BarsControl/BottomBar/Flexor/AdviceButton
@onready var firebase_button: Button = $BarsControl/BottomBar/Flexor/FirebaseButton
@onready var advice_label: RichTextLabel = $BarsControl/SideBar/AdvicePanel/AdviceLabel
@onready var game_over_popup: AcceptDialog = $GameOverPopup

var can_start_wave := true
var is_paused := false

func _ready() -> void:
	# Make sure the whole UI (including child buttons) keeps working while paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	for child in get_children():
		child.process_mode = Node.PROCESS_MODE_ALWAYS

	pause_button.pressed.connect(_on_pause_button_pressed)
	start_wave_button.pressed.connect(_on_start_wave_button_pressed)
	restart_button.pressed.connect(_on_game_over_restart)
	advice_button.pressed.connect(_on_advice_button_pressed)
	firebase_button.pressed.connect(_on_firebase_button_pressed)
	
	HealthMan.connect("update_label", Callable(self, "_on_update_label"))
	HealthMan.connect("game_over", Callable(self, "_on_game_over"))
	CoinsMan.connect("update_label", Callable(self, "_on_update_label"))
	WavesMan.connect("update_label", Callable(self, "_on_update_label"))
	SpawnerMan.connect("wave_complete", Callable(self, "_on_wave_complete"))

func _on_firebase_button_pressed() -> void:
	FirebaseMan.write_to_db()

func _on_update_label(sum: int, name: Label) -> void:
	name.text = str(sum)

func _on_wave_change(count: int) -> void:
	$TopBar/WaveLabel.text = str(count)

func _on_health_changed(health: int) -> void:
	$TopBar/HealthLabel.text = str(health)

func _on_wave_complete() -> void:
	GameMan.wave_active = false
	GameMan.stop_support_towers()
	can_start_wave = true
	start_wave_button.disabled = false
	advice_button.disabled = false
	show_wave_complete_message()

func show_wave_complete_message() -> void:
	var popup = AcceptDialog.new()
	popup.dialog_text = "Congrats! Wave Complete!"
	add_child(popup)
	popup.popup_centered()

func _on_game_over() -> void:
	# Show popup
	game_over_popup.popup_centered()
	
	# Connect confirmed signal only once
	if not game_over_popup.is_connected("confirmed", Callable(self, "_on_game_over_restart")):
		game_over_popup.connect("confirmed", Callable(self, "_on_game_over_restart"))

func _on_game_over_restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_pause_button_pressed() -> void:
	is_paused = !is_paused
	get_tree().paused = is_paused
	pause_button.text = "Resume" if is_paused else "Pause"

	# Keep button disabled if a wave is running, even after unpause
	if !can_start_wave:
		start_wave_button.disabled = true
	else:
		start_wave_button.disabled = is_paused

func _on_start_wave_button_pressed() -> void:
	if not can_start_wave:
		#GameMan.show_floating_message("A wave is already in progress!")
		return  # do nothing if wave is in progress
	WavesMan.start_next_wave()
	can_start_wave = false
	start_wave_button.disabled = true
	advice_button.disabled = true

func _on_advice_button_pressed() -> void:
	advice_button.disabled = true
	advice_label.text = "Thinking..."
	
	# Await AIManager.ask_ai (synchronous-looking)
	var prompt = await GameMan.collect_ai_prompt()
	var advice = await AiMan.ask_ai(prompt)
	
	# Update UI
	advice_label.text = advice
	advice_button.disabled = false
