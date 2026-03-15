extends Node

# config
var installgitsettings := {
	"vanilla-lce" : {
		"githubapi" : "https://api.github.com/repos/smartcmd/MinecraftConsoles/releases/tags/nightly",
		"requestedfilename" : "LCEWindows64.zip",
		#"installname" : "",
		"insamerelease" : true,
		#"requestnode" : Node,
		#"downloadpath" : FileEditor.rootpath + "/installations" + "/..."
		#"gitargs" : false/true
	},
}
var config :Dictionary
var cache :Dictionary
var installations :Dictionary
var linkedsaves :Dictionary

#nodes
var installboxes := {}
var saveboxes := {}
var uinode :Control

#userdata
var playername :String

func _ready() -> void:
	installations =  FileEditor.open_json(FileEditor.rootpath + "/installsinfo.json")
	config =  FileEditor.open_json(FileEditor.rootpath + "/config.json")
