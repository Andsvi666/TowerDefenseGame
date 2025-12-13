class_name ImageTool
# 常见图片格式的魔数签名
static var FORMAT_SIGNATURES = {
	"png": [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
	"jpg": [0xFF, 0xD8, 0xFF],
	"jpeg": [0xFF, 0xD8, 0xFF],
	"webp": [0x52, 0x49, 0x46, 0x46, null, null, null, null, 0x57, 0x45, 0x42, 0x50],
	"bmp": [0x42, 0x4D],
	"tga": [0x00, 0x00, 0x0A, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00],
	# 添加更多格式的签名...
}

# 从PackedByteArray检测图片格式
static func detect_image_format(data: PackedByteArray) -> String:
	if data.size() < 12:  # 确保数据足够长以包含签名
		return ""
	
	for format in FORMAT_SIGNATURES:
		var signature = FORMAT_SIGNATURES[format]
		var _match = true
		
		for i in range(signature.size()):
			if signature[i] == null:  # 通配符，跳过检查这个字节
				continue
			if i >= data.size() or data[i] != signature[i]:
				_match = false
				break
		
		if _match:
			return format
	
	return ""

# 加载图片数据
static func load_image_from_bytes(data: PackedByteArray) -> Image:
	var format = detect_image_format(data)
	var image = Image.new()
	
	match format:
		"png":
			image.load_png_from_buffer(data)
		"jpg", "jpeg":
			image.load_jpg_from_buffer(data)
		"webp":
			image.load_webp_from_buffer(data)
		"bmp":
			image.load_bmp_from_buffer(data)
		"tga":
			image.load_tga_from_buffer(data)
		_:
			return null
	return image
