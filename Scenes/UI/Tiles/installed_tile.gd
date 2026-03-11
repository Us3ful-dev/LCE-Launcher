extends ColorRect

var linkedinstall :String
var linkedinstalldata :Dictionary

func setup() -> void:
	linkedinstalldata = GlobalVariables.installations[linkedinstall]
	GlobalVariables.installtiles[linkedinstall] = self
	$Name.text = linkedinstall
	set_status()

func set_status():
	$Status.text = "Status: " + GlobalVariables.installations[linkedinstall]["status"]
	if GlobalVariables.installations[linkedinstall]["status"] != "ready":
		$Play.disabled = true
	else:
		$Play.disabled = false

func _on_play_button_down() -> void:
	if !GlobalVariables.installations[linkedinstall]["status"] == "ready":
		print("playing: ", linkedinstalldata["path"] + "/" + linkedinstalldata["executablename"], " With args: ", linkedinstalldata["executableargs"])
		var pid = OS.create_process(linkedinstalldata["path"] + "/" + linkedinstalldata["executablename"], linkedinstalldata["executableargs"])
		if pid == -1:
			printerr("Failed to launch: ", get_parent().filename)

func _on_open_folder_button_down() -> void:
	OS.shell_show_in_file_manager(linkedinstalldata["path"])

func _on_edit_installation_button_down() -> void:
	GlobalVariables.uinode.curreninstall = linkedinstall
	GlobalVariables.uinode.menu_manager("main/edit_installation")
