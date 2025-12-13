@tool
extends EditorPlugin

func _enter_tree() -> void:
	add_autoload_singleton("URLTextureManager","./manager/http_texture_manager.gd")
	
	pass
	
	
	

func _exit_tree() -> void:
	remove_autoload_singleton("URLTextureManager")
	
	
	
	pass
