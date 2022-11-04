tool
extends PopupPanel


signal info_entered(token)


func get_info() -> Dictionary:
	var container = $Control/VBoxContainer
	var info := {}
	
	for child in container.get_children():
		info[child.placeholder_text] = child.text
	
	return info


func _on_CancelButton_pressed():
	emit_signal("info_entered", "EXIT")
	hide()
	queue_free()


func _on_EnterButton_pressed():
	var info = get_info()
	
	if not "" in info.values():
		emit_signal("info_entered", info)
		hide()
		queue_free()
	else:
		print("MUST ENTER ALL FIELDS.")



