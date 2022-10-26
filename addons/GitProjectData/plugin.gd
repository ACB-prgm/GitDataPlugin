tool
extends EditorPlugin


const INTERNAL_DIR := "res://addons/GitProjectData/LocalProjectData"
const EXTERNAL_DIR := "user://GitProjectData"
const GH_TOKEN_PATH := "res://addons/GitProjectData/GH_TOKEN.cfg"
const COMMIT_PATH := "commit.cfg"
const GH_USERNAME := "ACB-prgm"
const GH_REPO := "LiveStreamGamez.nosync"

var GH_TOKEN : String


func _enter_tree():
	GH_TOKEN = load_gh_token()
	
	var dir = Directory.new()
	if !dir.dir_exists(INTERNAL_DIR):
		dir.make_dir(INTERNAL_DIR)
	if !dir.dir_exists(EXTERNAL_DIR):
		dir.make_dir_recursive(EXTERNAL_DIR)
	
	refresh_dir()

func _exit_tree():
	pass


func load_gh_token() -> String:
	var cfg := ConfigFile.new()
	cfg.load_encrypted_pass(GH_TOKEN_PATH, "godot") # just so its not visible on github
	return cfg.get_value("token", "token")


func get_latest_commit() -> String:
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	var url = "https://api.github.com/repos/%s/%s/commits" % [GH_USERNAME, GH_REPO]
	var headers = [
		"Accept: application/vnd.github+json",
		"Authorization: Bearer %s" % GH_TOKEN
	]
	headers = PoolStringArray(headers)
	
	var error = http_request.request(url, headers)
	if error != OK:
		push_error("An error occurred in the HTTP request with ERR Code: %s" % error)
	
	var response = yield(http_request, "request_completed")
	
	return parse_json(response[3].get_string_from_utf8())[0].get("sha")


func get_stored_commit() -> String:
	var path := EXTERNAL_DIR.plus_file(COMMIT_PATH)
	var cfg := ConfigFile.new()
	var ERR = cfg.load(path)
	if ERR != OK:
		return ""
	
	if cfg.has_section("commit"):
		return cfg.load_value("commit", "commit")
	
	return ""


func new_version() -> bool:
	var stored_commit = get_stored_commit()
	var git_commit = get_latest_commit()
	
	if !stored_commit:
		var cfg := ConfigFile.new()
		cfg.set_value("commit", "commit", git_commit)
		cfg.save(EXTERNAL_DIR.plus_file(COMMIT_PATH))
		return true
	
	if stored_commit == git_commit:
		return false
	else:
		var cfg := ConfigFile.new()
		cfg.set_value("commit", "commit", git_commit)
		cfg.save(EXTERNAL_DIR.plus_file(COMMIT_PATH))
		return true


func refresh_dir() -> void:
	if new_version():
		print("copy int to ext")
		copy_dir(INTERNAL_DIR, EXTERNAL_DIR)
	else:
		print("copy ext to int")
		copy_dir(EXTERNAL_DIR, INTERNAL_DIR)


func copy_dir(from_dir:String, to_dir:String) -> void:
	from_dir = ProjectSettings.globalize_path(from_dir)
	to_dir = ProjectSettings.globalize_path(to_dir)
	var dir = Directory.new()
	
	if dir.dir_exists(to_dir):
		if to_dir[-1] == ".":
			return
		var ERR = OS.move_to_trash(to_dir)
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
