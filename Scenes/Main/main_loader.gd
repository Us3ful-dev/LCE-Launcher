extends Node

const UI := preload("res://Scenes/UI/ui.tscn")

func _ready() -> void:
	loading_text_msg("making dirs")
	FileEditor.make_dirs(["/installations", "/globalsaves", "/cache"])
	loading_text_msg("making saves")
	if !FileAccess.file_exists(FileEditor.rootpath + "/cache.json"):
		var data := {
			#settings
		}
		FileEditor.make_write_json(FileEditor.rootpath + "/config.json" , data)
		setup_cache()
	if !FileAccess.file_exists(FileEditor.rootpath + "/config.json"):
		var data := {
			#settings
		}
		FileEditor.make_write_json(FileEditor.rootpath + "/config.json" , data)
	if !FileAccess.file_exists(FileEditor.rootpath + "/installsinfo.json"):
		var data := {
			#installs
		}
		FileEditor.make_write_json(FileEditor.rootpath + "/installsinfo.json" , data)
	
	loading_text_msg("checking installer file")
	check_installer()

func setup_cache() -> void:
	FileEditor.make_dirs(["/cache/vanilla-lce", ]) #rest
	GlobalVariables.cache = {
		#name            status true = ready       version
		"LCE-Launcher" : {"installversion" : "-"},
		"vanilla-lce" : {"status" : false, "installversion" : "-"},
	}
	FileEditor.save_data()

func check_installer():
	if !FileAccess.file_exists(FileEditor.rootpath + "/LCE-Launcher-Installer.exe"):
		loading_text_msg("downloading installer file")
		GithubControl.update_github_file({
			"githubapi" : "https://api.github.com/repos/Us3ful-dev/LCE-Launcher-Installer/releases/latest",
			"requestedfilename" : "LCE-Launcher-Installer.exe", # does not contain the installer file that comes with full install
			"installname" : "",
			"insamerelease" : false,
			"requestnode" : self,
			"downloadpath" : FileEditor.rootpath,
			"gitargs" : false,
			"removeold" : false
		})
	else:
		loading_text_msg("checking for updates")
		check_for_updates()

func check_for_updates():
	var data = FileEditor.open_json(FileEditor.rootpath + "/cache.json")
	if data.has("LCE-Launcher"):
		data["LCE-Launcher"]["installversion"] = ProjectSettings.get_setting("application/config/version")
	else:
		data["LCE-Launcher"] = {"installversion" : ProjectSettings.get_setting("application/config/version")}
	GlobalVariables.cache = data
	FileEditor.save_data()
	
	if !"--noupdatecheck" in OS.get_cmdline_args():
		loading_text_msg("updating")
		GithubControl.update_github_file({
			"githubapi" : "https://api.github.com/repos/Us3ful-dev/LCE-Launcher/releases/latest",
			"requestedfilename" : "LCE-Launcher-Update.zip", # does not contain the installer file that comes with full install
			"installname" : "LCE-Launcher",
			"insamerelease" : false,
			"requestnode" : self,
			"downloadpath" : FileEditor.rootpath,
			"gitargs" : false,
			"removeold" : false
		})
	else:
		print("skiped updatecheck")
		loading_text_msg("skiped update check")
		instantiate_ui()

func loading_text_msg(msg :String):
	%Loading.text += "\nLoading status: " + msg

func instantiate_ui():
	loading_text_msg("instantiating UI")
	$Loadingscreen.visible = false
	var instui = UI.instantiate()
	add_child(instui)

func failed_install(installname :String):
	loading_text_msg("failed to install: " + installname)
	if installname == "LCE-Launcher":
		instantiate_ui()

func install_finished(installname :String):
	loading_text_msg("finished: " + installname)
	if installname == "LCE-Launcher":
		var selfpid = OS.get_process_id()
		var pid = OS.create_process(FileEditor.rootpath + "/LCE-Launcher-Installer.exe", ["--isautoupdate", str(selfpid)])
		if pid == -1:
			printerr("Failed to launch: ", get_parent().filename)
		else:
			get_tree().quit()
	elif installname == "":
		check_for_updates()
	else:
		GlobalVariables.cache[installname]["status"] = true

func install_uptodate(installname :String):
	loading_text_msg("up to date: " + installname)
	if installname == "LCE-Launcher":
		instantiate_ui()
