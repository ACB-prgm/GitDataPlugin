extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	var cfg = ConfigFile.new()
	cfg.set_value("token", "token", "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")
	cfg.save_encrypted_pass("res://addons/GitProjectData/GH_TOKEN.cfg", "godot")
