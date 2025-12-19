class_name CanvasGameUI
extends CanvasLayer

@onready var pause_button: Button = $BarsControl/TopBar/ButtonPause
@onready var resume_button: Button = $PanelPauseMenu/VBoxContainer/ResumeButton
@onready var start_wave_button: Button = $BarsControl/TopBar/StartWaveButton
@onready var start_endless_wave_button: Button = $BarsControl/TopBar/StartEndlessButton
@onready var restart_button: Button = $PanelPauseMenu/VBoxContainer/RestartButton
@onready var restart_button_1: Button = $PanelGameOver/VBoxContainer/RestartButton
@onready var advice_button: Button = $BarsControl/SideBar/AdviceButton
@onready var firebase_button: Button = $PanelPauseMenu/VBoxContainer/FirebaseButton
@onready var menu_button: Button = $PanelPauseMenu/VBoxContainer/MenuButton
@onready var menu_button_1: Button = $PanelGameOver/VBoxContainer/MenuButton
@onready var advice_label: RichTextLabel = $BarsControl/SideBar/AdvicePanel/AdviceLabel
@onready var game_over_popup: AcceptDialog = $GameOverPopup
@onready var pause_panel: Panel = $PanelPauseMenu
@onready var game_panel: Panel = $PanelGameOver
# UI elements for gamemode configurations
@onready var gamemode_label: Label = $BarsControl/TopBar/LabelGamemode
@onready var wave_label: Label = $BarsControl/TopBar/WaveTitleLabel
@onready var wave_panel: PanelContainer = $BarsControl/TopBar/WavePanel
@onready var wave_panel_visual: PanelContainer = $BarsControl/TopBar/WavePanelVisual
@onready var endless_wave_label: Label = $BarsControl/TopBar/EndlessWaveTitleLabel
@onready var endless_wave_panel: PanelContainer = $BarsControl/TopBar/EndlessWavePanel
@onready var endless_wave_counter: Label = $BarsControl/TopBar/EndlessWavePanel/WaveLabel
@onready var endless_wave_panel_visual: PanelContainer = $BarsControl/TopBar/EndlessWavePanelVisual
@onready var box_label: Label = $BarsControl/SideBar/AdviceTitle
@onready var box_panel: RichTextLabel = $BarsControl/SideBar/AdvicePanel/AdviceLabel
@onready var box_panel_overlay: Panel = $BarsControl/SideBar/AdvicePanel
@onready var game_over_label: Label = $PanelGameOver/LabelDescription

func _ready() -> void:
	# Make sure the whole UI (including child buttons) keeps working while paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	for child in get_children():
		child.process_mode = Node.PROCESS_MODE_ALWAYS

	pause_button.pressed.connect(_on_pause_button_pressed)
	start_wave_button.pressed.connect(_on_start_wave_button_pressed)
	start_endless_wave_button.pressed.connect(_on_start_endless_wave_button_pressed)
	restart_button.pressed.connect(_on_game_over_restart)
	restart_button_1.pressed.connect(_on_game_over_restart)
	advice_button.pressed.connect(_on_advice_button_pressed)
	firebase_button.pressed.connect(_on_firebase_button_pressed)
	menu_button.pressed.connect(_on_menu_button_pressed)
	menu_button_1.pressed.connect(_on_menu_button_pressed)
	resume_button.pressed.connect(_on_resume_button_pressed)
	
	HealthMan.connect("update_label", Callable(self, "_on_update_label"))
	HealthMan.connect("game_over", Callable(self, "_on_game_over"))
	CoinsMan.connect("update_label", Callable(self, "_on_update_label"))
	WavesMan.connect("update_label", Callable(self, "_on_update_label"))
	SpawnerMan.connect("wave_complete", Callable(self, "_on_wave_complete"))
	GameMan.connect("game_setup_started", Callable(self, "_game_setup_started"))
	SpawnerMan.connect("endless_time_updated", Callable(self, "_update_timer"))
	GameMan.connect("update_log", Callable(self, "_update_log"))
	

func _game_setup_started() -> void:
	if GameMan.gamemode == "standard":
		gamemode_label.text = "Standard Mode"
		wave_label.visible = true
		wave_panel.visible = true
		wave_panel_visual.visible = true
		start_wave_button.visible = true
		box_label.text = "AI Generated Advice"
		box_panel.text = "Press 'Generate Advice' Button between waves to receive helpful guidance"
		box_panel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		advice_button.visible = true
	if GameMan.gamemode == "endless":
		gamemode_label.text = "Endless Mode"
		endless_wave_label.visible = true
		endless_wave_panel.visible = true
		endless_wave_panel_visual.visible = true
		start_endless_wave_button.visible = true
		box_label.text = "Game Actions Log"
		box_panel_overlay.anchor_bottom = 0.97
	if GameMan.gamemode == "AI":
		gamemode_label.text = "AI Mode"
		wave_label.visible = true
		wave_panel.visible = true
		wave_panel_visual.visible = true
		start_wave_button.visible = true
		box_label.text = "Game Actions Log"
		box_panel_overlay.anchor_bottom = 0.97

func _change_game_panel() -> void:
	get_tree().paused = true
	
	FirebaseMan.user_add_game()
	FirebaseMan.user_beat_campaign()
	
	var title_label: Label = game_panel.get_node_or_null("LabelTitle")
	var desc_label: Label = game_panel.get_node_or_null("LabelDescription")

	if title_label:
		title_label.text = "Waves Cleared"
	if desc_label:
		desc_label.text = "All enemies were defeated and Terminus is saved! Try again?"

	game_panel.visible = true

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_pause"):
		if pause_panel.visible:
			_on_resume_button_pressed()
		else:
			_on_pause_button_pressed()

func _update_timer(seconds: int) -> void:
	endless_wave_counter.text = str(seconds)

func _update_log(entry: String) -> void:
	box_panel.text += entry + "\n"
	box_panel.scroll_to_line(box_panel.get_line_count() - 1)

func _on_firebase_button_pressed() -> void:
	FirebaseMan.write_to_db()

func _on_update_label(sum: int, name: Label) -> void:
	name.text = str(sum)

func _on_wave_change(count: int) -> void:
	$TopBar/WaveLabel.text = str(count)

func _on_health_changed(health: int) -> void:
	$TopBar/HealthLabel.text = str(health)

func _on_wave_complete() -> void:
	if WavesMan.current_wave_index >= WavesMan.waves_count:
		_change_game_panel()
	else:
		GameMan.wave_active = false
		GameMan.stop_support_towers()
		start_wave_button.disabled = false
		advice_button.disabled = false
		show_wave_complete_message()

func show_wave_complete_message() -> void:
	var popup = AcceptDialog.new()
	popup.dialog_text = "Congrats! Wave Complete!"
	add_child(popup)
	popup.popup_centered()

func _on_game_over() -> void:
	FirebaseMan.user_add_game()
	get_tree().paused = true
	game_panel.visible = true
	if GameMan.gamemode == "endless":
		game_over_label.text = "You survived endless wave for %s seconds. Try again?" % endless_wave_counter.text
		FirebaseMan.user_update_endless(int(endless_wave_counter.text))

func _on_game_over_restart() -> void:
	if GameMan.gamemode == "endless":
		FirebaseMan.user_update_endless(int(endless_wave_counter.text))
		FirebaseMan.user_add_game()
	pause_panel.visible = false
	get_tree().paused = false
	SpawnerMan.stop_current_wave()
	ScreenMan.change_screen("game")

func _on_pause_button_pressed() -> void:
	get_tree().paused = true
	pause_panel.visible = true

func _on_resume_button_pressed() -> void:
	pause_panel.visible = false
	get_tree().paused = false

func _on_start_endless_wave_button_pressed() -> void:
	GameMan.start_support_towers()
	start_endless_wave_button.disabled = true
	SpawnerMan.start_endless_mode()

func _on_start_wave_button_pressed() -> void:
	GameMan.start_support_towers()
	WavesMan.start_next_wave()
	start_wave_button.disabled = true
	advice_button.disabled = true

func _on_advice_button_pressed() -> void:
	advice_button.disabled = true
	advice_label.text = "Thinking..."
	
	# Await AIManager.ask_ai (synchronous-looking)
	var advice = await AiMan.ask_AI_advice()
	
	# Update UI
	advice_label.text = advice
	advice_button.disabled = false

func _on_menu_button_pressed() -> void:
	#print_debug("to menu")
	pause_panel.visible = false
	get_tree().paused = false
	if GameMan.gamemode == "endless":
		FirebaseMan.user_update_endless(int(endless_wave_counter.text))
		FirebaseMan.user_add_game()
	ScreenMan.change_screen("menu")
	#switch to menu
 
