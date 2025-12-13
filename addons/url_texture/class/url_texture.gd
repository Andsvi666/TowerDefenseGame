@icon("./url_texture.svg")
extends Texture2D
##使用url进行网络加载的图片资源
class_name URLTexture

##当前正在显示的Texture2D
var _inner_texture:Texture2D:
	set(value):
		_inner_texture=value
		emit_changed()
		pass

@export var url:String="":
	set(value):
		url=value
		
		pass
		


##图片缓存模式
enum CacheMode{
	##不使用任何缓存，每次加载时重新下载
	NONE,
	##使用单例进行缓存
	CACHE_MANAGER,
	##使用自己的独立缓存进行缓存
	CACHE_SELF
}
@export var cache_mode:CacheMode=CacheMode.NONE
##使用的图片下载模式
enum DownloadType{
	##使用自身的HTTPClient进行下载（并行）
	SELF,
	##使用Manager单例进行排队下载
	MANAGER,
}
@export var download_type:DownloadType=DownloadType.SELF
enum TextureType{
	##在下载完毕后进行展示
	NORMAL,
	#TODO:
	##渐进式图片
	PROGRESSING
}



##当正在加载时使用的图片资源
@export var texture_loading:Texture2D
##当加载失败时显示的图片资源
@export var texture_load_failed:Texture2D
##当处于非加载状态时使用的texture
@export var texture_normal:Texture2D


var _inner_file_data:PackedByteArray=PackedByteArray()
##内部使用的HTTPRequest
var _inner_http_request:HTTPRequest=null


enum State{
	FREE,
	LOADING,
}

var state:State=State.FREE

#region cache

var file_cache:Dictionary[String,PackedByteArray]={}
var texture_cache:Dictionary[String,Texture2D]={}

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


func add_to_self_cache(url:String,data:PackedByteArray,texture:Texture2D):
	file_cache[url]=data
	texture_cache[url]=texture
	pass
#endregion



#region remap

func _draw(to_canvas_item: RID, pos: Vector2, modulate: Color, transpose: bool) -> void:
	if _inner_texture==null:
		return
	_inner_texture.draw(to_canvas_item,pos,modulate,transpose)
	
	
	pass
func _draw_rect(to_canvas_item: RID, rect: Rect2, tile: bool, modulate: Color, transpose: bool) -> void:
	if _inner_texture==null:
		return
	_inner_texture.draw_rect(to_canvas_item,rect,tile,modulate,transpose)
	
	
	pass
func _draw_rect_region(to_canvas_item: RID, rect: Rect2, src_rect: Rect2, modulate: Color, transpose: bool, clip_uv: bool) -> void:
	if _inner_texture==null:
		return
	_inner_texture.draw_rect_region(to_canvas_item,rect,src_rect,modulate,transpose,clip_uv)
	
	pass
func _get_height() -> int:
	if _inner_texture==null:
		return 0
	return _inner_texture.get_height()
func _get_width() -> int:
	if _inner_texture==null:
		return 0
	return _inner_texture.get_width()
func _has_alpha() -> bool:
	if _inner_texture==null:
		return false
	return _inner_texture.has_alpha()
func _is_pixel_opaque(x: int, y: int) -> bool:
	
	if _inner_texture==null:
		return false
	return _inner_texture._is_pixel_opaque(x,y)
#endregion

func _on_url_changed():
	match cache_mode:
		CacheMode.NONE:
			
			pass
		CacheMode.CACHE_MANAGER:
			
			pass
		CacheMode.CACHE_SELF:
			
			pass
	
	
	pass




#构造函数
func  _init() -> void:
	if Engine.has_singleton("UrlTextureManager"):
		var singleton=Engine.get_singleton("URLTextureManager")
		if singleton is Node:
			_inner_http_request=HTTPRequest.new()
			singleton.add_child(_inner_http_request)
	else:
		push_error("未找到单例，请启用URLTexture插件！")
	pass

static func create_from_url(url:String,cache_mode:CacheMode=CacheMode.NONE,download_type:DownloadType=DownloadType.SELF,texture_loading:Texture2D=null,texture_normal:Texture2D=null,texture_load_failed:Texture2D=null)->URLTexture:
	var texture=URLTexture.new()
	texture.cache_mode=cache_mode
	texture.download_type=download_type
	texture.url=url
	return texture


# 析构函数
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if  is_instance_valid(_inner_http_request) and _inner_http_request!=null:
			_inner_http_request.queue_free()
		pass
