class_name CanvasMenu
extends CanvasLayer

@onready var play_button: Button = $SubViewportContainer/SubViewport/VBoxContainer/StartButton
@onready var logout_button: Button = $SubViewportContainer/SubViewport/VBoxContainer/LogoutButton

func _ready() -> void:
	play_button.pressed.connect(_on_play_button_pressed)
	logout_button.pressed.connect(_on_logout_button_pressed)

func _on_play_button_pressed():
	ScreenMan.change_screen("game")

func _on_logout_button_pressed():
	FirebaseMan.logout_user()
	ScreenMan.change_screen("login")
