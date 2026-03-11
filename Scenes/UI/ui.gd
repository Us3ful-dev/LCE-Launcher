extends Control

const INSTALLTILE := preload("res://Scenes/UI/Tiles/installed_tile.tscn")
var currenmenu := "main"
var curreninstall := ""
var installsteps := []

func _ready() -> void:
	GlobalVariables.uinode = self
	menu_manager("main")

func menu_manager(newmenu :String) -> void:
	currenmenu = newmenu
	if currenmenu == "main":
		build_installed_vbox()
		$MainField/NewInstallButton.visible = true
		$TopBar/GithubToken.visible = true
		$MainField/EditInstall.visible = false
	elif newmenu == "main/edit_installation":
		$MainField/Installed.visible = false
		$MainField/NewInstallButton.visible = false
		$TopBar/GithubToken.visible = false
		$MainField/EditInstall.visible = true
	elif newmenu == "main/new_installation":
		$MainField/Installed.visible = false
		$MainField/NewInstallButton.visible = false
		$TopBar/GithubToken.visible = false
		$MainField/EditInstall.visible = true
	

func setup_installedit():
	%ErrorMSG.text = ""
	if currenmenu == "main/edit_installation":
		$MainField/EditInstall/FinishInstall.text = "Save Changes"
	elif currenmenu == "main/new_installation":
		$MainField/EditInstall/FinishInstall.text = "Create Installation"

func build_installed_vbox():
	$MainField/Installed.visible = true
	for install in GlobalVariables.installations:
		if install != "LCE-Launcher" and !GlobalVariables.installtiles.has(install):
			var newtile := INSTALLTILE.instantiate()
			newtile.linkedinstall = install
			newtile.status = GlobalVariables.installations[install]["status"]
			$MainField/Installed/Installedvbox.add_child.call_deferred(newtile)
			newtile.setup()

func failed_install(installname :String):
	print("failed: ", installname)

func install_finished(installname :String):
	print("finished: ", installname)
	next_install_step()

func install_uptodate(installname :String):
	print("up to date: ", installname)

func next_install_step():
	if len(installsteps) > 0:
		var noautonext := false
		if installsteps[0].has("git"):
			print("requesting github")
			noautonext = true
			GithubControl.update_github_file(installsteps[0]["git"])
			GlobalVariables.installtiles[installsteps[0]["git"]["installname"]].set_status("Installing")
		elif installsteps[0].has("unzip"):
			noautonext = true
			print("unzipping: ", installsteps[0]["unzip"][0], installsteps[0]["unzip"][1], true)
			FileEditor.extract_zip(installsteps[0]["unzip"][0], installsteps[0]["unzip"][1], true)
		elif installsteps[0].has("final"):
			print("finalizing tile: ", GlobalVariables.installtiles[installsteps[0]["final"]])
			GlobalVariables.installations[ installsteps[0]["final"] ]["status"] = "ready"
			GlobalVariables.installtiles[ installsteps[0]["final"] ].set_status()
			FileEditor.save_installsdata()
		installsteps.remove_at(0)
		if !noautonext:
			next_install_step()

func _on_github_token_changed(token: String) -> void:
	GithubControl.githubtoken = token

func _on_new_install_button_down() -> void:
	menu_manager("main/new_installation")

func _on_finish_install_down() -> void:
	%ErrorMSG.text = ""
	if %SelectedName.text == "" or %SelectedName.text == "LCE-Launcher":
		%ErrorMSG.text = "Invalid name: " + %SelectedName.text
		return
	
	var installdir = FileEditor.rootpath + "/installations/" + %SelectedName.text
	print("creating install at: " + installdir)
	FileEditor.make_dirs(["/installations/" + %SelectedName.text])
	if %InstallType.selected == 0:
		print("creating an Vanilla LCE install")
		GlobalVariables.installations[%SelectedName.text] = {
			"status" : "installing",
			#"installversion" will be added by git
			"path" : installdir,
			"executablename" : "Minecraft.Client.exe",
			"executableargs" : [],
		}
		
		var fullargs = GlobalVariables.installgitsettings["vanilla lce"]
		fullargs["installname"] = %SelectedName.text
		fullargs["requestnode"] = self
		fullargs["downloadpath"] = installdir
		
		installsteps.append({"git" : fullargs})
		installsteps.append({"unzip" : [installdir + "/" + fullargs["requestedfilename"], installdir]})
		installsteps.append({"final" : %SelectedName.text})
		print("current installsteps in the works: ", installsteps)
		
		FileEditor.save_installsdata()
		next_install_step()
	
	menu_manager("main")
