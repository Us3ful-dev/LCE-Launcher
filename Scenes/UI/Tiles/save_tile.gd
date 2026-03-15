extends Control

var linkedsave :String
var linkedsavepath :String

func setup() -> void:
	GlobalVariables.saveboxes[linkedsave] = self
	$Name.text = linkedsave

func _on_copy_save_button_down() -> void:
	GlobalVariables.uinode.set_dir_request_node(self)

func _on_delete_save_button_down() -> void:
	FileEditor.delete_all_from_dir(linkedsavepath, true)
	GlobalVariables.saveboxes.erase(linkedsave)

func _on_link_save_button_down() -> void:
	pass # Comming soon?

func dirselect(dir: String) -> void:
	FileEditor.copy_file_dir(linkedsavepath, dir + "/" + linkedsave, false)
