extends Control

var linkedinstall :String

func setup() -> void:
	GlobalVariables.installboxes[linkedinstall] = self
	$Name.text = linkedinstall
	$Status.text = GlobalVariables.installations[linkedinstall]["status"] + "  Version: " + GlobalVariables.installations[linkedinstall]["installversion"]

func _on_play_button_down() -> void:
	var args :Array = GlobalVariables.installations[linkedinstall]["executableargs"].duplicate_deep()
	if GlobalVariables.playername != "":
		args.append("-name")
		args.append(GlobalVariables.playername)
	print(
		GlobalVariables.installations[linkedinstall]["path"] + "/" + GlobalVariables.installations[linkedinstall]["executablename"], " <> ",
		args, " <> ",
		GlobalVariables.installations[linkedinstall]["openterminal"],
	)
	OS.create_process(GlobalVariables.installations[linkedinstall]["path"] + "/" + GlobalVariables.installations[linkedinstall]["executablename"], args, GlobalVariables.installations[linkedinstall]["openterminal"])

func _on_edit_button_down() -> void:
	pass # Replace with function body.

func _on_delete_button_down() -> void:
	GlobalVariables.installboxes.erase(linkedinstall)
	GlobalVariables.uinode.installsteps.append({"deleteoperation" : [linkedinstall, GlobalVariables.installations[linkedinstall]["path"]]})
	GlobalVariables.uinode.current_install_step()
	self.queue_free()

func _on_update_button_down() -> void:
	pass # Replace with function body.
