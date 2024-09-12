@tool
extends EditorImportPlugin

func _get_importer_name():
	return "phoenixillusion.tiled.gridmap.importer"

func _get_visible_name():
	return "GridMap from Tiled"

func _get_recognized_extensions():
	return ["tmx"]

func _get_save_extension():
	return "tscn"

func _get_resource_type():
	return "PackedScene"

func _get_preset_count():
	return 1

func _get_import_order():
	return 200

func _get_option_visibility(path, option_name, options):
	return true

func _get_preset_name(preset_index):
	return "Default"

func _get_import_options(path, preset_index):
	return [
			{
				"name": "center_grid_map",
				"default_value": true
			},
			{
				"name": "y_offset",
				"default_value": 0
			},
			{
				"name": "x_offset",
				"default_value": 0
			},
			{
				"name": "z_offset",
				"default_value": 0
			},
			{
				"name": "tilemap_to_mesh_map_csv",
				"default_value": "",
				"property_hint": PROPERTY_HINT_FILE,
				"hint_string": "*.csv,*.tsv"
			}
		]

func _import(source_file, save_path, options, platform_variants, gen_files):
	var TiledToGridMap = load("res://addons/phoenixillusion.tiled.gridmap.importer/tiled_to_gridmap.gd")

	var tiledToGridMap = TiledToGridMap.new();

	var scene = PackedScene.new()
	# Fill the Mesh with data read in "file", left as an exercise to the reader.
	var gridMap = tiledToGridMap.build(source_file, options)
	scene.pack(gridMap)
	return ResourceSaver.save(scene, save_path + "." + _get_save_extension())
	
func _get_priority():
	return 2