class_name TiledToGridMap

# XML Parsing Logic: Copied 9-05-2024
# https://github.com/vnen/godot-tiled-importer/blob/master/addons/vnen.tiled_importer/tiled_map_reader.gd

# Constants for tile flipping
# http://doc.mapeditor.org/reference/tmx-map-format/#tile-flipping
const FLIPPED_HORIZONTALLY_FLAG = 0x80000000
const FLIPPED_VERTICALLY_FLAG   = 0x40000000
const FLIPPED_DIAGONALLY_FLAG   = 0x20000000

func build(source_file, options)->GridMap:
	var TiledXMLToDictionary = load("res://addons/phoenixillusion.tiled.gridmap.importer/tiled_xml_to_dict.gd")
	var tmx_to_dict = TiledXMLToDictionary.new()
	var data: Dictionary = tmx_to_dict.read_tmx(source_file)
	if typeof(data) != TYPE_DICTIONARY:
		# Error happened
		printerr("Error parsing map file '%s'." % [source_file])
		return
	var width = data.width
	var height = data.height
	var layers: Array = data.layers
	var tile_id_map: Dictionary = {}
	if options.tilemap_to_mesh_map_csv != "":
		tile_id_map = TiledToGridMap.parseCSVMap(options.tilemap_to_mesh_map_csv)
	var gridMap = GridMap.new()
	var y: int = 0
	for layer in layers:
		if layer.type == "tilelayer":
			var chunks = []

			if data.infinite:
				chunks = layer.chunks
			else:
				chunks = [layer]
			TiledToGridMap.parseLayer(gridMap, layer, chunks, y, tile_id_map, options)
			y += 1
	return gridMap

static func parseCSVMap(source_file: String)->Dictionary:
	var file = FileAccess.open(source_file, FileAccess.READ)
	if not file:
		printerr("Failed to open file: ", source_file)
		return {}
	var result: Dictionary = {}
	var delim = ","
	if source_file.ends_with(".tsv"):
		delim = "\t"
	while not file.eof_reached():
		var line = file.get_csv_line(delim)
		if line.size() == 2:
			var a = line[0]
			var b = line[1]
			if a.is_valid_int() and b.is_valid_int():
				result[a.to_int()] = b.to_int() 
	file.close()

	return result

static func parseLayer(g: GridMap, layer, chunks, world_y: int, tile_id_map: Dictionary, options):

	for chunk in chunks:
		var chunk_data = chunk.data

		if "encoding" in layer and layer.encoding == "base64":
			if "compression" in layer:
				chunk_data = decompress_layer_data(chunk_data, layer.compression, chunk.width, chunk.height)
				if typeof(chunk_data) == TYPE_INT:
					# Error happened
					return chunk_data
			else:
				chunk_data = read_base64_layer_data(chunk_data)

		var count = 0
		for tile_id in chunk_data:
			var int_id = int(str(tile_id)) & 0xFFFFFFFF

			if int_id == 0:
				count += 1
				continue
			int_id -= 1

			var flipped_h = bool(int_id & FLIPPED_HORIZONTALLY_FLAG)
			var flipped_v = bool(int_id & FLIPPED_VERTICALLY_FLAG)
			var flipped_d = bool(int_id & FLIPPED_DIAGONALLY_FLAG)

			var gid = int_id & ~(FLIPPED_HORIZONTALLY_FLAG | FLIPPED_VERTICALLY_FLAG | FLIPPED_DIAGONALLY_FLAG)
			if tile_id_map.has(gid):
				print("Replacing: ",gid, " => ", tile_id_map[gid])
				gid = tile_id_map[gid]

			var x_offset = options.x_offset + chunk.x;
			var y_offset = options.y_offset;
			var z_offset = options.z_offset + chunk.y;

			if options.center_grid_map:
				x_offset -= int(layer.width / 2)
				z_offset -= int(layer.height / 2)

			var world_x = (count % int(chunk.width))
			var world_z = int(count / chunk.width)
			set_cell(g, world_x + x_offset, world_y + y_offset, world_z + z_offset, gid, parse_rotation(flipped_h, flipped_v, flipped_d))

			count += 1

const ROT_0 = 0
const ROT_90 = 22
const ROT_180 = 16
const ROT_270 = 10

static func parse_rotation(flipped_h: bool, flipped_v: bool, flipped_d: bool)->int:
	if flipped_h and flipped_d:
		return ROT_90
	if flipped_v and flipped_d:
		return ROT_180
	if flipped_h and flipped_v:
		return ROT_270
	return ROT_0

static func set_cell(g: GridMap, x: int, y: int, z: int, gid: int, rot: int):
	g.set_cell_item(Vector3i(x,y,z), gid, rot)

# Below Functions: Copied from vnen.tiled_importer

# Decompress the data of the layer
# Compression argument is a string, either "gzip" or "zlib"
static func decompress_layer_data(layer_data: String, compression: String, width: int, height: int):
	if compression != "gzip" and compression != "zlib":
		printerr("Unrecognized compression format: %s" % [compression])
		return ERR_INVALID_DATA

	var compression_type = FileAccess.COMPRESSION_DEFLATE if compression == "zlib" else FileAccess.COMPRESSION_GZIP
	var expected_size = int(width) * int(height) * 4
	var raw_data = Marshalls.base64_to_raw(layer_data).decompress(expected_size, compression_type)

	return decode_layer(raw_data)

# Reads the layer as a base64 data
# Returns an array of ints as the decoded layer would be
static func read_base64_layer_data(layer_data):
	var decoded = Marshalls.base64_to_raw(layer_data)
	return decode_layer(decoded)

# Reads a PoolByteArray and returns the layer array
# Used for base64 encoded and compressed layers
static func decode_layer(layer_data):
	var result = []
	for i in range(0, layer_data.size(), 4):
		var num = (layer_data[i]) | \
				(layer_data[i + 1] << 8) | \
				(layer_data[i + 2] << 16) | \
				(layer_data[i + 3] << 24)
		result.push_back(num)
	return result
