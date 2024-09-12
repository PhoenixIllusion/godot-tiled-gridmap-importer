@tool
extends EditorPlugin

var import_plugin

func _enter_tree() -> void:
	import_plugin = preload("res://addons/phoenixillusion.tiled.gridmap.importer/import_plugin.gd").new()
	add_import_plugin(import_plugin)


func _exit_tree() -> void:
	remove_import_plugin(import_plugin)
	import_plugin = null
