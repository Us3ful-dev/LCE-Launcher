extends Node

var rootpath := OS.get_executable_path().get_base_dir() # (appdata/LCE-Launcher)-probably 
@onready var zipthread := Thread.new()

func open_folder(path :String) -> void:
	OS.shell_show_in_file_manager(path)

func make_dirs(dirs :Array) -> void:
	for dir in dirs:
		var fullpath = rootpath + dir
		if DirAccess.dir_exists_absolute(fullpath):
			if dir == "":
				dir = "/LCE-loader"
			print_rich("[color=green]dir [color=lightgreen]",dir, "[color=green] was already created")
		else:
			var err = DirAccess.make_dir_absolute(fullpath)
			if err == OK:
				print_rich("[color=green]Successfully created folder: [color=lightgreen]", fullpath)
			else:
				push_error("Error creating folder: ", fullpath, " with error: ", err)

func delete_file(path :String):
	print_rich("[color=green]Delete: ", path)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

func move_file_dir(oldpath :String, newpath :String):
	print_rich("[color=green]Move: ", oldpath + " To: ", newpath)
	var err = DirAccess.rename_absolute(oldpath, newpath)
	if err != OK:
		push_error("Move failed: ", err)

func copy_file_dir(oldpath :String, newpath :String, callnext :bool):
	print_rich("[color=green]Copy: ", oldpath + " To: ", newpath)
	var err = DirAccess.copy_absolute(oldpath, newpath)
	if err != OK:
		push_error("Copy failed: ", err)
	if callnext:
		GlobalVariables.uinode.current_install_step()

func delete_all_from_dir(path :String, dirto :bool) -> bool:
	for file in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path + "/" + file)
	for dir in DirAccess.get_directories_at(path):
		delete_all_from_dir(path + "/" + dir, false)
	if dirto:
		DirAccess.remove_absolute(path)
	return true

func save_data():
	make_write_json(rootpath + "/installsinfo.json", GlobalVariables.installations)
	make_write_json(rootpath + "/cache.json", GlobalVariables.cache)
	make_write_json(rootpath + "/config.json", GlobalVariables.config)

func make_write_json(filepath :String, data) -> void:
	var filename := filepath.get_file()
	var file = FileAccess.open(filepath, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
		print_rich("[color=green]created/updated [color=lightgreen]", filename, "[color=green] at: [color=lightgreen]", filepath)
	else:
		push_error("Could not create ", filename, " file at: ", filepath)

func open_json(filepath :String) -> Dictionary:
	if FileAccess.file_exists(filepath):
		var file = FileAccess.open(filepath, FileAccess.READ)
		var content = file.get_as_text()
		file.close()
		var result = JSON.parse_string(content)
		if typeof(result) == TYPE_DICTIONARY:
			return result
	return {}

func extract_zip(filepath :String, outputpath :String, removezip :bool, callnext :bool): # edited default godot code (see docs on ZIPReader)
	zipthread.start(thread_extract_zip.bind(filepath, outputpath, removezip, callnext)) # do check if thread is running else problems with muliple extracts at once

func thread_extract_zip(filepath :String, outputpath :String, removezip :bool, callnext :bool):
	print_rich("[color=green]zip assignment: FROM: ", filepath, "  TO: ", outputpath, "  REMOVEZIP: ", removezip)
	var reader := ZIPReader.new()
	var err := reader.open(filepath)
	if err != OK:
		push_error("failed to open zip: ", err)
		return
	
	var root_dir = DirAccess.open(outputpath)
	
	var files = reader.get_files()
	for file_path in files:
		# If the current entry is a directory.
		if file_path.ends_with("/"):
			root_dir.make_dir_recursive(file_path)
			continue
		
		root_dir.make_dir_recursive(root_dir.get_current_dir().path_join(file_path).get_base_dir())
		var file = FileAccess.open(root_dir.get_current_dir().path_join(file_path), FileAccess.WRITE)
		if file:
			var buffer = reader.read_file(file_path)
			file.store_buffer(buffer)
		else:
			push_error("failed to write: ", file_path)
	
	reader.close()
	
	if removezip:
		var rerr := DirAccess.remove_absolute(filepath)
		if rerr != OK:
			push_error("failed to delete old zip: ", err)
	
	if callnext:
		GlobalVariables.uinode.current_install_step() # probably not very clean but should work for now
	print_rich("[color=green]extraction complete")

func _exit_tree():
	if zipthread.is_alive():
		zipthread.wait_to_finish()
