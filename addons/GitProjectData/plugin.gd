tool
extends EditorPlugin


const REFRESH_RATE := 5 # refresh every X seconds, API rate limit is 5k/hour
const INTERNAL_DIR := "res://addons/GitProjectData"
const EXTERNAL_DIR := "user://GitProjectData"
const GH_TOKEN_PATH := "res://addons/GitProjectData/GH_TOKEN.cfg"
const GH_USERNAME := "ACB-prgm"
const GH_REPO := "GitDataPlugin"

var INTERNAL_DATA := INTERNAL_DIR.plus_file("ProjectData")
#var INTERNAL_COMMIT := INTERNAL_DIR.plus_file("GitProjectData")
var EXTERNAL_DATA := EXTERNAL_DIR.plus_file("ProjectData")
var EXTERNAL_COMMIT := EXTERNAL_DIR.plus_file("commit.cfg")
var GH_TOKEN := "restart"

var popup_TSCN = preload("res://addons/GitProjectData/AccessTokenPopup.tscn")
var refresh_timer := Timer.new()


func _enter_tree():
	var ERR = get_gh_token()
	
	if ERR == ERR_PRINTER_ON_FIRE:
		print("Cancel GitProjectData Plugin. Toggle enable to try again.")
		return
	
	get_tree().root.call_deferred("add_child", refresh_timer)
	refresh_timer.set_wait_time(REFRESH_RATE)
	refresh_timer.set_one_shot(false)
	refresh_timer.connect("timeout", self, "refresh_dir")
	refresh_timer.set_autostart(true)
	

	var dir = Directory.new()
	if !dir.dir_exists(INTERNAL_DATA):
		dir.make_dir_recursive(INTERNAL_DATA)
	if !dir.dir_exists(EXTERNAL_DATA):
		dir.make_dir_recursive(EXTERNAL_DATA)
	
	refresh_dir()

func _exit_tree():
#	refresh_dir()
	refresh_timer.queue_free()


func get_gh_token():
	var cfg := ConfigFile.new()
	# just so its not visible on github
	var ERR = cfg.load_encrypted_pass(GH_TOKEN_PATH, "godot")
	if ERR == 7: # ERR_FILE_NOT_FOUND
		var popup = popup_TSCN.instance()
		get_tree().root.add_child(popup)
		popup.popup_centered()
		var token = yield(popup, "token_entered")
		if token == "EXIT":
			return ERR_PRINTER_ON_FIRE
		if yield(get_latest_commit(token), "completed"):
			cfg.set_value("token", "token", token)
			cfg.save_encrypted_pass(GH_TOKEN_PATH, "godot")
			GH_TOKEN = token
			return OK
		else:
			return get_gh_token()
	elif ERR != OK:
		push_error("Unable to retrieve token from cfg with ERR: " + ERR)
		return ERR
	else:
		GH_TOKEN = cfg.get_value("token", "token")
		return OK


func get_latest_commit(token:String) -> String:
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	var url = "https://api.github.com/repos/%s/%s/commits" % [GH_USERNAME, GH_REPO]
	var headers = [
		"Accept: application/vnd.github+json",
		"Authorization: Bearer %s" % token
	]
	headers = PoolStringArray(headers)
	
	var error = http_request.request(url, headers)
	if error != OK:
		push_error("An error occurred in the HTTP request with ERR Code: %s" % error)
		return ""
	
	var response = yield(http_request, "request_completed")
	if response[1] != 200:
		print(response[3].get_string_from_utf8())
		return ""
	
	return parse_json(response[3].get_string_from_utf8())[0].get("sha")


func get_stored_commit() -> String:
	var path := EXTERNAL_COMMIT
	var cfg := ConfigFile.new()
	var ERR = cfg.load(path)
	if ERR != OK:
		return ""
	
	if cfg.has_section("commit"):
		return cfg.get_value("commit", "commit")
	else:
		return ""


func store_commit(commit:String) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("commit", "commit", commit)
	cfg.save(EXTERNAL_COMMIT)


func is_new_version() -> bool:
	var stored_commit = get_stored_commit()
	var git_commit = yield(get_latest_commit(GH_TOKEN), "completed")

	if !stored_commit or stored_commit != git_commit:
		store_commit(git_commit)
		return true
	else:
		return false


func refresh_dir() -> void:
	if GH_TOKEN == "restart":
		get_gh_token()
	
	if yield(is_new_version(), "completed"):
#		print("copy int to ext")
		copy_dir(INTERNAL_DATA, EXTERNAL_DATA)
	else:
#		print("copy ext to int")
		copy_dir(EXTERNAL_DATA, INTERNAL_DATA)


func copy_dir(from_dir:String, to_dir:String, delete_to:=true) -> void:
	from_dir = ProjectSettings.globalize_path(from_dir)
	to_dir = ProjectSettings.globalize_path(to_dir)
	var dir = Directory.new()
	
	if dir.dir_exists(to_dir):
		if to_dir[-1] == ".":
			return
#		var ERR = OS.move_to_trash(to_dir)
		var ERR = OS.execute("rm", ["-rf", to_dir])
		if ERR != OK:
			print("Failed to remove directory at %s with Error code: %s" % [to_dir, ERR])
			return
	dir.make_dir(to_dir)

	if dir.open(from_dir) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			var from_path = from_dir.plus_file(file_name)
			var to_path = to_dir.plus_file(file_name)
			if dir.current_is_dir():
				if file_name != "logs":
					copy_dir(from_path, to_path)
			else:
				var ERR = dir.copy(from_path, to_path)
				if ERR != OK:
					print("ERROR COPYING FILE: %s" % file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path. %s" % from_dir)






