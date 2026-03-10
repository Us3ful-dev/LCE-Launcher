extends Node

var rootpath := OS.get_executable_path().get_base_dir() # (appdata/LCE-Launcher)-probably 

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

func extract_zip(filepath :String, outputpath :String):
	var zip = ZIPReader.new()
	var err = zip.open(filepath)
	if err != OK:
		push_error("failed to open zip: ", err)
		return
	
	var files = zip.get_files()
	for file in files:
		var fulloutpath :String = outputpath + "/" + file
		# Write the file
		var data = zip.read_file(file)
		var f = FileAccess.open(fulloutpath, FileAccess.WRITE)
		if f:
			f.store_buffer(data)
			f.close()
		else:
			push_error("failed to write: ", fulloutpath)
	
	zip.close()
	print_rich("[color=green]extraction complete")
