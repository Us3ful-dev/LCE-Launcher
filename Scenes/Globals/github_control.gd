extends Node

# need to be set by requester:
var githubapi := "" #https://api.github.com/repos/YOUR_USERNAME/YOUR_REPO/releases/latest
var requestedfilename := "" # for smartcmd/MinecraftConsoles LCEWindows64.zip
var installname := "" # the name of the install <- game-(name user gave to install)
var insamerelease := false # smartcmd/MinecraftConsoles uses nightly so in same release (checks timestamp)
var requestnode # this is the node that requested te check (can return the completion)
var downloadpath :String # LCE-Launcher/requestedfilename.zip
var removeold :bool # temorary for update

# own vars:
var headers := ["User-Agent: LCE-Launcher-gitchecker"]
var alreadyworking := false # make shure no two checks interfere
var newupdatetag :String # the new version / update time

# HTTPRequesters:
var checkrequester :HTTPRequest
var downloadrequester :HTTPRequest

var waitingrequests := []

func _ready() -> void:
	checkrequester = HTTPRequest.new()
	add_child(checkrequester)
	checkrequester.use_threads = true
	checkrequester.request_completed.connect(on_request_completed)
	
	downloadrequester = HTTPRequest.new()
	add_child(downloadrequester)
	downloadrequester.use_threads = true #downloads in the background using seperate thread
	downloadrequester.request_completed.connect(on_download_completed)

func update_github_file(gitargs :Dictionary) -> void:
	print_rich("[color=green]GITCONTROL: request: ", gitargs, " already working: ", alreadyworking)
	waitingrequests.append(gitargs)
	if !alreadyworking:
		next_update()

func next_update() -> void:
	if len(waitingrequests) > 0:
		alreadyworking = true
		githubapi = waitingrequests[0]["githubapi"]
		requestedfilename = waitingrequests[0]["requestedfilename"]
		installname = waitingrequests[0]["installname"]
		insamerelease = waitingrequests[0]["insamerelease"]
		requestnode = waitingrequests[0]["requestnode"]
		downloadpath = waitingrequests[0]["downloadpath"] + "/" + waitingrequests[0]["requestedfilename"]
		removeold = waitingrequests[0]["removeold"]
		waitingrequests.remove_at(0)
		
		checkrequester.request(githubapi, headers)

func on_request_completed(result, response_code, _headers, body) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		print_rich("[color=green]GITCONTROL: Body: ", body.get_string_from_utf8())
		print_rich("[color=green]GITCONTROL: Failed to check for file: ", response_code)
		alreadyworking = false
		requestnode.failed_install(installname)
		next_update()
		return
	
	var json := JSON.new()
	json.parse(body.get_string_from_utf8())
	var data :Dictionary = json.get_data()
	
	var installdata = FileEditor.open_json(FileEditor.rootpath + "/cache.json")
	if insamerelease: 
		var lastupdate = ""
		if installdata.has(installname):
			lastupdate = installdata[installname]["installversion"]
		
		if data["published_at"] != lastupdate:
			print_rich("[color=green]GITCONTROL: File (Update) available, published: ", data["published_at"])
			download_release(data["assets"])
			# Save the new timestamp after successful download
			
			newupdatetag = data["published_at"]
		else:
			requestnode.install_uptodate(installname)
			alreadyworking = false
			print_rich("[color=green]GITCONTROL: Already up to date.")
			next_update()
	else:
		var expectedversion = ""
		if installdata.has(installname):
			expectedversion = installdata[installname]["installversion"]
		
		if data["tag_name"] != expectedversion:
			print_rich("[color=green]GITCONTROL: File (Update) available: ", data["tag_name"])
			download_release(data["assets"])
		else:
			requestnode.install_uptodate(installname)
			alreadyworking = false
			print_rich("[color=green]GITCONTROL: Already up to date.")
			next_update()

func download_release(assets: Array) -> void:
	if removeold:
		print_rich("[color=green]GITCONTROL: Delete old: ", downloadpath)
		FileEditor.delete_file(downloadpath)
	#find the required .zip
	var downloadurl = ""
	for asset in assets: #all posible downloads
		if asset["name"] == requestedfilename: #find correct download
			downloadurl = asset["browser_download_url"]
			break
	
	if downloadurl == "":
		print_rich("[color=green]GITCONTROL: No matching asset found")
		alreadyworking = false
		requestnode.failed_install(installname)
		next_update()
		return
	
	downloadrequester.download_file = downloadpath
	downloadrequester.request(downloadurl, headers)
	print_rich("[color=green]GITCONTROL: Downloading file from: ", downloadurl)

func on_download_completed(result, response_code, _headers, body):
	if result == HTTPRequest.RESULT_SUCCESS:
		print_rich("[color=green]GITCONTROL: Download complete: ", downloadpath)
		# update what version is installed
		if installname != "":
			var data = FileEditor.open_json(FileEditor.rootpath + "/cache.json")
			if data.has(installname):
				data[installname]["installversion"] = newupdatetag
			GlobalVariables.cache = data
			FileEditor.save_data()
		
		alreadyworking = false
		requestnode.install_finished(installname)
		next_update()
	else:
		print_rich("[color=green]GITCONTROL: Body: ", body.get_string_from_utf8())
		print_rich("[color=green]GITCONTROL: Download failed: ", response_code)
		alreadyworking = false
		requestnode.failed_install(installname)
		next_update()
