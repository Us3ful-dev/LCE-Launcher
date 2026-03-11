extends Node

var rootpath := OS.get_executable_path().get_base_dir() # (appdata/LCE-Launcher)-probably 
var zipthread :Thread

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
			var error = DirAccess.make_dir_absolute(fullpath)
			if error == OK:
				print_rich("[color=green]Successfully created folder: [color=lightgreen]", fullpath)
			else:
				push_error("Error creating folder: ", fullpath, " with error: ", error)

func save_installsdata():
	make_write_json(rootpath + "/installsinfo.json", GlobalVariables.installations)

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
		return result
	return {}

func extract_zip(filepath :String, outputpath :String, removezip :bool): # edited default godot code (see docs on ZIPReader)
	zipthread = Thread.new()
	zipthread.start(thread_extract_zip.bind(filepath, outputpath, removezip))

func thread_extract_zip(filepath :String, outputpath :String, removezip :bool):
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
	
	if removezip:
		var rerr := DirAccess.remove_absolute(filepath)
		if rerr != OK:
			push_error("failed to delete old zip: ", err)
	
	GlobalVariables.uinode.next_install_step() # probably not very clean but should work for now
	print_rich("[color=green]extraction complete")

func _exit_tree():
	zipthread.wait_to_finish()
