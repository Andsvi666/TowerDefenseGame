class_name CanvasSelect
extends CanvasLayer

@onready var return_button: Button = $SubViewportContainer/SubViewport/ColorRect/ButtonReturn
@onready var play_standart_button: Button = $SubViewportContainer/SubViewport/ControlStandart/ButtonPlay
@onready var play_endless_button: Button = $SubViewportContainer/SubViewport/ControlEndless/ButtonPlay
@onready var play_AI_button: Button = $SubViewportContainer/SubViewport/ControlAI/ButtonPlay
@onready var hide_block_1: ColorRect = $SubViewportContainer/SubViewport/ControlEndless/ColorRectHide
@onready var hide_block_2: ColorRect = $SubViewportContainer/SubViewport/ControlAI/ColorRectHide

func _ready() -> void:
	return_button.pressed.connect(_on_return_button_pressed)
	play_standart_button.pressed.connect(_on_play_standart_button_pressed)
	play_endless_button.pressed.connect(_on_play_endless_button_pressed)
	play_AI_button.pressed.connect(_on_play_AI_button_pressed)
	check_completion()

func check_completion() -> void:
	if FirebaseMan.current_user_completion:
		hide_block_1.visible = false
		hide_block_2.visible = false
 
func _on_return_button_pressed() -> void:
	ScreenMan.change_screen("menu")

func _on_play_standart_button_pressed() -> void:
	GameMan.gamemode = "standard"
	ScreenMan.change_screen("game")

func _on_play_endless_button_pressed() -> void:
	GameMan.gamemode = "endless"
	ScreenMan.change_screen("game")

func _on_play_AI_button_pressed() -> void:
	GameMan.gamemode = "AI"
	ScreenMan.change_screen("game")
