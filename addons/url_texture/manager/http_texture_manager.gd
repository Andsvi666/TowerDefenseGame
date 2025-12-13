extends Node



var file_cache:Dictionary[String,PackedByteArray]={}
var texture_cache:Dictionary[String,Texture2D]={}

var manager_download_queue:Array[String]=[]


var main_http_request_node:HTTPRequest

func find_file_cache(url:String):
	if file_cache.has(url):
		return file_cache[url]
	else:
		return null
func find_texture_cache(url:String):
	if texture_cache.has(url):
		return texture_cache[url]
	else:
		return null


func _ready() -> void:
	main_http_request_node=HTTPRequest.new()
	add_child(main_http_request_node)
	main_http_request_node.request_completed.connect(_on_main_http_request_finished)
	
	
	pass

func _on_main_http_request_finished(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	
	
	
	
	pass
