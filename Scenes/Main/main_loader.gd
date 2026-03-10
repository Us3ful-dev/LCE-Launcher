extends Node

func _ready() -> void:
	FileEditor.make_dirs(["/instalations", "/globalsaves"])
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
	
	if !"--noupdatecheck" in OS.get_cmdline_args():
		GithubControl.update_github_file(
			"https://api.github.com/repos/Us3ful-dev/LCE-Launcher/releases/latest",
			"LCEWindows64.zip",
			"LCE-Launcher",
			false,
			self,
			FileEditor.rootpath
		)
	else:
		var data = FileEditor.open_json(FileEditor.rootpath + "/installsinfo.json")
		if data.has("LCE-Launcher"):
			data["LCE-Launcher"] = ProjectSettings.get_setting("application/config/version")
		FileEditor.make_write_json(FileEditor.rootpath + "/installsinfo.json", data)

func update_finished():
	pass
