class_name DictionaryTool


static func generate_new_random_hash_key(dictionary:Dictionary,length:int=32)->String:
	var hash_key:String=generate_random_hash(length)
	while dictionary.has(hash_key):
		hash_key=generate_random_hash(length)
	return hash_key

static func generate_random_hash(length: int = 32) -> String:
	# 计算需要的字节数（每个字节对应2个十六进制字符）
	var byte_count = ceil(length / 2.0)
	var crypto = Crypto.new()
	var random_bytes = crypto.generate_random_bytes(byte_count)
	return bytes_to_hex(random_bytes).substr(0, length)

static func bytes_to_hex(bytes: PackedByteArray) -> String:
	"""将字节数组转换为十六进制字符串"""
	var hex_chars = "0123456789abcdef"
	var result = ""
	for byte in bytes:
		result += hex_chars[byte >> 4]  # 高4位
		result += hex_chars[byte & 0x0F]  # 低4位
	return result
