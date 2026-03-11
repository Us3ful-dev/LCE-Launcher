extends Node

var installgitsettings := {
	"vanilla lce" : {
		"githubapi" : "https://api.github.com/repos/smartcmd/MinecraftConsoles/releases/tags/nightly",
		"requestedfilename" : "LCEWindows64.zip",
		#"installname" : "",
		"insamerelease" : true,
		#"requestnode" : Node,
		#"downloadpath" : FileEditor.rootpath + "/installations" + "/..."
	},
	"weave loader" : {
		
	},
	"faucet loader" : {
		
	},
}
var installations :Dictionary

var installtiles := {}
var uinode :Control

func _ready() -> void:
	installations =  FileEditor.open_json(FileEditor.rootpath + "/installsinfo.json")
