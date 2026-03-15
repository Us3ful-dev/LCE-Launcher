extends Control

const INSTALLBOX := preload("res://Scenes/UI/Tiles/install_tile.tscn")
const SAVESBOX := preload("res://Scenes/UI/Tiles/save_tile.tscn")

var currenmenu := "installs"
var curreninstall := ""
var installsteps := []

var editnode :Control
var dirrequestnode :Control

func _ready() -> void:
	GlobalVariables.uinode = self
	menu_manager("installs")
	update_cached_installs()

func update_cached_installs() -> void:
	var dirs := DirAccess.get_directories_at(FileEditor.rootpath + "/cache")
	for dir in dirs:
		var fullargs = GlobalVariables.installgitsettings[dir].duplicate_deep()
		fullargs["installname"] = dir
		fullargs["requestnode"] = self
		fullargs["downloadpath"] = FileEditor.rootpath + "/cache/" + dir
		fullargs["removeold"] = true
		GithubControl.update_github_file(fullargs)

func failed_install(installname :String):
	print("failed: ", installname)
	GlobalVariables.cache[installname]["status"] = true

func install_finished(installname :String):
	print("finished: ", installname)
	GlobalVariables.cache[installname]["status"] = true

func install_uptodate(installname :String):
	print("up to date: ", installname)
	GlobalVariables.cache[installname]["status"] = true

func menu_manager(newmenu :String) -> void:
	currenmenu = newmenu
	if currenmenu == "installs":
		build_installs_vbox()
		$Sidebar/SelectedButton.visible = true
		$Sidebar/SelectedButton.position = $Sidebar/Installations.position
		
		$MainTile/Settings.visible = false
		$MainTile/Profile.visible = false
		$MainTile/EditInstall.visible = false
		$MainTile/SelectedInstallSaves.visible = false
		$MainTile/Saves.visible = false
		$MainTile/Installs.visible = true
		$BottomBar.visible = true
	elif newmenu == "installs/edit_installation":
		$MainTile/Installs.visible = false
		$MainTile/EditInstall.visible = true
		setup_installedit()
	elif newmenu == "installs/new_installation":
		$MainTile/Installs.visible = false
		$MainTile/EditInstall.visible = true
		setup_installedit()
	elif newmenu == "saves":
		build_saves_menubutton()
		_on_selected_install_saves_item_selected(0)
		$Sidebar/SelectedButton.visible = true
		$Sidebar/SelectedButton.position = $Sidebar/Saves.position
		
		$MainTile/Settings.visible = false
		$MainTile/Profile.visible = false
		$MainTile/SelectedInstallSaves.visible = true
		$MainTile/Saves.visible = true
		$MainTile/Installs.visible = false
		$BottomBar.visible = false
	elif newmenu == "profile":
		$Sidebar/SelectedButton.visible = false
		
		$MainTile/Settings.visible = false
		$MainTile/Profile.visible = true
		$MainTile/SelectedInstallSaves.visible = false
		$MainTile/Saves.visible = false
		$MainTile/Installs.visible = false
		$BottomBar.visible = false
	elif newmenu == "settings":
		$Sidebar/SelectedButton.visible = false
		
		$MainTile/Settings.visible = true
		$MainTile/Profile.visible = false
		$MainTile/SelectedInstallSaves.visible = false
		$MainTile/Saves.visible = false
		$MainTile/Installs.visible = false
		$BottomBar.visible = false

func build_installs_vbox() -> void:
	for install in GlobalVariables.installations:
		if !GlobalVariables.installboxes.has(install):
			var newbox := INSTALLBOX.instantiate()
			newbox.linkedinstall = install
			$MainTile/Installs/VBox.add_child.call_deferred(newbox)
			newbox.setup()

func build_saves_menubutton():
	for itemid in $MainTile/SelectedInstallSaves.item_count:
		$MainTile/SelectedInstallSaves.remove_item(itemid)
	for install in GlobalVariables.installations:
		$MainTile/SelectedInstallSaves.add_item(install)

func show_saves_from_install(install :String):
	for child in $MainTile/Saves/VBox.get_children():
		child.queue_free()
	
	for dir in DirAccess.get_directories_at(GlobalVariables.installations[install]["path"] + "/Windows64/GameHDD"):
		var newbox := SAVESBOX.instantiate()
		newbox.linkedsave = dir
		newbox.linkedsavepath = GlobalVariables.installations[install]["path"] + "/Windows64/GameHDD/" + dir
		$MainTile/Saves/VBox.add_child.call_deferred(newbox)
		newbox.setup()

func setup_installedit():
	%Error.text = ""

func current_install_step():
	if len(installsteps) > 0:
		var autonext := true
		if installsteps[0].has("getfilesoperation"):
			print("fileoperation: ", installsteps[0])
			if GlobalVariables.cache[ installsteps[0]["getfilesoperation"][0] ]["status"] == true:
				var getpath :String = FileEditor.rootpath + "/cache/" + installsteps[0]["getfilesoperation"][0] + "/" + installsteps[0]["getfilesoperation"][2]
				FileEditor.copy_file_dir.call_deferred(getpath, installsteps[0]["getfilesoperation"][1] + "/" + installsteps[0]["getfilesoperation"][2], true)
			autonext = false
		elif installsteps[0].has("zipoperation"):
			print("zipoperation: ", installsteps[0])
			FileEditor.extract_zip(installsteps[0]["zipoperation"][0], installsteps[0]["zipoperation"][1], installsteps[0]["zipoperation"][2], true)
			autonext = false
		elif installsteps[0].has("readyoperation"):
			print("readyoperation: ", installsteps[0])
			GlobalVariables.installations[ installsteps[0]["readyoperation"] ]["status"] = "ready"
			FileEditor.save_data()
		elif installsteps[0].has("deleteoperation"):
			print("deleteoperation: ", installsteps[0])
			GlobalVariables.installations.erase(installsteps[0]["deleteoperation"][0])
			FileEditor.delete_all_from_dir(installsteps[0]["deleteoperation"][1], true)
			FileEditor.save_data()
		installsteps.remove_at(0)
		if autonext:
			current_install_step()

func edit_install() -> void:
	pass

func install_new_installation() -> void:
	var typeid :int = %InstallType.get_selected_id()
	var type :String
	
	if typeid == 0:
		type = "vanilla lce"
	elif typeid == 1:
		type = "axo loader"
	elif typeid == 2:
		type = "weave loader"
	elif typeid == 3:
		type = "faucet"
	elif typeid == 4:
		type = "loom"
	
	%Error.text = ""
	if %NameInput.text == "" or GlobalVariables.installations.has(%NameInput.text):
		%Error.text = "Error: Invalid name"
	
	if type == "vanilla lce":
		FileEditor.make_dirs(["/installations/" + %NameInput.text])
		var installdir :String = FileEditor.rootpath + "/installations/" + %NameInput.text
		
		var installsettings := {
			"type" : "vanilla lce",
			"status" : "installing",
			"installversion" : GlobalVariables.cache["vanilla-lce"]["installversion"],
			"path" : installdir,
			"executablename" : "Minecraft.Client.exe",
			"executableargs" : [],
			"openterminal" : false
		}
		if %Fullscreen.button_pressed:
			installsettings["executableargs"].append("-fullscreen")
		if %Terminal.button_pressed: # does not work for some reason :(
			installsettings["openterminal"] = true
		
		GlobalVariables.installations[%NameInput.text] = installsettings
		FileEditor.save_data()
		
		installsteps.append({"getfilesoperation" : ["vanilla-lce", installdir, "LCEWindows64.zip"]})
		installsteps.append({"zipoperation" : [installdir + "/LCEWindows64.zip", installdir, true]})
		installsteps.append({"readyoperation" : %NameInput.text})
		
		current_install_step()
	
	menu_manager("installs")

func set_dir_request_node(node :Control) -> void:
	dirrequestnode = node
	$FileDialog.popup_centered()

func _on_installations_button_down() -> void:
	menu_manager("installs")

func _on_saves_button_down() -> void:
	menu_manager("saves")

func _on_settings_button_down() -> void:
	menu_manager("settings")

func _on_profile_button_down() -> void:
	menu_manager("profile")

func _on_new_install_button_down() -> void:
	menu_manager("installs/new_installation")

func _on_finish_install_button_down() -> void:
	if currenmenu == "installs/new_installation":
		install_new_installation()

func _on_file_dialog_dir_selected(dir: String) -> void:
	dirrequestnode.dirselect(dir)

func _on_selected_install_saves_item_selected(index: int) -> void:
	if $MainTile/SelectedInstallSaves.item_count > 0:
		show_saves_from_install($MainTile/SelectedInstallSaves.get_item_text(index))

func _on_name_text_changed(pname: String) -> void:
	GlobalVariables.playername = pname
