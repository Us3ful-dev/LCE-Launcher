extends Node

# need to be set by requester:
var githubapi := "" #https://api.github.com/repos/YOUR_USERNAME/YOUR_REPO/releases/latest
var requestedfilename := "" # for smartcmd/MinecraftConsoles LCEWindows64.zip
var installname := "" # the name of the install <- game-(name user gave to install)
var insamerelease := false # smartcmd/MinecraftConsoles uses nightly so in same release (checks timestamp)
var requestnode # this is the node that requested te check (can return the completion)
var downloadpath :String # LCE-Launcher/requestedfilename.zip

#posible
var githubtoken := ""

# own vars:
var headers := ["User-Agent: LCE-Launcher-gitchecker"]
var alreadyworking := false # make shure no two checks interfere
var newupdatetag :String # the new version / update time

# HTTPRequesters:
var checkrequester :HTTPRequest
var downloadrequester :HTTPRequest

func _ready() -> void:
	checkrequester = HTTPRequest.new()
	add_child(checkrequester)
	checkrequester.use_threads = true
	checkrequester.request_completed.connect(on_request_completed)
	
	downloadrequester = HTTPRequest.new()
	add_child(downloadrequester)
	downloadrequester.use_threads = true #downloads in the background using seperate thread
	downloadrequester.request_completed.connect(on_download_completed)

func update_github_file(ngithubapi :String, nrequestedfilename :String, ninstallname :String, ninsamerelease :bool, nrequestnode, ndownloadpath :String) -> bool:
	if alreadyworking:
		return false
	
	if githubtoken != "":
		headers.append("Authorization: Bearer " + githubtoken)
	
	alreadyworking = true
	githubapi = ngithubapi
	requestedfilename = nrequestedfilename
	installname = ninstallname
	insamerelease = ninsamerelease
	requestnode = nrequestnode
	downloadpath = ndownloadpath + "/" + nrequestedfilename
	
	checkrequester.request(githubapi, headers)
	
	return true

func on_request_completed(result, response_code, _headers, body) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		print("Body: ", body.get_string_from_utf8())
		print("Failed to check for updates: ", response_code)
		alreadyworking = false
		return
	
	var json := JSON.new()
	json.parse(body.get_string_from_utf8())
	var data :Dictionary = json.get_data()
	
	print(data)
	
	if insamerelease: 
		var lastupdate = ""
		var installdata = FileEditor.open_json(FileEditor.rootpath + "/installsinfo.json")
		if installdata.has(installname):
			lastupdate = installdata[installname]
		
		if data["published_at"] != lastupdate:
			print("Update available, published: ", data["published_at"])
			download_release(data["assets"])
			# Save the new timestamp after successful download
			
			newupdatetag = data["published_at"]
		else:
			print("Already up to date.")
	else:
		var expectedversion = ""
		var installdata = FileEditor.open_json(FileEditor.rootpath + "/installsinfo.json")
		if installdata.has(installname):
			expectedversion = installdata[installname]
		
		if data["tag_name"] != expectedversion:
			print("Update available: ", data["tag_name"])
			download_release(data["assets"])
		else:
			print("Already up to date.")

func download_release(assets: Array) -> void:
	#find the required .zip
	var downloadurl = ""
	for asset in assets: #all posible downloads
		if asset["name"] == requestedfilename: #find correct download
			downloadurl = asset["browser_download_url"]
			break
	
	if downloadurl == "":
		print("No matching asset found")
		alreadyworking = false
		return
	
	downloadrequester.download_file = downloadpath
	downloadrequester.request(downloadurl, headers)
	print("Downloading update")

func on_download_completed(result, response_code, _headers, body):
	if result == HTTPRequest.RESULT_SUCCESS:
		print("Download complete: ", downloadpath)
		# update what version is installed
		var data = FileEditor.open_json(FileEditor.rootpath + "/installsinfo.json")
		if data.has(installname):
			data[installname] = newupdatetag
		FileEditor.make_write_json(FileEditor.rootpath + "/installsinfo.json", data)
		
		alreadyworking = false
		requestnode.update_finished()
	else:
		print("Body: ", body.get_string_from_utf8())
		print("Download failed: ", response_code)
		alreadyworking = false
